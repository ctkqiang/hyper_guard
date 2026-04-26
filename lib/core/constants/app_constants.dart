class AppConstants {
  AppConstants._();

  static const String appName = 'HyperGuard';
  static const String appNameCN = '澎湃盾';
  static const String version = '1.0.0';
  static const String channelDevice = 'xin.ctkqiang.hyper_guard/device';
  static const String channelSandbox = 'xin.ctkqiang.hyper_guard/sandbox';
  static const String channelMonitor = 'xin.ctkqiang.hyper_guard/monitor';
  static const String channelInstall = 'xin.ctkqiang.hyper_guard/install';

  static const Duration scanTimeout = Duration(seconds: 30);
  static const Duration sandboxTimeout = Duration(minutes: 5);
  static const int maxSandboxApps = 5;
  static const int maxReportHistory = 50;

  static const Set<String> requiredPermissions = {
    'android.permission.READ_PHONE_STATE',
    'android.permission.ACCESS_FINE_LOCATION',
    'android.permission.READ_CONTACTS',
    'android.permission.READ_SMS',
    'android.permission.REQUEST_INSTALL_PACKAGES',
  };
}
