import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/theme/app_theme.dart';
import 'presentation/bloc/device/device_bloc.dart';
import 'presentation/bloc/device/device_event.dart';
import 'presentation/bloc/sandbox/sandbox_bloc.dart';
import 'presentation/bloc/report/report_bloc.dart';
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
      ],
      child: MaterialApp(
        title: 'HyperGuard 澎湃盾',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const SplashScreen(),
      ),
    );
  }
}
