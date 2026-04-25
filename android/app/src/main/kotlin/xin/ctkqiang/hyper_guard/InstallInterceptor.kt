package xin.ctkqiang.hyper_guard

import android.app.Activity
import android.app.AlertDialog
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.net.Uri
import android.os.Build
import android.util.Log
import androidx.annotation.RequiresApi
import java.io.File

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
        fun onInstallTypeSelected(type: InstallType)
    }

    enum class InstallType {
        NORMAL_INSTALL,
        SANDBOX_INSTALL
    }

    private var callback: InstallCallback? = null
    private var isRegistered = false

    private val packageReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (intent?.action == Intent.ACTION_PACKAGE_ADDED) {
                val packageName = intent.data?.schemeSpecificPart ?: return
                Log.d(TAG, "Package added detected: $packageName")
                if (intent.getBooleanExtra(Intent.EXTRA_REPLACING, false)) {
                    return
                }
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
                activity.registerReceiver(
                    packageReceiver,
                    filter,
                    Context.RECEIVER_EXPORTED
                )
            } else {
                activity.registerReceiver(packageReceiver, filter)
            }
            isRegistered = true
            Log.d(TAG, "Install interceptor registered")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to register interceptor", e)
        }
    }

    fun unregister() {
        if (!isRegistered) return
        try {
            activity.unregisterReceiver(packageReceiver)
            isRegistered = false
            Log.d(TAG, "Install interceptor unregistered")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to unregister interceptor", e)
        }
    }

    fun showInstallDialog(packageName: String, apkPath: String) {
        AlertDialog.Builder(activity).apply {
            setTitle("HyperGuard 安装拦截")
            setMessage(
                "检测到 APK 安装请求\n\n" +
                "包名: $packageName\n\n" +
                "请选择安装方式："
            )
            setPositiveButton("蜜罐安全安装") { _, _ ->
                callback?.onInstallTypeSelected(InstallType.SANDBOX_INSTALL)
                Log.d(TAG, "Sandbox install selected for: $packageName")
            }
            setNegativeButton("正常安装") { _, _ ->
                callback?.onInstallTypeSelected(InstallType.NORMAL_INSTALL)
                Log.d(TAG, "Normal install selected for: $packageName")
            }
            setNeutralButton("取消") { _, _ ->
                Log.d(TAG, "Install cancelled for: $packageName")
            }
            setCancelable(false)
        }.show()
    }

    fun installApkNormal(apkPath: String) {
        try {
            val apkFile = File(apkPath)
            if (!apkFile.exists()) {
                Log.e(TAG, "APK file not found: $apkPath")
                return
            }
            val intent = Intent(Intent.ACTION_VIEW).apply {
                setDataAndType(
                    Uri.fromFile(apkFile),
                    "application/vnd.android.package-archive"
                )
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                    addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                }
            }
            activity.startActivity(intent)
            Log.d(TAG, "Normal install started for: $apkPath")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start normal install", e)
        }
    }

    fun onDestroy() {
        unregister()
        callback = null
        instance = null
    }
}
