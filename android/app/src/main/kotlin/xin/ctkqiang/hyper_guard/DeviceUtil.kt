package xin.ctkqiang.hyper_guard

import android.os.Build

object DeviceUtil {

    private val XIAOMI_IDENTIFIERS = setOf(
        "xiaomi", "小米", "redmi", "红米", "poco", "miui", "blackshark"
    )

    private val HYPEROS_KEYWORDS = setOf(
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
        if (checkBuildField()) return true
        if (checkSystemProperty()) return true
        return checkBuildFingerprint()
    }

    fun getHyperOSVersion(): String {
        val raw = try {
            val cls = Class.forName("android.os.SystemProperties")
            val method = cls.getMethod("get", String::class.java, String::class.java)
            method.invoke(null, "ro.miui.ui.version.name", "") as String
        } catch (e: Exception) {
            ""
        }

        if (raw.isEmpty()) {
            val fp = (Build.FINGERPRINT ?: "").lowercase()
            val display = (Build.DISPLAY ?: "").lowercase()
            return when {
                fp.contains("os3") || display.contains("os3") -> "3.0"
                fp.contains("os2") || display.contains("os2") -> "2.0"
                fp.contains("os1") || display.contains("os1") -> "1.0"
                else -> "unknown"
            }
        }

        if (raw.uppercase().startsWith("OS")) {
            val numeric = raw.drop(2)
            val parts = numeric.split(".")
            return when {
                parts.size >= 2 -> "${parts[0]}.${parts[1]}"
                parts.size == 1 -> "${parts[0]}.0"
                else -> raw
            }
        }

        return raw
    }

    private fun checkBuildField(): Boolean {
        return try {
            val cls = Class.forName("miui.os.Build")
            cls.getField("IS_HYPER_OS").getBoolean(null)
        } catch (e: Exception) {
            false
        }
    }

    private fun checkSystemProperty(): Boolean {
        return try {
            val cls = Class.forName("android.os.SystemProperties")
            val method = cls.getMethod("get", String::class.java, String::class.java)
            val version = method.invoke(null, "ro.miui.ui.version.name", "") as String
            if (version.isEmpty()) return false
            val lower = version.lowercase()
            if (lower.startsWith("os")) return true
            if (HYPEROS_KEYWORDS.any { lower.contains(it) }) return true
            false
        } catch (e: Exception) {
            false
        }
    }

    private fun checkBuildFingerprint(): Boolean {
        val fingerprint = (Build.FINGERPRINT ?: "").lowercase()
        val display = (Build.DISPLAY ?: "").lowercase()
        if (HYPEROS_KEYWORDS.any { fingerprint.contains(it) || display.contains(it) }) return true
        if (fingerprint.contains("os3") || display.contains("os3")) return true
        if (fingerprint.contains("os2") || display.contains("os2")) return true
        return false
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
            "hyperOSVersion" to getHyperOSVersion(),
            "isXiaomi" to isXiaomiDevice().toString(),
            "isHyperOS" to isHyperOS().toString(),
            "fingerprint" to (Build.FINGERPRINT ?: "unknown"),
        )
    }
}
