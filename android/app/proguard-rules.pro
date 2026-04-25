# HyperGuard ProGuard Rules

# Keep Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep HyperGuard native methods
-keep class xin.ctkqiang.hyper_guard.HyperGuardNative {
    native <methods>;
    *;
}

# Keep HyperGuard core classes
-keep class xin.ctkqiang.hyper_guard.DeviceUtil { *; }
-keep class xin.ctkqiang.hyper_guard.InstallInterceptor { *; }
-keep class xin.ctkqiang.hyper_guard.InstallInterceptor$* { *; }
-keep class xin.ctkqiang.hyper_guard.MainActivity { *; }
-keep class xin.ctkqiang.hyper_guard.HyperGuardService { *; }
-keep class xin.ctkqiang.hyper_guard.MainActivity$SandboxSession { *; }

# Keep data classes for serialization
-keep class xin.ctkqiang.hyper_guard.MainActivity$SandboxSession {
    <fields>;
}

# Keep model classes
-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable

# Keep JNI
-keepclasseswithmembernames class * {
    native <methods>;
}

# Dont warn
-dontwarn org.codehaus.mojo.animal_sniffer.**
-dontwarn javax.annotation.**
