import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../bloc/device/device_bloc.dart';
import '../bloc/device/device_event.dart';
import '../bloc/device/device_state.dart';
import '../../core/theme/app_theme.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<DeviceBloc, DeviceState>(
      listener: (context, state) {
        if (state.status == DeviceValidationStatus.compatible) {
          Navigator.of(context).pushReplacement(
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => const HomeScreen(),
              transitionDuration: const Duration(milliseconds: 600),
              transitionsBuilder: (_, animation, __, child) {
                return FadeScaleTransition(animation: animation, child: child);
              },
            ),
          );
        }
      },
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.bgDeep, AppTheme.bgSurface, AppTheme.bgDeep],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: child,
                    );
                  },
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppTheme.primaryGradient,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryNeon.withValues(alpha: 0.5),
                          blurRadius: 40,
                          spreadRadius: 8,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.shield_rounded,
                      color: Colors.black,
                      size: 48,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'HyperGuard',
                  style: GoogleFonts.orbitron(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4,
                    color: AppTheme.primaryNeon,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '澎湃盾',
                  style: GoogleFonts.orbitron(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 6,
                    color: AppTheme.shieldGold,
                  ),
                ),
                const SizedBox(height: 30),
                BlocBuilder<DeviceBloc, DeviceState>(
                  builder: (context, state) {
                    switch (state.status) {
                      case DeviceValidationStatus.checking:
                        return _buildCheckingWidget();
                      case DeviceValidationStatus.initial:
                        return _buildCheckingWidget();
                      case DeviceValidationStatus.incompatible:
                        return _buildIncompatibleWidget(state.errorMessage);
                      case DeviceValidationStatus.error:
                        return _buildRetryWidget(state.errorMessage);
                      default:
                        return const SizedBox.shrink();
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCheckingWidget() {
    return Column(
      children: [
        const SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryNeon),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          '正在验证设备安全环境...',
          style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
        ),
      ],
    );
  }

  Widget _buildIncompatibleWidget(String? message) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: [
          const Icon(
            Icons.gpp_bad_rounded,
            color: AppTheme.accentDanger,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            message ?? '设备不兼容',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 24),
          NezhaSmallButton(
            label: '退出应用',
            onPressed: () {},
            color: AppTheme.accentDanger,
          ),
        ],
      ),
    );
  }

  Widget _buildRetryWidget(String? message) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppTheme.accentWarning,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            message ?? '检测出错',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 24),
          NezhaSmallButton(
            label: '重试',
            onPressed: () {
              context.read<DeviceBloc>().add(const CheckDevice());
            },
            color: AppTheme.primaryNeon,
          ),
        ],
      ),
    );
  }
}

class NezhaSmallButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color color;

  const NezhaSmallButton({
    super.key,
    required this.label,
    this.onPressed,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: color,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }
}
