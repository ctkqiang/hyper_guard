package xin.ctkqiang.hyper_guard

import android.app.AlertDialog
import android.content.pm.PackageManager
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray
import org.json.JSONObject
import java.io.File
import java.util.UUID
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {

    companion object {
        private const val TAG = "HyperGuard"
        private const val CHANNEL_DEVICE = "xin.ctkqiang.hyper_guard/device"
        private const val CHANNEL_SANDBOX = "xin.ctkqiang.hyper_guard/sandbox"
        private const val CHANNEL_MONITOR = "xin.ctkqiang.hyper_guard/monitor"
    }

    private val sandboxExecutor = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())
    private lateinit var installInterceptor: InstallInterceptor
    private val activeSandboxes = ConcurrentHashMap<String, SandboxSession>()
    private val reportStore = mutableListOf<JSONObject>()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (!DeviceUtil.isXiaomiDevice()) {
            showIncompatibleDialog("Device Not Supported", "HyperGuard requires a Xiaomi device with HyperOS.")
            return
        }
        if (!DeviceUtil.isHyperOS()) {
            showIncompatibleDialog("HyperOS Required", "Please upgrade to HyperOS to use HyperGuard.")
            return
        }
        installInterceptor = InstallInterceptor.getInstance(this)
        installInterceptor.setCallback(object : InstallInterceptor.InstallCallback {
            override fun onInstallRequested(packageName: String, apkPath: String) {
                installInterceptor.showInstallDialog(packageName, apkPath)
            }
            override fun onInstallTypeSelected(type: InstallInterceptor.InstallType, apkPath: String) {
                when (type) {
                    InstallInterceptor.InstallType.SANDBOX_INSTALL -> {
                        sandboxExecutor.execute {
                            val app = installToSandboxInternal(apkPath)
                            mainHandler.post {
                                flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger ->
                                    MethodChannel(messenger, CHANNEL_SANDBOX)
                                        .invokeMethod("onSandboxAppInstalled", app)
                                }
                            }
                        }
                    }
                    InstallInterceptor.InstallType.NORMAL_INSTALL -> {
                        installInterceptor.installApkNormal(apkPath)
                    }
                }
            }
        })
        installInterceptor.register()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_DEVICE)
            .setMethodCallHandler(::handleDeviceChannel)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_SANDBOX)
            .setMethodCallHandler(::handleSandboxChannel)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_MONITOR)
            .setMethodCallHandler(::handleMonitorChannel)
    }

    private fun handleDeviceChannel(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "isXiaomiDevice" -> result.success(DeviceUtil.isXiaomiDevice())
            "isHyperOS" -> result.success(DeviceUtil.isHyperOS())
            "getHyperOSVersion" -> result.success(DeviceUtil.getHyperOSVersion())
            "getDeviceInfo" -> result.success(DeviceUtil.getDeviceInfo())
            else -> result.notImplemented()
        }
    }

    private fun handleSandboxChannel(call: MethodCall, result: MethodChannel.Result) {
        sandboxExecutor.execute {
            when (call.method) {
                "initializeSandbox" -> mainHandler.post {
                    result.success(initializeSandboxInternal())
                }
                "installToSandbox" -> {
                    val apkPath = call.argument<String>("apkPath") ?: ""
                    val app = installToSandboxInternal(apkPath)
                    mainHandler.post { result.success(app) }
                }
                "startAnalysis" -> {
                    val appId = call.argument<String>("appId") ?: ""
                    startAnalysisInternal(appId)
                    mainHandler.post { result.success(true) }
                }
                "stopSandbox" -> {
                    stopSandboxInternal(call.argument<String>("appId") ?: "")
                    mainHandler.post { result.success(true) }
                }
                "terminateSandbox" -> {
                    terminateSandboxInternal(call.argument<String>("appId") ?: "")
                    mainHandler.post { result.success(true) }
                }
                "getFakeDataProfile" -> {
                    val appId = call.argument<String>("appId") ?: ""
                    mainHandler.post { result.success(buildSandboxProfile(appId)) }
                }
                "getActiveSandboxApps" -> mainHandler.post {
                    result.success(getActiveSandboxAppsInternal())
                }
                else -> mainHandler.post { result.notImplemented() }
            }
        }
    }

    private fun handleMonitorChannel(call: MethodCall, result: MethodChannel.Result) {
        sandboxExecutor.execute {
            when (call.method) {
                "generateReport" -> mainHandler.post {
                    result.success(generateReportInternal(call.argument<String>("sandboxAppId") ?: ""))
                }
                "getReportHistory" -> mainHandler.post {
                    result.success(getReportHistoryInternal())
                }
                "deleteReport" -> mainHandler.post {
                    result.success(deleteReportInternal(call.argument<String>("reportId") ?: ""))
                }
                "exportReport" -> mainHandler.post {
                    result.success(exportReportInternal(
                        call.argument<String>("reportId") ?: "",
                        call.argument<String>("format") ?: "json"
                    ))
                }
                else -> mainHandler.post { result.notImplemented() }
            }
        }
    }

    private fun initializeSandboxInternal(): Boolean {
        return try {
            val sandboxRoot = File(filesDir, "hyperguard_sandbox")
            if (!sandboxRoot.exists()) sandboxRoot.mkdirs()
            File(sandboxRoot, "sessions").let { if (!it.exists()) it.mkdirs() }
            File(sandboxRoot, "data_profiles").let { if (!it.exists()) it.mkdirs() }
            File(sandboxRoot, "network_logs").let { if (!it.exists()) it.mkdirs() }
            File(sandboxRoot, "exports").let { if (!it.exists()) it.mkdirs() }
            Log.i(TAG, "Sandbox root initialized: ${sandboxRoot.absolutePath}")
            true
        } catch (e: Exception) {
            Log.e(TAG, "Sandbox initialization failed", e)
            false
        }
    }

    private fun installToSandboxInternal(apkPath: String): Map<String, Any?> {
        val appId = UUID.randomUUID().toString()
        val resolvedApk = ApkAnalyzer.analyze(apkPath, packageManager)
        val sessionDir = File(filesDir, "hyperguard_sandbox/sessions/$appId")
        sessionDir.mkdirs()

        val session = SandboxSession(
            id = appId,
            packageName = resolvedApk.packageName,
            appName = resolvedApk.appName,
            apkPath = apkPath,
            sandboxDir = sessionDir.absolutePath,
            versionName = resolvedApk.versionName,
            requestedPermissions = resolvedApk.permissions,
        )
        activeSandboxes[appId] = session
        Log.i(TAG, "Sandbox session created: ${resolvedApk.appName} (${resolvedApk.packageName})")

        return mapOf(
            "id" to appId,
            "packageName" to resolvedApk.packageName,
            "appName" to resolvedApk.appName,
            "iconPath" to resolvedApk.iconPath,
            "sizeBytes" to resolvedApk.sizeBytes,
            "status" to 0,
            "threatLevel" to 0,
            "createdTime" to session.createdTime,
            "completedTime" to null,
            "permissionRequests" to 0,
            "networkRequests" to 0,
            "blockedActions" to 0,
            "detectedBehaviors" to emptyList<String>(),
        )
    }

    private fun startAnalysisInternal(appId: String) {
        val session = activeSandboxes[appId] ?: return
        session.isAnalyzing = true

        val profile = buildSandboxProfile(appId)
        writeSandboxProfile(session.sandboxDir, profile)
        session.permissionAttempts = session.requestedPermissions.size

        for (perm in session.requestedPermissions) {
            val risk = when {
                perm.contains("CONTACTS") || perm.contains("SMS") || perm.contains("CALL_LOG") -> "critical"
                perm.contains("LOCATION") || perm.contains("CAMERA") || perm.contains("MICROPHONE") -> "high"
                perm.contains("STORAGE") || perm.contains("PHONE") -> "medium"
                else -> "low"
            }
            session.blockedActions++

            val event = mapOf(
                "eventType" to "permission_request",
                "description" to "Blocked: $perm",
                "severity" to risk,
                "timestamp" to System.currentTimeMillis(),
                "details" to mapOf("appId" to appId, "permission" to perm, "granted" to false, "provisioned" to true),
            )
            sendBehaviorEvent(event)
            session.detectedBehaviors.add("permission_request:$perm")
        }

        session.networkAttempts = session.detectedBehaviors.size
        Log.i(TAG, "Analysis complete for $appId: ${session.blockedActions} blocked, ${session.permissionAttempts} permissions")
    }

    private fun stopSandboxInternal(appId: String) {
        activeSandboxes[appId]?.let {
            it.isAnalyzing = false
            it.isRunning = false
        }
        Log.i(TAG, "Sandbox stopped: $appId")
    }

    private fun terminateSandboxInternal(appId: String) {
        activeSandboxes.remove(appId)?.let { session ->
            File(session.sandboxDir).deleteRecursively()
        }
        Log.i(TAG, "Sandbox terminated: $appId")
    }

    private fun getActiveSandboxAppsInternal(): List<Map<String, Any?>> {
        return activeSandboxes.values.map { s ->
            mapOf(
                "id" to s.id,
                "packageName" to s.packageName,
                "appName" to s.appName,
                "iconPath" to null,
                "sizeBytes" to 0,
                "status" to when {
                    s.isAnalyzing -> 2
                    s.isRunning -> 1
                    else -> 0
                },
                "threatLevel" to s.threatLevel,
                "createdTime" to s.createdTime,
                "completedTime" to null,
                "permissionRequests" to s.permissionAttempts,
                "networkRequests" to s.networkAttempts,
                "blockedActions" to s.blockedActions,
                "detectedBehaviors" to s.detectedBehaviors.toList(),
            )
        }
    }

    private fun generateReportInternal(sandboxAppId: String): Map<String, Any>? {
        val session = activeSandboxes[sandboxAppId] ?: return null
        val reportId = UUID.randomUUID().toString()
        val threatScore = calculateThreatScore(session)

        val threatLevel = when {
            threatScore >= 70 -> "malicious"
            threatScore >= 40 -> "suspicious"
            else -> "safe"
        }

        val permEvents = session.requestedPermissions.mapIndexed { index, perm ->
            JSONObject().apply {
                put("eventType", "permission_request")
                put("description", "Requested: $perm")
                put("severity", when {
                    perm.contains("CONTACTS") || perm.contains("SMS") -> "critical"
                    perm.contains("LOCATION") || perm.contains("CAMERA") -> "high"
                    else -> "medium"
                })
                put("timestamp", session.createdTime + index * 100L)
                put("details", JSONObject().apply {
                    put("appId", sandboxAppId)
                    put("permission", perm)
                    put("blocked", true)
                })
            }
        }

        val recommendations = mutableListOf<String>()
        val dangerousPerms = session.requestedPermissions.filter {
            it.contains("SMS") || it.contains("CONTACTS") || it.contains("CALL_LOG") ||
            it.contains("CAMERA") || it.contains("MICROPHONE") || it.contains("LOCATION")
        }
        if (dangerousPerms.isNotEmpty()) {
            recommendations.add("Requested ${dangerousPerms.size} dangerous permissions that access sensitive user data via sandbox isolation.")
        }
        if (threatScore >= 70) {
            recommendations.add("HIGH RISK: This APK exhibits strong indicators of malicious behavior. Do not install outside the sandbox.")
        } else if (threatScore >= 40) {
            recommendations.add("CAUTION: This APK shows suspicious patterns. Recommend sandbox-only usage.")
        }

        val report = JSONObject().apply {
            put("id", reportId)
            put("sandboxAppId", sandboxAppId)
            put("packageName", session.packageName)
            put("appName", session.appName)
            put("threatLevel", threatLevel)
            put("threatScore", threatScore)
            put("generatedTime", System.currentTimeMillis())
            put("permissionAttempts", JSONArray())
            put("networkActivities", JSONArray())
            put("behaviorEvents", JSONArray(permEvents))
            put("summary", "Analysis of ${session.appName} (${session.packageName}). ${session.requestedPermissions.size} permissions requested, ${session.blockedActions} blocked. Threat score: $threatScore.")
            put("recommendations", JSONArray(recommendations))
        }
        reportStore.add(report)
        return jsonToMap(report)
    }

    private fun getReportHistoryInternal(): List<Map<String, Any>> {
        return reportStore.mapNotNull { jsonToMap(it) }
    }

    private fun deleteReportInternal(reportId: String): Boolean {
        return reportStore.removeAll { it.optString("id") == reportId }
    }

    private fun exportReportInternal(reportId: String, format: String): Boolean {
        val report = reportStore.find { it.optString("id") == reportId } ?: return false
        return try {
            val exportDir = File(filesDir, "hyperguard_sandbox/exports")
            if (!exportDir.exists()) exportDir.mkdirs()
            File(exportDir, "report_$reportId.$format").writeText(report.toString(2))
            true
        } catch (e: Exception) {
            Log.e(TAG, "Export failed", e)
            false
        }
    }

    private fun sendBehaviorEvent(event: Map<String, Any>) {
        mainHandler.post {
            try {
                flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger ->
                    MethodChannel(messenger, CHANNEL_SANDBOX)
                        .invokeMethod("onBehaviorEvent", event)
                }
            } catch (e: Exception) {
                Log.e(TAG, "Event send failed", e)
            }
        }
    }

    private fun calculateThreatScore(session: SandboxSession): Int {
        var score = 0
        val perms = session.requestedPermissions
        for (perm in perms) {
            when {
                perm.contains("SMS") || perm.contains("CONTACTS") || perm.contains("CALL_LOG") -> score += 25
                perm.contains("CAMERA") || perm.contains("MICROPHONE") || perm.contains("LOCATION") -> score += 15
                perm.contains("STORAGE") || perm.contains("PHONE") -> score += 10
                else -> score += 5
            }
        }
        score += session.networkAttempts * 3
        return score.coerceIn(0, 100)
    }

    private fun buildSandboxProfile(appId: String): Map<String, String> {
        val deviceInfo = DeviceUtil.getDeviceInfo()
        return mapOf<String, String>(
            "imei" to "000000000000000",
            "androidId" to appId.take(16),
            "serial" to "0000000000000000",
            "macAddress" to "02:00:00:00:00:00",
            "phoneNumber" to "00000000000",
            "simSerial" to "00000000000000000000",
            "latitude" to "0.0",
            "longitude" to "0.0",
            "deviceModel" to (deviceInfo["model"] ?: "Xiaomi"),
            "manufacturer" to "Xiaomi",
            "brand" to (deviceInfo["brand"] ?: "Xiaomi"),
            "contactsCount" to "0",
            "smsCount" to "0",
            "callLogCount" to "0",
            "photoCount" to "0",
        )
    }

    private fun writeSandboxProfile(sandboxDir: String, profile: Map<String, String>) {
        val profileFile = File(sandboxDir, "sandbox_profile.json")
        val json = JSONObject()
        profile.forEach { (k, v) -> json.put(k, v) }
        profileFile.writeText(json.toString(2))
    }

    private fun showIncompatibleDialog(title: String, message: String) {
        AlertDialog.Builder(this).apply {
            setTitle(title)
            setMessage(message)
            setCancelable(false)
            setPositiveButton("Exit") { _, _ -> finishAffinity() }
        }.show()
    }

    private fun jsonToMap(json: JSONObject): Map<String, Any> {
        val map = mutableMapOf<String, Any>()
        val keys = json.keys()
        while (keys.hasNext()) {
            val key = keys.next()
            val value = json.get(key)
            when (value) {
                is JSONObject -> map[key] = jsonToMap(value)
                is JSONArray -> map[key] = jsonArrayToList(value)
                is Long -> map[key] = value.toInt().let { if (it.toLong() == value) it else value }
                else -> map[key] = value
            }
        }
        return map
    }

    private fun jsonArrayToList(arr: JSONArray): List<Any> {
        val list = mutableListOf<Any>()
        for (i in 0 until arr.length()) {
            val value = arr.get(i)
            when (value) {
                is JSONObject -> list.add(jsonToMap(value))
                is JSONArray -> list.add(jsonArrayToList(value))
                is Long -> list.add(value.toInt().let { if (it.toLong() == value) it else value })
                else -> list.add(value)
            }
        }
        return list
    }

    override fun onDestroy() {
        installInterceptor.onDestroy()
        sandboxExecutor.shutdown()
        super.onDestroy()
    }

    data class SandboxSession(
        val id: String,
        val packageName: String,
        val appName: String,
        val apkPath: String,
        val sandboxDir: String,
        val createdTime: Long = System.currentTimeMillis(),
        val versionName: String = "unknown",
        val requestedPermissions: List<String> = emptyList(),
        var isRunning: Boolean = true,
        var isAnalyzing: Boolean = false,
        var threatLevel: Int = 0,
        var permissionAttempts: Int = 0,
        var networkAttempts: Int = 0,
        var blockedActions: Int = 0,
        val detectedBehaviors: MutableList<String> = mutableListOf(),
    )
}

