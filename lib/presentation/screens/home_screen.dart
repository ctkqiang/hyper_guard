import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/security_status_indicator.dart';
import '../bloc/sandbox/sandbox_bloc.dart';
import '../bloc/sandbox/sandbox_event.dart';
import '../bloc/sandbox/sandbox_state.dart';
import '../bloc/report/report_bloc.dart';
import '../bloc/report/report_event.dart';
import '../bloc/report/report_state.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/sandbox_app.dart';
import '../../data/models/security_report.dart';
import 'sandbox_screen.dart';
import 'report_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    context.read<SandboxBloc>().add(const InitializeSandbox());
    context.read<ReportBloc>().add(const LoadReportHistory());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: false,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(0),
        child: Container(),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildDashboardTab(),
          const SandboxScreen(),
          const ReportScreen(),
          _buildSettingsTab(),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildDashboardTab() {
    return SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 8),
            _buildSecurityStatusCard(),
            const SizedBox(height: 16),
            _buildQuickActions(),
            const SizedBox(height: 16),
            _buildActiveSandboxes(),
            const SizedBox(height: 16),
            _buildRecentThreats(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryNeon.withValues(alpha: 0.05),
            Colors.transparent,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppTheme.primaryGradient,
            ),
            child: const Icon(
              Icons.shield_rounded,
              color: Colors.black,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppConstants.appNameCN,
                style: GoogleFonts.orbitron(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                  color: AppTheme.primaryNeon,
                ),
              ),
              Text(
                'HyperOS Security Sandbox',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.accentSuccess.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.accentSuccess.withValues(alpha: 0.3),
              ),
            ),
            child: const Icon(
              Icons.verified_user_rounded,
              color: AppTheme.accentSuccess,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityStatusCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [
              AppTheme.primaryNeon.withValues(alpha: 0.08),
              AppTheme.primaryDark.withValues(alpha: 0.04),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: AppTheme.borderGlow.withValues(alpha: 0.6),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppTheme.primaryGradient,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryNeon.withValues(alpha: 0.4),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.security_rounded,
                color: Colors.black,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '澎湃防护已激活',
                    style: GoogleFonts.orbitron(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryNeon,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '系统安装拦截 · 蜜罐沙盒 · 行为审计',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('快捷操作'),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.bug_report_rounded,
                  title: '扫描APK',
                  subtitle: '安全检测',
                  color: AppTheme.primaryNeon,
                  onTap: () {},
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.shield_rounded,
                  title: '蜜罐安装',
                  subtitle: '沙盒运行',
                  color: AppTheme.shieldGold,
                  onTap: () => _navigateTo(1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.analytics_rounded,
                  title: '安全报告',
                  subtitle: '行为审计',
                  color: AppTheme.accentSuccess,
                  onTap: () => _navigateTo(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.settings_rounded,
                  title: '防护设置',
                  subtitle: '策略配置',
                  color: AppTheme.accentWarning,
                  onTap: () => _navigateTo(3),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActiveSandboxes() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('活跃沙盒'),
          const SizedBox(height: 10),
          BlocBuilder<SandboxBloc, SandboxState>(
            builder: (context, state) {
              if (state.activeApps.isEmpty) {
                return _emptyStateCard(
                  icon: Icons.inbox_rounded,
                  title: '暂无活跃沙盒',
                  subtitle: '选择APK进行蜜罐安全安装',
                  actionLabel: '开始安装',
                  onAction: () => _navigateTo(1),
                );
              }
              return Column(
                children: state.activeApps
                    .map((app) => _MiniSandboxCard(app: app))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRecentThreats() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('近期威胁'),
          const SizedBox(height: 10),
          BlocBuilder<ReportBloc, ReportState>(
            builder: (context, state) {
              final threats = state.reports
                  .where((r) => r.threatScore > 20)
                  .take(3)
                  .toList();
              if (threats.isEmpty) {
                return _emptyStateCard(
                  icon: Icons.verified_outlined,
                  title: '未发现近期威胁',
                  subtitle: '您的设备安全，无需担心',
                );
              }
              return Column(
                children: threats
                    .map((r) => _ThreatMiniCard(report: r))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.orbitron(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: AppTheme.textPrimary,
      ),
    );
  }

  void _navigateTo(int index) {
    setState(() => _currentIndex = index);
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.bgSurface,
        border: Border(
          top: BorderSide(
            color: AppTheme.borderGlow.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.dashboard_rounded,
                label: '仪表盘',
                isSelected: _currentIndex == 0,
                onTap: () => _navigateTo(0),
              ),
              _NavItem(
                icon: Icons.shield_rounded,
                label: '沙盒',
                isSelected: _currentIndex == 1,
                onTap: () => _navigateTo(1),
              ),
              _NavItem(
                icon: Icons.assignment_rounded,
                label: '报告',
                isSelected: _currentIndex == 2,
                onTap: () => _navigateTo(2),
              ),
              _NavItem(
                icon: Icons.settings_rounded,
                label: '设置',
                isSelected: _currentIndex == 3,
                onTap: () => _navigateTo(3),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsTab() {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.build_rounded,
                size: 48,
                color: AppTheme.textSecondary,
              ),
              const SizedBox(height: 16),
              const Text(
                '防护设置',
                style: TextStyle(color: AppTheme.textPrimary, fontSize: 18),
              ),
              const SizedBox(height: 8),
              const Text(
                '策略配置模块将在后续版本开放',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyStateCard({
    required IconData icon,
    required String title,
    required String subtitle,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderGlow.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 36,
            color: AppTheme.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 14),
            GestureDetector(
              onTap: onAction,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryNeon.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppTheme.primaryNeon.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  actionLabel,
                  style: const TextStyle(
                    color: AppTheme.primaryNeon,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? AppTheme.primaryNeon : AppTheme.textSecondary;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniSandboxCard extends StatelessWidget {
  final SandboxApp app;
  const _MiniSandboxCard({required this.app});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderGlow.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.android_rounded,
            color: AppTheme.primaryNeon,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              app.appName,
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
            ),
          ),
          SecurityStatusIndicator(threatLevel: app.threatLevel, size: 14),
        ],
      ),
    );
  }
}

class _ThreatMiniCard extends StatelessWidget {
  final SecurityReport report;
  const _ThreatMiniCard({required this.report});

  @override
  Widget build(BuildContext context) {
    final color = report.threatScore > 60
        ? AppTheme.accentDanger
        : report.threatScore > 30
        ? AppTheme.accentWarning
        : AppTheme.accentSuccess;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              report.threatScore > 30
                  ? Icons.warning_rounded
                  : Icons.check_circle_rounded,
              color: color,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              report.appName,
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
            ),
          ),
          Text(
            '威胁 ${report.threatScore}',
            style: TextStyle(color: color, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
