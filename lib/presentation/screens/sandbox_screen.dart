import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/theme_colors.dart';
import '../widgets/hyper_app_bar.dart';
import '../widgets/hyper_button.dart';
import '../widgets/sandbox_app_tile.dart';
import '../bloc/sandbox/sandbox_bloc.dart';
import '../bloc/sandbox/sandbox_event.dart';
import '../bloc/sandbox/sandbox_state.dart';
import '../../data/models/sandbox_app.dart';
import '../../data/models/security_report.dart';

class SandboxScreen extends StatefulWidget {
  const SandboxScreen({super.key});

  @override
  State<SandboxScreen> createState() => _SandboxScreenState();
}

class _SandboxScreenState extends State<SandboxScreen> {
  SandboxApp? _selectedApp;

  @override
  Widget build(BuildContext context) {
    if (_selectedApp != null) return _emulatorView(context, _selectedApp!);
    return BlocBuilder<SandboxBloc, SandboxState>(
      builder: (context, state) {
        final colors = ThemeColors.of(context);
        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: const HyperAppBar(title: '蜜罐沙盒'),
          body: SafeArea(
            child: Column(
              children: [
                _statusBar(state, colors),
                const SizedBox(height: 12),
                Expanded(
                  child: state.status == SandboxStatus.initializing
                      ? Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              colors.brandLight,
                            ),
                          ),
                        )
                      : state.status == SandboxStatus.error &&
                            state.activeApps.isEmpty
                      ? _errorView(context, state, colors)
                      : state.activeApps.isEmpty
                      ? _emptyView(context, colors)
                      : _appList(context, state),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _statusBar(SandboxState state, ThemeColors colors) {
    final running = state.activeApps.any(
      (a) =>
          a.status == SandboxAppStatus.running ||
          a.status == SandboxAppStatus.analyzing,
    );
    final blocked = state.activeApps.fold<int>(
      0,
      (s, a) => s + a.blockedActions,
    );
    final count = state.activeApps.length;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.cardBorder, width: 0.5),
        ),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: running ? colors.brandLight : colors.textMuted,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              running ? '沙盒运行中' : '沙盒待命',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: running ? colors.brandLight : colors.textSecondary,
              ),
            ),
            const Spacer(),
            if (count > 0) ...[
              Text(
                '$count 应用',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: colors.textSecondary,
                ),
              ),
              if (blocked > 0) ...[
                const SizedBox(width: 12),
                Text(
                  '$blocked 拦截',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: colors.warning,
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _errorView(
    BuildContext context,
    SandboxState state,
    ThemeColors colors,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 48, color: colors.danger),
            const SizedBox(height: 16),
            Text(
              state.errorMessage ?? '沙盒环境异常',
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 20),
            HyperButton(
              label: '重试初始化',
              onPressed: () =>
                  context.read<SandboxBloc>().add(const InitializeSandbox()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyView(BuildContext context, ThemeColors colors) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                color: colors.warning.withValues(alpha: 0.06),
              ),
              child: Icon(
                Icons.shield_rounded,
                color: colors.warning,
                size: 36,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '蜜罐沙盒就绪',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '选择 APK 文件进行蜜罐安全分析\n所有敏感数据均为沙盒伪造数据',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 13,
                height: 1.8,
              ),
            ),
            const SizedBox(height: 28),
            HyperButton(
              label: '选择 APK 文件',
              icon: Icons.folder_open_rounded,
              onPressed: () => _pickAndInstall(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _appList(BuildContext context, SandboxState state) {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 4, bottom: 24),
      itemCount: state.activeApps.length,
      itemBuilder: (_, i) {
        final app = state.activeApps[i];
        return SandboxAppListTile(
          app: app,
          onTap: () => setState(() => _selectedApp = app),
          onStop: () => context.read<SandboxBloc>().add(StopSandbox(app.id)),
          onAnalyze: () =>
              context.read<SandboxBloc>().add(StartAnalysis(app.id)),
          onReport: () =>
              context.read<SandboxBloc>().add(GenerateReport(app.id)),
        );
      },
    );
  }

  Widget _emulatorView(BuildContext context, SandboxApp app) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: HyperAppBar(
        title: app.appName,
        onBack: () => setState(() => _selectedApp = null),
      ),
      body: BlocBuilder<SandboxBloc, SandboxState>(
        builder: (context, state) {
          final colors = ThemeColors.of(context);
          final events = state.liveBehaviorEvents
              .where((e) => e.details['appId'] == app.id)
              .toList();
          final networks = state.liveNetworkActivities
              .where((e) => e.details['appId'] == app.id)
              .toList();
          final perms = state.livePermissionAttempts
              .where((e) => e.details['appId'] == app.id)
              .toList();
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _emulatorHeader(app, colors),
                const SizedBox(height: 16),
                if (events.isNotEmpty) ...[
                  _sectionTitle(
                    '行为监控',
                    Icons.biotech_rounded,
                    colors.warning,
                    colors,
                  ),
                  const SizedBox(height: 10),
                  ...events.map((e) => _eventCard(e, colors)),
                  const SizedBox(height: 16),
                ],
                if (networks.isNotEmpty) ...[
                  _sectionTitle(
                    '网络活动',
                    Icons.wifi_tethering_rounded,
                    colors.brandLight,
                    colors,
                  ),
                  const SizedBox(height: 10),
                  ...networks.map((a) => _networkCard(a, colors)),
                  const SizedBox(height: 16),
                ],
                if (perms.isNotEmpty) ...[
                  _sectionTitle(
                    '权限请求',
                    Icons.admin_panel_settings_rounded,
                    colors.danger,
                    colors,
                  ),
                  const SizedBox(height: 10),
                  ...perms.map((p) => _permissionCard(p, colors)),
                  const SizedBox(height: 16),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: HyperButton(
                        label: '开始分析',
                        variant: HyperButtonVariant.primary,
                        onPressed: app.status != SandboxAppStatus.analyzing
                            ? () => context.read<SandboxBloc>().add(
                                StartAnalysis(app.id),
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: HyperButton(
                        label: '生成报告',
                        variant: HyperButtonVariant.outline,
                        onPressed: () => context.read<SandboxBloc>().add(
                          GenerateReport(app.id),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _emulatorHeader(SandboxApp app, ThemeColors colors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.cardBorder, width: 0.5),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: colors.brandGradient,
            ),
            child: const Icon(
              Icons.android_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            app.appName,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            app.packageName,
            style: TextStyle(fontSize: 13, color: colors.textSecondary),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _stat('${app.blockedActions} 拦截', colors.warning),
              const SizedBox(width: 12),
              _stat('${app.permissionRequests} 权限', colors.brandLight),
              const SizedBox(width: 12),
              _stat('${app.networkRequests} 网络', colors.success),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(
    String title,
    IconData icon,
    Color color,
    ThemeColors colors,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _eventCard(BehaviorEvent event, ThemeColors colors) {
    final color = event.severity == 'critical'
        ? colors.danger
        : event.severity == 'high'
        ? colors.warning
        : colors.brandLight;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.cardBorder, width: 0.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 3),
            width: 7,
            height: 7,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.description,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _fmtTime(event.timestamp),
                  style: TextStyle(fontSize: 10, color: colors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _networkCard(NetworkActivity activity, ThemeColors colors) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.cardBorder, width: 0.5),
      ),
      child: Row(
        children: [
          Icon(
            activity.encrypted ? Icons.lock_rounded : Icons.lock_open_rounded,
            size: 14,
            color: activity.encrypted ? colors.success : colors.warning,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.url,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: colors.textPrimary, fontSize: 12),
                ),
                Text(
                  '${activity.method} ${activity.statusCode}',
                  style: TextStyle(fontSize: 10, color: colors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _permissionCard(PermissionAttempt attempt, ThemeColors colors) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.cardBorder, width: 0.5),
      ),
      child: Row(
        children: [
          Icon(
            attempt.granted ? Icons.check_circle_rounded : Icons.cancel_rounded,
            size: 16,
            color: attempt.granted ? colors.success : colors.danger,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              attempt.permission,
              style: TextStyle(color: colors.textPrimary, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, Color color) {
    return Text(
      label,
      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
    );
  }

  String _fmtTime(DateTime t) {
    final diff = Duration(
      milliseconds:
          DateTime.now().millisecondsSinceEpoch - t.millisecondsSinceEpoch,
    );
    if (diff.inSeconds < 60) return '${diff.inSeconds}s';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    return '${diff.inHours}h';
  }
}

Future<void> _pickAndInstall(BuildContext context) async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['apk'],
    allowMultiple: false,
  );
  if (result == null || result.files.isEmpty) return;
  final path = result.files.single.path;
  if (path == null) return;
  if (!context.mounted) return;
  context.read<SandboxBloc>().add(InstallToSandbox(path));
}
