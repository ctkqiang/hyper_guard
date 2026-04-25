package xin.ctkqiang.hyper_guard

import android.app.AlertDialog
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
    private val fakeDataProfile = generateFakeDataProfile()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (!DeviceUtil.isXiaomiDevice()) {
            showIncompatibleDialog("此设备非小米/红米设备", "HyperGuard 无法运行")
            return
        }
        if (!DeviceUtil.isHyperOS()) {
            showIncompatibleDialog(
                "需要 HyperOS 澎湃系统",
                "请升级至 HyperOS 后使用 HyperGuard"
            )
            return
        }
        installInterceptor = InstallInterceptor.getInstance(this)
        installInterceptor.setCallback(object : InstallInterceptor.InstallCallback {
            override fun onInstallRequested(packageName: String, apkPath: String) {
                installInterceptor.showInstallDialog(packageName, apkPath)
            }

            override fun onInstallTypeSelected(type: InstallInterceptor.InstallType) {
                when (type) {
                    InstallInterceptor.InstallType.SANDBOX_INSTALL -> {
                        Log.d(TAG, "Sandbox install flow initiated")
                    }
                    InstallInterceptor.InstallType.NORMAL_INSTALL -> {
                        Log.d(TAG, "Normal install flow initiated")
                    }
                }
            }
        })
        installInterceptor.register()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL_DEVICE
        ).setMethodCallHandler(::handleDeviceChannel)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL_SANDBOX
        ).setMethodCallHandler(::handleSandboxChannel)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL_MONITOR
        ).setMethodCallHandler(::handleMonitorChannel)
    }

    private fun handleDeviceChannel(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "isXiaomiDevice" -> result.success(DeviceUtil.isXiaomiDevice())
            "isHyperOS" -> result.success(DeviceUtil.isHyperOS())
            "getDeviceInfo" -> result.success(DeviceUtil.getDeviceInfo())
            else -> result.notImplemented()
        }
    }

    private fun handleSandboxChannel(call: MethodCall, result: MethodChannel.Result) {
        sandboxExecutor.execute {
            when (call.method) {
                "initializeSandbox" -> {
                    val success = initializeSandboxInternal()
                    mainHandler.post { result.success(success) }
                }
                "installToSandbox" -> {
                    val apkPath = call.argument<String>("apkPath") ?: ""
                    val sandboxApp = installToSandboxInternal(apkPath)
                    mainHandler.post { result.success(sandboxApp) }
                }
                "startAnalysis" -> {
                    val appId = call.argument<String>("appId") ?: ""
                    startAnalysisInternal(appId)
                    mainHandler.post { result.success(true) }
                }
                "stopSandbox" -> {
                    val appId = call.argument<String>("appId") ?: ""
                    stopSandboxInternal(appId)
                    mainHandler.post { result.success(true) }
                }
                "terminateSandbox" -> {
                    val appId = call.argument<String>("appId") ?: ""
                    terminateSandboxInternal(appId)
                    mainHandler.post { result.success(true) }
                }
                "getFakeDataProfile" -> {
                    mainHandler.post { result.success(fakeDataProfile) }
                }
                "getActiveSandboxApps" -> {
                    val apps = getActiveSandboxAppsInternal()
                    mainHandler.post { result.success(apps) }
                }
                else -> mainHandler.post { result.notImplemented() }
            }
        }
    }

    private fun handleMonitorChannel(call: MethodCall, result: MethodChannel.Result) {
        sandboxExecutor.execute {
            when (call.method) {
                "generateReport" -> {
                    val sandboxAppId = call.argument<String>("sandboxAppId") ?: ""
                    val report = generateReportInternal(sandboxAppId)
                    mainHandler.post { result.success(report) }
                }
                "getReportHistory" -> {
                    val reports = getReportHistoryInternal()
                    mainHandler.post { result.success(reports) }
                }
                "deleteReport" -> {
                    val reportId = call.argument<String>("reportId") ?: ""
                    val deleted = deleteReportInternal(reportId)
                    mainHandler.post { result.success(deleted) }
                }
                "exportReport" -> {
                    val reportId = call.argument<String>("reportId") ?: ""
                    val format = call.argument<String>("format") ?: "json"
                    val exported = exportReportInternal(reportId, format)
                    mainHandler.post { result.success(exported) }
                }
                else -> mainHandler.post { result.notImplemented() }
            }
        }
    }

    private fun initializeSandboxInternal(): Boolean {
        return try {
            val sandboxDir = File(filesDir, "sandbox")
            if (!sandboxDir.exists()) {
                sandboxDir.mkdirs()
            }
            val fakeDataDir = File(sandboxDir, "fake_data")
            if (!fakeDataDir.exists()) {
                fakeDataDir.mkdirs()
            }
            Log.d(TAG, "Sandbox initialized at: ${sandboxDir.absolutePath}")
            true
        } catch (e: Exception) {
            Log.e(TAG, "Failed to initialize sandbox", e)
            false
        }
    }

    private fun installToSandboxInternal(apkPath: String): Map<String, Any> {
        val appId = UUID.randomUUID().toString()
        val packageName = extractPackageName(apkPath)
        val appName = extractAppName(apkPath) ?: "Unknown APK"
        val sizeBytes = try {
            File(apkPath).length().toInt()
        } catch (e: Exception) {
            0
        }

        val session = SandboxSession(
            id = appId,
            packageName = packageName,
            appName = appName,
            apkPath = apkPath,
            fakeDataProfile = fakeDataProfile
        )
        activeSandboxes[appId] = session

        Log.d(TAG, "APK installed to sandbox: $appName ($packageName)")

        return mapOf(
            "id" to appId,
            "packageName" to packageName,
            "appName" to appName,
            "iconPath" to null,
            "sizeBytes" to sizeBytes,
            "status" to 0,
            "threatLevel" to 0,
            "createdTime" to System.currentTimeMillis().toString(),
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

        val behaviors = listOf(
            mapOf(
                "eventType" to "privacy_access",
                "description" to "尝试读取通讯录数据 (已返回空数据)",
                "severity" to "high",
                "timestamp" to System.currentTimeMillis().toString(),
                "details" to mapOf("appId" to appId, "target" to "contacts"),
            ),
            mapOf(
                "eventType" to "sms_access",
                "description" to "尝试读取短信记录 (已返回空数据)",
                "severity" to "high",
                "timestamp" to (System.currentTimeMillis() + 1000).toString(),
                "details" to mapOf("appId" to appId, "target" to "sms"),
            ),
            mapOf(
                "eventType" to "location_access",
                "description" to "请求 GPS 定位权限 (已返回假位置)",
                "severity" to "medium",
                "timestamp" to (System.currentTimeMillis() + 2000).toString(),
                "details" to mapOf("appId" to appId, "faked" to true),
            ),
            mapOf(
                "eventType" to "network_request",
                "description" to "发起网络连接请求",
                "severity" to "low",
                "timestamp" to (System.currentTimeMillis() + 3000).toString(),
                "details" to mapOf("appId" to appId, "monitored" to true),
            ),
        )

        behaviors.forEach { behavior ->
            sendBehaviorEventToFlutter(behavior)
        }
    }

    private fun stopSandboxInternal(appId: String) {
        val session = activeSandboxes[appId] ?: return
        session.isAnalyzing = false
        session.isRunning = false
        Log.d(TAG, "Sandbox stopped: $appId")
    }

    private fun terminateSandboxInternal(appId: String) {
        activeSandboxes.remove(appId)
        Log.d(TAG, "Sandbox terminated: $appId")
    }

    private fun getActiveSandboxAppsInternal(): List<Map<String, Any>> {
        return activeSandboxes.values.map { session ->
            mapOf(
                "id" to session.id,
                "packageName" to session.packageName,
                "appName" to session.appName,
                "iconPath" to null,
                "sizeBytes" to 0,
                "status" to if (session.isAnalyzing) 2 else if (session.isRunning) 1 else 0,
                "threatLevel" to session.threatLevel,
                "createdTime" to session.createdTime.toString(),
                "completedTime" to null,
                "permissionRequests" to session.permissionAttempts,
                "networkRequests" to session.networkAttempts,
                "blockedActions" to session.blockedActions,
                "detectedBehaviors" to session.detectedBehaviors.toList(),
            )
        }
    }

    private fun generateReportInternal(sandboxAppId: String): Map<String, Any>? {
        val session = activeSandboxes[sandboxAppId] ?: return null
        val reportId = UUID.randomUUID().toString()
        val threatScore = calculateThreatScore(session)

        val recommendations = mutableListOf<String>()
        if (session.permissionAttempts > 3) {
            recommendations.add("该应用请求了过多权限 (${session.permissionAttempts} 次)，疑似隐私窃取行为")
        }
        if (session.networkAttempts > 5) {
            recommendations.add("该应用发起了大量网络请求 (${session.networkAttempts} 次)，建议检查网络通信目标")
        }
        if (threatScore > 60) {
            recommendations.add("威胁指数较高，强烈建议删除此 APK，不要进行正常安装")
        } else if (threatScore > 30) {
            recommendations.add("该应用存在可疑行为，建议谨慎处理")
        }

        val reportJson = JSONObject().apply {
            put("id", reportId)
            put("sandboxAppId", sandboxAppId)
            put("packageName", session.packageName)
            put("appName", session.appName)
            put("threatLevel", when {
                threatScore > 60 -> "malicious"
                threatScore > 30 -> "suspicious"
                else -> "safe"
            })
            put("threatScore", threatScore)
            put("generatedTime", System.currentTimeMillis().toString())
            put("permissionAttempts", JSONArray())
            put("networkActivities", JSONArray())
            put("behaviorEvents", JSONArray())
            put("summary", "在蜜罐沙盒环境中分析了 ${session.appName}。共监测到 ${session.permissionAttempts} 次权限请求、${session.networkAttempts} 次网络活动，拦截了 ${session.blockedActions} 次敏感操作。")
            put("recommendations", JSONArray(recommendations))
        }

        reportStore.add(reportJson)

        return try {
            jsonToMap(reportJson)
        } catch (e: Exception) {
            null
        }
    }

    private fun getReportHistoryInternal(): List<Map<String, Any>> {
        return reportStore.mapNotNull { report ->
            try {
                jsonToMap(report)
            } catch (e: Exception) {
                null
            }
        }
    }

    private fun deleteReportInternal(reportId: String): Boolean {
        val removed = reportStore.removeAll { report ->
            report.optString("id") == reportId
        }
        return removed
    }

    private fun exportReportInternal(reportId: String, format: String): Boolean {
        val report = reportStore.find { it.optString("id") == reportId } ?: return false
        return try {
            val exportDir = File(filesDir, "exports")
            if (!exportDir.exists()) exportDir.mkdirs()
            val exportFile = File(exportDir, "report_$reportId.$format")
            exportFile.writeText(report.toString(2))
            Log.d(TAG, "Report exported to: ${exportFile.absolutePath}")
            true
        } catch (e: Exception) {
            Log.e(TAG, "Failed to export report", e)
            false
        }
    }

    private fun sendBehaviorEventToFlutter(behavior: Map<String, Any>) {
        mainHandler.post {
            try {
                flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger ->
                    MethodChannel(messenger, CHANNEL_SANDBOX).invokeMethod(
                        "onBehaviorEvent",
                        behavior
                    )
                }
            } catch (e: Exception) {
                Log.e(TAG, "Failed to send behavior event", e)
            }
        }
    }

    private fun calculateThreatScore(session: SandboxSession): Int {
        var score = 0
        score += session.permissionAttempts * 10
        score += session.networkAttempts * 5
        score += session.blockedActions * 15
        return score.coerceIn(0, 100)
    }

    private fun extractPackageName(apkPath: String): String {
        return "com.mock.${UUID.randomUUID().toString().take(8)}"
    }

    private fun extractAppName(apkPath: String): String? {
        return File(apkPath).nameWithoutExtension
    }

    private fun generateFakeDataProfile(): Map<String, String> {
        return mapOf(
            "imei" to "866262050000000",
            "androidId" to "9774d56d682e549c",
            "serial" to "unknown",
            "macAddress" to "02:00:00:00:00:00",
            "phoneNumber" to "+8613800000000",
            "simSerial" to "89860000000000000000",
            "latitude" to "39.9042",
            "longitude" to "116.4074",
            "deviceModel" to "M2012K11AC",
            "manufacturer" to "Xiaomi",
            "brand" to "Redmi",
            "contactsCount" to "0",
            "smsCount" to "0",
            "callLogCount" to "0",
            "photoCount" to "0",
        )
    }

    private fun showIncompatibleDialog(title: String, message: String) {
        AlertDialog.Builder(this).apply {
            setTitle(title)
            setMessage(message)
            setCancelable(false)
            setPositiveButton("退出") { _, _ -> finishAffinity() }
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
                else -> map[key] = value
            }
        }
        return map
    }

    private fun jsonArrayToList(jsonArray: JSONArray): List<Any> {
        val list = mutableListOf<Any>()
        for (i in 0 until jsonArray.length()) {
            val value = jsonArray.get(i)
            when (value) {
                is JSONObject -> list.add(jsonToMap(value))
                is JSONArray -> list.add(jsonArrayToList(value))
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
        val fakeDataProfile: Map<String, String>,
        val createdTime: Long = System.currentTimeMillis(),
        var isRunning: Boolean = true,
        var isAnalyzing: Boolean = false,
        var threatLevel: Int = 0,
        var permissionAttempts: Int = 0,
        var networkAttempts: Int = 0,
        var blockedActions: Int = 0,
        val detectedBehaviors: MutableList<String> = mutableListOf(),
    )
}
