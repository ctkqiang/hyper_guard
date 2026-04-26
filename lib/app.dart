import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/theme/app_theme.dart';
import 'presentation/bloc/device/device_bloc.dart';
import 'presentation/bloc/device/device_event.dart';
import 'presentation/bloc/sandbox/sandbox_bloc.dart';
import 'presentation/bloc/report/report_bloc.dart';
import 'presentation/bloc/theme/theme_bloc.dart';
import 'presentation/bloc/theme/theme_state.dart';
import 'presentation/screens/splash_screen.dart';
import 'services/device_service.dart';
import 'services/sandbox_service.dart';
import 'services/monitor_service.dart';

class HyperGuardApp extends StatelessWidget {
  const HyperGuardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<DeviceBloc>(
          create: (_) =>
              DeviceBloc(deviceService: DeviceService())
                ..add(const CheckDevice()),
        ),
        BlocProvider<SandboxBloc>(
          create: (_) => SandboxBloc(
            sandboxService: SandboxService(),
            monitorService: MonitorService(),
          ),
        ),
        BlocProvider<ReportBloc>(
          create: (_) => ReportBloc(monitorService: MonitorService()),
        ),
        BlocProvider<ThemeBloc>(create: (_) => ThemeBloc()),
      ],
      child: BlocBuilder<ThemeBloc, ThemeState>(
        builder: (context, themeState) {
          final themeMode = switch (themeState.mode) {
            AppThemeMode.light => ThemeMode.light,
            AppThemeMode.dark => ThemeMode.dark,
            AppThemeMode.system => ThemeMode.system,
          };

          final Brightness systemBrightness =
              WidgetsBinding.instance.platformDispatcher.platformBrightness;
          final bool isDark = switch (themeState.mode) {
            AppThemeMode.light => false,
            AppThemeMode.dark => true,
            AppThemeMode.system => systemBrightness == Brightness.dark,
          };

          final Color navBarColor = isDark
              ? AppTheme.slate900
              : AppTheme.slate50;
          final Brightness navBarIconBrightness = isDark
              ? Brightness.light
              : Brightness.dark;

          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: isDark
                  ? Brightness.light
                  : Brightness.dark,
              systemNavigationBarColor: navBarColor,
              systemNavigationBarIconBrightness: navBarIconBrightness,
            ),
            child: MaterialApp(
              title: 'HyperGuard',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              themeMode: themeMode,
              home: const SplashScreen(),
            ),
          );
        },
      ),
    );
  }
}
