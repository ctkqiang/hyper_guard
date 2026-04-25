package xin.ctkqiang.hyper_guard

import android.os.Build

object DeviceUtil {

    private val XIAOMI_IDENTIFIERS = setOf(
        "xiaomi", "小米", "redmi", "红米", "poco", "miui", "blackshark"
    )

    private val HYPEROS_IDENTIFIERS = setOf(
        "hyperos", "hyper_os", "hyper os", "澎湃os", "澎湃 os"
    )

    fun isXiaomiDevice(): Boolean {
        val manufacturer = Build.MANUFACTURER.lowercase()
        val brand = Build.BRAND.lowercase()
        val model = Build.MODEL.lowercase()
        return XIAOMI_IDENTIFIERS.any {
            manufacturer.contains(it) || brand.contains(it) || model.contains(it)
        }
    }

    fun isHyperOS(): Boolean {
        return try {
            val cls = Class.forName("miui.os.Build")
            cls.getField("IS_HYPER_OS").getBoolean(null)
        } catch (e: NoSuchFieldException) {
            try {
                val cls = Class.forName("android.os.SystemProperties")
                val method = cls.getMethod("get", String::class.java, String::class.java)
                val version = method.invoke(null, "ro.miui.ui.version.name", "") as String
                HYPEROS_IDENTIFIERS.any { version.lowercase().contains(it) }
            } catch (ex: Exception) {
                checkBuildFingerprint()
            }
        } catch (e: Exception) {
            checkBuildFingerprint()
        }
    }

    private fun checkBuildFingerprint(): Boolean {
        val fingerprint = (Build.FINGERPRINT ?: "").lowercase()
        val display = (Build.DISPLAY ?: "").lowercase()
        return HYPEROS_IDENTIFIERS.any {
            fingerprint.contains(it) || display.contains(it)
        }
    }

    fun getDeviceInfo(): Map<String, String> {
        return mapOf(
            "manufacturer" to (Build.MANUFACTURER ?: "unknown"),
            "brand" to (Build.BRAND ?: "unknown"),
            "model" to (Build.MODEL ?: "unknown"),
            "device" to (Build.DEVICE ?: "unknown"),
            "product" to (Build.PRODUCT ?: "unknown"),
            "hardware" to (Build.HARDWARE ?: "unknown"),
            "androidVersion" to Build.VERSION.RELEASE,
            "sdkVersion" to Build.VERSION.SDK_INT.toString(),
            "isXiaomi" to isXiaomiDevice().toString(),
            "isHyperOS" to isHyperOS().toString(),
            "fingerprint" to (Build.FINGERPRINT ?: "unknown"),
        )
    }
}
