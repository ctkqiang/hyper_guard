package xin.ctkqiang.hyper_guard

import android.util.Log

object HyperGuardNative {

    private const val TAG = "HyperGuardNative"
    private var isLoaded = false

    init {
        try {
            System.loadLibrary("hyperguard_sandbox")
            isLoaded = true
            Log.d(TAG, "Native library loaded successfully")
        } catch (e: UnsatisfiedLinkError) {
            isLoaded = false
            Log.e(TAG, "Failed to load native library: ${e.message}")
        }
    }

    fun isAvailable(): Boolean = isLoaded

    fun setFlutterCallback(callback: NativeCallback) {
        if (!isLoaded) return
        nativeSetFlutterCallback(callback)
    }

    fun nativeInitialize(sandboxDir: String): Boolean {
        if (!isLoaded) return false
        return try {
            nativeInit(sandboxDir)
        } catch (e: Exception) {
            Log.e(TAG, "Native initialize error", e)
            false
        }
    }

    fun nativeCreateSession(
        appId: String,
        packageName: String,
        appName: String,
        apkPath: String
    ): Boolean {
        if (!isLoaded) return false
        return try {
            nativeSessionCreate(appId, packageName, appName, apkPath)
        } catch (e: Exception) {
            Log.e(TAG, "Native create session error", e)
            false
        }
    }

    fun nativeStartAnalysis(appId: String): Boolean {
        if (!isLoaded) return false
        return try {
            nativeAnalysisStart(appId)
        } catch (e: Exception) {
            Log.e(TAG, "Native start analysis error", e)
            false
        }
    }

    fun nativeStopSession(appId: String): Boolean {
        if (!isLoaded) return false
        return try {
            nativeSessionStop(appId)
        } catch (e: Exception) {
            Log.e(TAG, "Native stop session error", e)
            false
        }
    }

    fun nativeTerminateSession(appId: String): Boolean {
        if (!isLoaded) return false
        return try {
            nativeSessionTerminate(appId)
        } catch (e: Exception) {
            Log.e(TAG, "Native terminate session error", e)
            false
        }
    }

    fun nativeCalculateThreatScore(appId: String): Int {
        if (!isLoaded) return 0
        return try {
            nativeThreatScore(appId)
        } catch (e: Exception) {
            Log.e(TAG, "Native threat score error", e)
            0
        }
    }

    fun nativeGetFakeProfile(): Map<String, String> {
        if (!isLoaded) return emptyMap()
        return try {
            nativeFakeProfile()
        } catch (e: Exception) {
            Log.e(TAG, "Native fake profile error", e)
            emptyMap()
        }
    }

    fun nativeGetFakeImei(): String {
        if (!isLoaded) return ""
        return try {
            nativeFakeImei()
        } catch (e: Exception) {
            Log.e(TAG, "Native fake IMEI error", e)
            ""
        }
    }

    fun nativeGetFakeAndroidId(): String {
        if (!isLoaded) return ""
        return try {
            nativeFakeAndroidId()
        } catch (e: Exception) {
            Log.e(TAG, "Native fake Android ID error", e)
            ""
        }
    }

    interface NativeCallback {
        fun onNativeEvent(channel: String, method: String, data: String)
    }

    private external fun nativeSetFlutterCallback(callback: NativeCallback)

    @JvmStatic
    private external fun nativeInit(sandboxDir: String): Boolean

    @JvmStatic
    private external fun nativeSessionCreate(
        appId: String,
        packageName: String,
        appName: String,
        apkPath: String
    ): Boolean

    @JvmStatic
    private external fun nativeAnalysisStart(appId: String): Boolean

    @JvmStatic
    private external fun nativeSessionStop(appId: String): Boolean

    @JvmStatic
    private external fun nativeSessionTerminate(appId: String): Boolean

    @JvmStatic
    private external fun nativeThreatScore(appId: String): Int

    @JvmStatic
    private external fun nativeFakeProfile(): Map<String, String>

    @JvmStatic
    private external fun nativeFakeImei(): String

    @JvmStatic
    private external fun nativeFakeAndroidId(): String
}
