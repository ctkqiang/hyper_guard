import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/nezha_card.dart';
import '../widgets/nezha_app_bar.dart';
import '../widgets/nezha_button.dart';
import '../widgets/sandbox_app_tile.dart';
import '../bloc/sandbox/sandbox_bloc.dart';
import '../bloc/sandbox/sandbox_event.dart';
import '../bloc/sandbox/sandbox_state.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/sandbox_app.dart';

class SandboxScreen extends StatelessWidget {
  const SandboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SandboxBloc, SandboxState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: NezhaAppBar(
            title: '蜜罐沙盒',
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                onPressed: () {
                  context.read<SandboxBloc>().add(const RefreshSandboxApps());
                },
              ),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                _buildSandboxStatusBar(state),
                const SizedBox(height: 12),
                Expanded(
                  child: state.status == SandboxStatus.initializing
                      ? _buildLoadingState()
                      : state.status == SandboxStatus.error &&
                            state.activeApps.isEmpty
                      ? _buildErrorState(state)
                      : state.activeApps.isEmpty
                      ? _buildEmptyState(context)
                      : _buildSandboxList(context, state),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSandboxStatusBar(SandboxState state) {
    final isRunning = state.activeApps.any(
      (a) =>
          a.status == SandboxAppStatus.running ||
          a.status == SandboxAppStatus.analyzing,
    );
    final totalBlocked = state.activeApps.fold<int>(
      0,
      (sum, a) => sum + a.blockedActions,
    );
    final totalRequests = state.activeApps.fold<int>(
      0,
      (sum, a) => sum + a.permissionRequests + a.networkRequests,
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: isRunning
            ? AppTheme.primaryNeon.withValues(alpha: 0.08)
            : AppTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isRunning
              ? AppTheme.primaryNeon.withValues(alpha: 0.3)
              : AppTheme.borderGlow.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isRunning ? AppTheme.primaryNeon : AppTheme.textSecondary,
              boxShadow: isRunning
                  ? [
                      BoxShadow(
                        color: AppTheme.primaryNeon.withValues(alpha: 0.6),
                        blurRadius: 8,
                      ),
                    ]
                  : null,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            isRunning ? '沙盒运行中' : '沙盒待命',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isRunning ? AppTheme.primaryNeon : AppTheme.textSecondary,
            ),
          ),
          const Spacer(),
          if (totalBlocked > 0) ...[
            _StatDot(
              label: '${state.activeApps.length} 应用',
              color: AppTheme.textPrimary,
            ),
            const SizedBox(width: 14),
            _StatDot(label: '$totalBlocked 拦截', color: AppTheme.accentWarning),
            const SizedBox(width: 14),
            _StatDot(label: '$totalRequests 请求', color: AppTheme.primaryNeon),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 36,
            height: 36,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryNeon),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            '初始化沙盒环境...',
            style: GoogleFonts.orbitron(
              fontSize: 13,
              color: AppTheme.textSecondary,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(SandboxState state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 56,
              color: AppTheme.accentDanger,
            ),
            const SizedBox(height: 16),
            Text(
              state.errorMessage ?? '沙盒环境异常',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),
            NezhaButton(
              label: '重试初始化',
              onPressed: () {
                context.read<SandboxBloc>().add(const InitializeSandbox());
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.shieldGold.withValues(alpha: 0.1),
                border: Border.all(
                  color: AppTheme.shieldGold.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.shield_rounded,
                color: AppTheme.shieldGold,
                size: 40,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '蜜罐沙盒已就绪',
              style: GoogleFonts.orbitron(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              '当外部APK发起安装请求时\n选择「蜜罐安全安装」即可在此处查看\n\n诈骗APP获取的所有数据均为伪造数据',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
                height: 1.8,
              ),
            ),
            const SizedBox(height: 28),
            NezhaButton(
              label: '模拟安装请求',
              icon: Icons.add_rounded,
              onPressed: () {
                _showMockInstallDialog(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSandboxList(BuildContext context, SandboxState state) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: state.activeApps.length,
      itemBuilder: (context, index) {
        final app = state.activeApps[index];
        return SandboxAppTile(
          app: app,
          onStop: () {
            context.read<SandboxBloc>().add(StopSandbox(app.id));
          },
          onAnalyze: () {
            context.read<SandboxBloc>().add(StartAnalysis(app.id));
          },
          onGenerateReport: () {
            context.read<SandboxBloc>().add(GenerateReport(app.id));
          },
          onTap: () {
            _showSandboxDetail(context, app, state);
          },
        );
      },
    );
  }

  void _showMockInstallDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          '模拟安装请求',
          style: GoogleFonts.orbitron(
            color: AppTheme.primaryNeon,
            fontSize: 15,
          ),
        ),
        content: const Text(
          '模拟一个外部APK安装请求以测试蜜罐沙盒功能',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          NezhaButton(
            label: '模拟安装',
            variant: NezhaButtonVariant.primary,
            isFullWidth: false,
            onPressed: () {
              Navigator.pop(ctx);
              context.read<SandboxBloc>().add(
                const InstallToSandbox('/mock/path/test.apk'),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showSandboxDetail(
    BuildContext context,
    SandboxApp app,
    SandboxState state,
  ) {
    final relatedEvents = state.liveBehaviorEvents
        .where((e) => e.details['appId'] == app.id)
        .toList();
    final relatedNetwork = state.liveNetworkActivities
        .where((e) => e.details['appId'] == app.id)
        .toList();
    final relatedPermissions = state.livePermissionAttempts
        .where((e) => e.details['appId'] == app.id)
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: AppTheme.bgSurface,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.textSecondary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    app.appName,
                    style: GoogleFonts.orbitron(
                      fontSize: 16,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    app.packageName,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _DetailRow('行为事件', '${relatedEvents.length}'),
                  _DetailRow('网络请求', '${relatedNetwork.length}'),
                  _DetailRow('权限尝试', '${relatedPermissions.length}'),
                  _DetailRow('拦截操作', '${app.blockedActions}'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatDot extends StatelessWidget {
  final String label;
  final Color color;

  const _StatDot({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
