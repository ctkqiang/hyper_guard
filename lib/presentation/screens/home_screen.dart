import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/theme_colors.dart';
import '../../data/models/security_report.dart';
import '../widgets/sandbox_app_tile.dart';
import '../bloc/sandbox/sandbox_bloc.dart';
import '../bloc/sandbox/sandbox_event.dart';
import '../bloc/sandbox/sandbox_state.dart';
import '../bloc/report/report_bloc.dart';
import '../bloc/report/report_event.dart';
import '../bloc/report/report_state.dart';
import '../bloc/theme/theme_bloc.dart';
import '../bloc/theme/theme_event.dart';
import '../bloc/theme/theme_state.dart';
import 'sandbox_screen.dart';
import 'report_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    context.read<SandboxBloc>().add(const InitializeSandbox());
    context.read<ReportBloc>().add(const LoadReportHistory());
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);
    return Scaffold(
      body: IndexedStack(
        index: _tabIndex,
        children: [
          _dashboard(colors),
          const SandboxScreen(),
          const ReportScreen(),
          _settings(colors),
        ],
      ),
      bottomNavigationBar: _bottomNav(colors),
    );
  }

  Widget _dashboard(ThemeColors colors) {
    return SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header(colors),
            const SizedBox(height: 12),
            _statusBanner(colors),
            const SizedBox(height: 20),
            _quickActions(colors),
            const SizedBox(height: 24),
            _activeSandboxes(colors),
            const SizedBox(height: 20),
            _recentThreats(colors),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _header(ThemeColors colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: colors.brandGradient,
            ),
            child: const Icon(
              Icons.shield_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'HyperGuard',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: colors.textPrimary,
                  letterSpacing: 1,
                ),
              ),
              Text(
                '澎湃盾 · 蜜罐沙盒防护系统',
                style: TextStyle(
                  fontSize: 11,
                  color: colors.textMuted,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: colors.success.withValues(alpha: 0.08),
              border: Border.all(
                color: colors.success.withValues(alpha: 0.2),
                width: 0.5,
              ),
            ),
            child: Icon(
              Icons.verified_user_rounded,
              color: colors.success,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBanner(ThemeColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              colors.brandMain.withValues(alpha: 0.06),
              colors.brandLight.withValues(alpha: 0.02),
            ],
          ),
          border: Border.all(color: colors.cardBorder, width: 0.5),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: colors.brandGradient,
              ),
              child: const Icon(
                Icons.security_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '澎湃防护系统已激活',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '安装拦截 · 蜜罐沙盒 · 行为审计 · 威胁分析',
                    style: TextStyle(fontSize: 12, color: colors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickActions(ThemeColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              '安全操作',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colors.textSecondary,
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: _actionTile(
                  Icons.bug_report_rounded,
                  'APK 安全扫描',
                  colors.brandLight,
                  () => _switchTo(1),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _actionTile(
                  Icons.shield_rounded,
                  '蜜罐安全安装',
                  colors.warning,
                  () => _switchTo(1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _actionTile(
                  Icons.analytics_rounded,
                  '安全报告中心',
                  colors.success,
                  () => _switchTo(2),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _actionTile(
                  Icons.tune_rounded,
                  '防护策略配置',
                  colors.brandLight,
                  () => _switchTo(3),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _activeSandboxes(ThemeColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              '活跃沙盒',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colors.textSecondary,
              ),
            ),
          ),
          BlocBuilder<SandboxBloc, SandboxState>(
            builder: (_, state) {
              if (state.activeApps.isEmpty) {
                return _emptyHint(
                  Icons.inbox_rounded,
                  '暂无活跃沙盒',
                  '开始蜜罐安装',
                  () => _switchTo(1),
                  colors,
                );
              }
              return Column(
                children: state.activeApps
                    .map(
                      (a) => SandboxAppListTile(
                        app: a,
                        onStop: () =>
                            context.read<SandboxBloc>().add(StopSandbox(a.id)),
                        onAnalyze: () => context.read<SandboxBloc>().add(
                          StartAnalysis(a.id),
                        ),
                        onReport: () => context.read<SandboxBloc>().add(
                          GenerateReport(a.id),
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _recentThreats(ThemeColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              '近期威胁',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colors.textSecondary,
              ),
            ),
          ),
          BlocBuilder<ReportBloc, ReportState>(
            builder: (_, state) {
              final threats = state.reports
                  .where((r) => r.threatScore > 20)
                  .take(3)
                  .toList();
              if (threats.isEmpty)
                return _emptyHint(
                  Icons.verified_outlined,
                  '系统安全，未发现威胁',
                  null,
                  null,
                  colors,
                );
              return Column(
                children: threats.map((r) => _threatCard(r, colors)).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _emptyHint(
    IconData icon,
    String text,
    String? actionLabel,
    VoidCallback? onAction,
    ThemeColors colors,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.cardBorder, width: 0.5),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: colors.textMuted.withValues(alpha: 0.4)),
          const SizedBox(height: 10),
          Text(
            text,
            style: TextStyle(color: colors.textSecondary, fontSize: 13),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 14),
            GestureDetector(
              onTap: onAction,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: colors.brandGradient,
                ),
                child: Text(
                  actionLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _threatCard(SecurityReport r, ThemeColors colors) {
    final color = r.threatScore > 60
        ? colors.danger
        : r.threatScore > 30
        ? colors.warning
        : colors.success;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.cardBorder, width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              r.threatScore > 30
                  ? Icons.warning_rounded
                  : Icons.check_circle_rounded,
              color: color,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              r.appName,
              style: TextStyle(color: colors.textPrimary, fontSize: 13),
            ),
          ),
          Text(
            '威胁 ${r.threatScore}',
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionTile(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: ThemeColors.of(context).card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: ThemeColors.of(context).cardBorder,
            width: 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 14),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: ThemeColors.of(context).textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bottomNav(ThemeColors colors) {
    return Container(
      decoration: BoxDecoration(
        color: colors.navBarBackground,
        border: Border(top: BorderSide(color: colors.navBarBorder, width: 0.5)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(Icons.dashboard_rounded, '仪表盘', 0, colors),
              _navItem(Icons.shield_rounded, '沙盒', 1, colors),
              _navItem(Icons.assignment_rounded, '报告', 2, colors),
              _navItem(Icons.tune_rounded, '设置', 3, colors),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, int idx, ThemeColors colors) {
    final selected = _tabIndex == idx;
    final color = selected ? colors.brandLight : colors.textMuted;
    return GestureDetector(
      onTap: () => _switchTo(idx),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _settings(ThemeColors colors) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(
              '外观设置',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            BlocBuilder<ThemeBloc, ThemeState>(
              builder: (context, themeState) {
                return Container(
                  decoration: BoxDecoration(
                    color: colors.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: colors.cardBorder, width: 0.5),
                  ),
                  child: Column(
                    children: [
                      _themeOption(
                        icon: Icons.brightness_auto_rounded,
                        title: '跟随系统',
                        subtitle: '自动切换亮色与暗色模式',
                        selected: themeState.mode == AppThemeMode.system,
                        onTap: () => context.read<ThemeBloc>().add(
                          const SetThemeMode(AppThemeMode.system),
                        ),
                        colors: colors,
                      ),
                      Divider(height: 1, indent: 52, color: colors.divider),
                      _themeOption(
                        icon: Icons.light_mode_rounded,
                        title: '浅色模式',
                        subtitle: '始终使用浅色主题',
                        selected: themeState.mode == AppThemeMode.light,
                        onTap: () => context.read<ThemeBloc>().add(
                          const SetThemeMode(AppThemeMode.light),
                        ),
                        colors: colors,
                      ),
                      Divider(height: 1, indent: 52, color: colors.divider),
                      _themeOption(
                        icon: Icons.dark_mode_rounded,
                        title: '深色模式',
                        subtitle: '始终使用深色主题',
                        selected: themeState.mode == AppThemeMode.dark,
                        onTap: () => context.read<ThemeBloc>().add(
                          const SetThemeMode(AppThemeMode.dark),
                        ),
                        colors: colors,
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 28),
            Text(
              '关于',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colors.cardBorder, width: 0.5),
              ),
              child: Column(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: colors.brandGradient,
                    ),
                    child: const Icon(
                      Icons.shield_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'HyperGuard 澎湃盾',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Version 1.0.0',
                    style: TextStyle(fontSize: 13, color: colors.textSecondary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'HyperOS Security Sandbox System',
                    style: TextStyle(fontSize: 12, color: colors.textMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _themeOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool selected,
    required VoidCallback onTap,
    required ThemeColors colors,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Row(
          children: [
            Icon(
              icon,
              color: selected ? colors.brandLight : colors.textMuted,
              size: 22,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: selected ? colors.brandLight : colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: colors.textSecondary),
                  ),
                ],
              ),
            ),
            if (selected)
              Icon(
                Icons.check_circle_rounded,
                color: colors.brandLight,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  void _switchTo(int idx) => setState(() => _tabIndex = idx);
}