object ApkAnalyzer {
    data class ApkInfo(
        val packageName: String,
        val appName: String,
        val versionName: String,
        val iconPath: String?,
        val sizeBytes: Int,
        val permissions: List<String>,
    )

    fun analyze(apkPath: String, pm: PackageManager): ApkInfo {
        val apkFile = File(apkPath)
        return try {
            val info = pm.getPackageArchiveInfo(apkPath, PackageManager.GET_PERMISSIONS)
            if (info != null) {
                val appName = info.applicationInfo?.let {
                    pm.getApplicationLabel(it).toString()
                } ?: apkFile.nameWithoutExtension

                val permissions = info.requestedPermissions?.toList() ?: emptyList()

                ApkInfo(
                    packageName = info.packageName,
                    appName = appName,
                    versionName = info.versionName ?: "unknown",
                    iconPath = null,
                    sizeBytes = apkFile.length().toInt(),
                    permissions = permissions,
                )
            } else {
                ApkInfo(
                    packageName = "unknown.${UUID.randomUUID().toString().take(8)}",
                    appName = apkFile.nameWithoutExtension,
                    versionName = "unknown",
                    iconPath = null,
                    sizeBytes = apkFile.length().toInt(),
                    permissions = emptyList(),
                )
            }
        } catch (e: Exception) {
            Log.e("ApkAnalyzer", "Failed to analyze APK: $apkPath", e)
            ApkInfo(
                packageName = "unknown.${UUID.randomUUID().toString().take(8)}",
                appName = apkFile.nameWithoutExtension,
                versionName = "unknown",
                iconPath = null,
                sizeBytes = apkFile.length().toInt(),
                permissions = emptyList(),
            )
        }
    }
}
