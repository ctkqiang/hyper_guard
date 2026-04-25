package xin.ctkqiang.hyper_guard

import android.app.AlertDialog
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {

    companion object {
        private val XIAOMI_IDENTIFIERS = setOf("xiaomi", "redmi", "poco", "blackshark")
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (!isXiaomiDevice()) {
            AlertDialog.Builder(this)
                .setTitle("Device Not Supported")
                .setMessage("This application is exclusively designed for Xiaomi devices.")
                .setCancelable(false)
                .setPositiveButton("Exit") { _, _ ->
                    finishAffinity()
                }
                .show()
            return
        }
    }

    private fun isXiaomiDevice(): Boolean {
        val manufacturer = Build.MANUFACTURER.lowercase()
        val brand = Build.BRAND.lowercase()
        return XIAOMI_IDENTIFIERS.any { it == manufacturer || it == brand }
    }
}
