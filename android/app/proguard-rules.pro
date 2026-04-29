# HyperGuard ProGuard Rules

-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

-keep class xin.ctkqiang.hyper_guard.HyperGuardNative {
    native <methods>;
    *;
}

-keep class xin.ctkqiangmote .hyper_guard.DeviceUtil { *; }
-keep class xin.ctkqiang.hyper_guard.InstallInterceptor { *; }
-keep class xin.ctkqiang.hyper_guard.InstallInterceptor$* { *; }
-keep class xin.ctkqiang.hyper_guard.MainActivity { *; }
-keep class xin.ctkqiang.hyper_guard.HyperGuardService { *; }
-keep class xin.ctkqiang.hyper_guard.MainActivity$SandboxSession {
    <fields>;
}

-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable

-keepclasseswithmembernames class * {
    native <methods>;
}

-dontwarn com.google.android.play.core.**
-dontwarn org.codehaus.mojo.animal_sniffer.**
-dontwarn javax.annotation.**
