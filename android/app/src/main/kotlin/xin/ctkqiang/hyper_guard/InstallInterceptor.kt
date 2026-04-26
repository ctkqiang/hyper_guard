package xin.ctkqiang.hyper_guard

import android.app.Activity
import android.app.AlertDialog
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.util.Log
import java.io.File
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class InstallInterceptor private constructor(private val activity: Activity) {

    companion object {
        private const val TAG = "InstallInterceptor"
        private var instance: InstallInterceptor? = null

        fun getInstance(activity: Activity): InstallInterceptor {
            return instance ?: synchronized(this) {
                instance ?: InstallInterceptor(activity).also { instance = it }
            }
        }
    }

    interface InstallCallback {
        fun onInstallRequested(packageName: String, apkPath: String)
        fun onInstallTypeSelected(type: InstallType, apkPath: String)
    }

    enum class InstallType {
        NORMAL_INSTALL,
        SANDBOX_INSTALL
    }

    enum class RiskLevel {
        LOW, MEDIUM, HIGH, CRITICAL;

        override fun toString(): String = when (this) {
            LOW -> "Low Risk"
            MEDIUM -> "Medium Risk"
            HIGH -> "High Risk"
            CRITICAL -> "Critical Risk"
        }
    }

    data class ValidationResult(
        val valid: Boolean,
        val riskLevel: RiskLevel,
        val issues: List<String>,
        val metadata: Map<String, String>,
    )

    private var callback: InstallCallback? = null
    private var isRegistered = false
    private var pendingApkPath: String = ""
    private val auditLogFile: File by lazy {
        File(activity.filesDir, "hyperguard_sandbox/audit").let { dir ->
            if (!dir.exists()) dir.mkdirs()
            File(dir, "install_audit.log")
        }
    }

    private val packageReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (intent?.action == Intent.ACTION_PACKAGE_ADDED) {
                val packageName = intent.data?.schemeSpecificPart ?: return
                if (intent.getBooleanExtra(Intent.EXTRA_REPLACING, false)) return
                Log.i(TAG, "Install intercepted: $packageName")
                callback?.onInstallRequested(packageName, "")
            }
        }
    }

    fun setCallback(callback: InstallCallback?) {
        this.callback = callback
    }

    fun register() {
        if (isRegistered) return
        try {
            val filter = IntentFilter().apply {
                addAction(Intent.ACTION_PACKAGE_ADDED)
                addDataScheme("package")
                priority = 999
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                activity.registerReceiver(packageReceiver, filter, Context.RECEIVER_EXPORTED)
            } else {
                activity.registerReceiver(packageReceiver, filter)
            }
            isRegistered = true
            writeAuditLog("InstallInterceptor registered")
            Log.i(TAG, "Interceptor registered")
        } catch (e: Exception) {
            Log.e(TAG, "Interceptor registration failed", e)
        }
    }

    fun unregister() {
        if (!isRegistered) return
        try {
            activity.unregisterReceiver(packageReceiver)
            isRegistered = false
            writeAuditLog("InstallInterceptor unregistered")
            Log.i(TAG, "Interceptor unregistered")
        } catch (e: Exception) {
            Log.e(TAG, "Unregister failed", e)
        }
    }

    fun showInstallDialog(packageName: String, apkPath: String) {
        pendingApkPath = apkPath
        val validation = validateApk(apkPath)

        writeAuditLog("INSTALL_DIALOG_SHOWN package=$packageName risk=${validation.riskLevel}")

        val message = buildString {
            append("Package: $packageName\n")
            if (validation.metadata["appName"] != null) {
                append("App: ${validation.metadata["appName"]}\n")
            }
            if (validation.metadata["versionName"] != null) {
                append("Version: ${validation.metadata["versionName"]}\n")
            }
            append("\nSecurity Assessment: ${validation.riskLevel}\n")
            if (validation.issues.isNotEmpty()) {
                append("\nIssues detected:\n")
                validation.issues.forEachIndexed { i, issue ->
                    append("${i + 1}. $issue\n")
                }
            }
            append("\nSelect installation mode:")
        }

        AlertDialog.Builder(activity).apply {
            setTitle("HyperGuard Installation Guard")
            setMessage(message)
            setPositiveButton("Sandbox (Safe)") { _, _ ->
                writeAuditLog("ACTION selected=SANDBOX package=$packageName risk=${validation.riskLevel}")
                callback?.onInstallTypeSelected(InstallType.SANDBOX_INSTALL, pendingApkPath)
            }
            setNegativeButton("Normal Install") { _, _ ->
                showNormalInstallConfirmation(packageName)
            }
            setNeutralButton("Cancel") { _, _ ->
                writeAuditLog("ACTION selected=CANCEL package=$packageName")
            }
            setCancelable(false)
        }.show()
    }

    private fun showNormalInstallConfirmation(packageName: String) {
        val validation = validateApk(pendingApkPath)
        if (validation.riskLevel == RiskLevel.HIGH || validation.riskLevel == RiskLevel.CRITICAL) {
            AlertDialog.Builder(activity).apply {
                setTitle("Warning: ${validation.riskLevel}")
                setMessage(
                    "This APK has been flagged as ${validation.riskLevel}.\n\n" +
                    "Normal installation will grant the app full access to your device.\n\n" +
                    "Are you sure you want to proceed?"
                )
                setPositiveButton("Proceed Anyway") { _, _ ->
                    writeAuditLog("NORMAL_INSTALL_OVERRIDE package=$packageName risk=${validation.riskLevel}")
                    callback?.onInstallTypeSelected(InstallType.NORMAL_INSTALL, pendingApkPath)
                }
                setNegativeButton("Use Sandbox Instead") { _, _ ->
                    writeAuditLog("OVERRIDE_TO_SANDBOX package=$packageName")
                    callback?.onInstallTypeSelected(InstallType.SANDBOX_INSTALL, pendingApkPath)
                }
                setNeutralButton("Cancel") { _, _ ->
                    writeAuditLog("NORMAL_CANCELLED package=$packageName")
                }
                setCancelable(false)
            }.show()
        } else {
            writeAuditLog("ACTION selected=NORMAL package=$packageName risk=${validation.riskLevel}")
            callback?.onInstallTypeSelected(InstallType.NORMAL_INSTALL, pendingApkPath)
        }
    }

    fun validateApk(apkPath: String): ValidationResult {
        val issues = mutableListOf<String>()
        val metadata = mutableMapOf<String, String>()
        var riskLevel = RiskLevel.LOW

        try {
            val apkFile = File(apkPath)
            if (!apkFile.exists()) {
                issues.add("APK file not found at path")
                metadata["sizeBytes"] = "0"
                return ValidationResult(false, RiskLevel.CRITICAL, issues, metadata)
            }

            val sizeMb = apkFile.length() / (1024.0 * 1024.0)
            metadata["sizeBytes"] = apkFile.length().toString()
            metadata["sizeMb"] = "%.2f".format(sizeMb)

            val info = activity.packageManager.getPackageArchiveInfo(
                apkPath, PackageManager.GET_PERMISSIONS
            )

            if (info == null) {
                issues.add("Failed to parse APK package info - may be corrupted")
                return ValidationResult(false, RiskLevel.CRITICAL, issues, metadata)
            }

            metadata["packageName"] = info.packageName
            metadata["versionName"] = info.versionName ?: "unknown"
            metadata["appName"] = try {
                info.applicationInfo?.let { activity.packageManager.getApplicationLabel(it).toString() }
            } catch (e: Exception) { null } ?: "Unknown"

            val permissions = info.requestedPermissions?.toList() ?: emptyList()
            metadata["permissionCount"] = permissions.size.toString()

            val dangerousPerms = listOf(
                "SMS", "CONTACTS", "CALL_LOG", "CAMERA", "MICROPHONE",
                "LOCATION", "PHONE", "STORAGE", "INSTALL_PACKAGES"
            )
            permissions.forEach { perm ->
                dangerousPerms.forEach { keyword ->
                    if (perm.contains(keyword)) {
                        issues.add("Requests permission: $perm")
                    }
                }
            }

            val sensitiveCount = permissions.count { perm ->
                dangerousPerms.any { perm.contains(it) }
            }
            riskLevel = when {
                permissions.any { it.contains("INSTALL_PACKAGES") || it.contains("SYSTEM_ALERT_WINDOW") } -> RiskLevel.CRITICAL
                sensitiveCount >= 5 -> RiskLevel.HIGH
                sensitiveCount >= 3 -> RiskLevel.MEDIUM
                else -> RiskLevel.LOW
            }

            metadata["sensitivePermissions"] = sensitiveCount.toString()
            metadata["totalPermissions"] = permissions.size.toString()
            metadata["riskLevel"] = riskLevel.name

        } catch (e: Exception) {
            issues.add("Validation error: ${e.message}")
            riskLevel = RiskLevel.CRITICAL
        }

        writeAuditLog("VALIDATION package=${metadata["packageName"]} risk=$riskLevel issues=${issues.size}")
        return ValidationResult(issues.isEmpty(), riskLevel, issues, metadata)
    }

    fun installApkNormal(apkPath: String) {
        try {
            val apkFile = File(apkPath)
            if (!apkFile.exists()) return
            writeAuditLog("NORMAL_INSTALL_START path=$apkPath")
            val intent = Intent(Intent.ACTION_VIEW).apply {
                setDataAndType(Uri.fromFile(apkFile), "application/vnd.android.package-archive")
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                    addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                }
            }
            activity.startActivity(intent)
        } catch (e: Exception) {
            Log.e(TAG, "Normal install failed", e)
            writeAuditLog("NORMAL_INSTALL_FAILED path=$apkPath error=${e.message}")
        }
    }

    fun writeAuditLog(message: String) {
        try {
            val timestamp = SimpleDateFormat("yyyy-MM-dd HH:mm:ss.SSS", Locale.US).format(Date())
            auditLogFile.appendText("[$timestamp] $message\n")
        } catch (e: Exception) {
            Log.e(TAG, "Audit log write failed", e)
        }
    }

    fun getAuditLogs(): List<String> {
        return try {
            auditLogFile.readLines().takeLast(500)
        } catch (e: Exception) {
            emptyList()
        }
    }

    class InstallReceiver : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (intent?.action == Intent.ACTION_PACKAGE_ADDED ||
                intent?.action == "android.intent.action.PACKAGE_INSTALL") {
                val packageName = intent.data?.schemeSpecificPart ?: return
                if (intent.getBooleanExtra(Intent.EXTRA_REPLACING, false)) return
                Log.i("InstallReceiver", "Install intercepted: $packageName")
                val activity = context as? Activity ?: return
                val interceptor = try {
                    InstallInterceptor.getInstance(activity)
                } catch (e: Exception) {
                    InstallInterceptor(activity)
                }
                interceptor.showInstallDialog(packageName, "")
            }
        }
    }

    fun onDestroy() {
        unregister()
        callback = null
        instance = null
    }
}
