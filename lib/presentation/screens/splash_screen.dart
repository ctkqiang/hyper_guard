import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/theme_colors.dart';
import '../bloc/device/device_bloc.dart';
import '../bloc/device/device_event.dart';
import '../bloc/device/device_state.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  int _step = 0;
  Timer? _timer;

  final List<String> _statusTexts = [
    '验证设备安全环境',
    '检测 HyperOS 系统完整性',
    '初始化蜜罐沙盒引擎',
    '防护系统就绪',
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 900), (_) {
      if (!mounted) return;
      setState(() => _step = (_step + 1) % _statusTexts.length);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);
    return BlocListener<DeviceBloc, DeviceState>(
      listener: (ctx, state) {
        if (state.status == DeviceValidationStatus.compatible) {
          _timer?.cancel();
          Navigator.of(ctx).pushReplacement(
            PageRouteBuilder(
              pageBuilder: (_, a, b) => const HomeScreen(),
              transitionDuration: const Duration(milliseconds: 400),
              transitionsBuilder: (_, a, b, c) =>
                  FadeTransition(opacity: a, child: c),
            ),
          );
        }
      },
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(color: colors.background),
          child: SafeArea(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Spacer(flex: 3),
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: colors.brandGradient,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Image.asset(
                        'assets/applogo.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'HyperGuard',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: colors.textPrimary,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '澎湃盾',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: colors.brandLight,
                      letterSpacing: 6,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'HyperOS Security Sandbox',
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.textMuted,
                      letterSpacing: 1,
                    ),
                  ),
                  const Spacer(flex: 2),
                  BlocBuilder<DeviceBloc, DeviceState>(
                    builder: (ctx, state) {
                      return switch (state.status) {
                        DeviceValidationStatus.checking ||
                        DeviceValidationStatus.initial => _checking(colors),
                        DeviceValidationStatus.incompatible => _incompatible(
                          state.errorMessage,
                          colors,
                          ctx,
                        ),
                        DeviceValidationStatus.error => _retry(
                          state.errorMessage,
                          colors,
                          ctx,
                        ),
                        _ => const SizedBox.shrink(),
                      };
                    },
                  ),
                  const Spacer(flex: 3),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _checking(ThemeColors colors) {
    return Column(
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Text(
            _statusTexts[_step],
            key: ValueKey(_step),
            style: TextStyle(fontSize: 13, color: colors.textSecondary),
          ),
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation<Color>(colors.brandLight),
          ),
        ),
      ],
    );
  }

  Widget _incompatible(String? msg, ThemeColors colors, BuildContext ctx) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: colors.danger.withValues(alpha: 0.1),
            ),
            child: Icon(
              Icons.smartphone_rounded,
              color: colors.danger,
              size: 28,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            msg ?? '设备不兼容',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: colors.textSecondary,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              decoration: BoxDecoration(
                color: colors.danger.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                '退出应用',
                style: TextStyle(
                  color: colors.danger,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _retry(String? msg, ThemeColors colors, BuildContext ctx) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: colors.warning.withValues(alpha: 0.1),
            ),
            child: Icon(
              Icons.error_outline_rounded,
              color: colors.warning,
              size: 28,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            msg ?? '检测异常',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: colors.textSecondary,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () => ctx.read<DeviceBloc>().add(const CheckDevice()),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: colors.brandGradient,
              ),
              child: const Text(
                '重试',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
