import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/nezha_card.dart';
import '../widgets/nezha_app_bar.dart';
import '../widgets/nezha_button.dart';
import '../widgets/report_chart.dart';
import '../bloc/report/report_bloc.dart';
import '../bloc/report/report_event.dart';
import '../bloc/report/report_state.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/security_report.dart';

class ReportScreen extends StatelessWidget {
  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReportBloc, ReportState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: NezhaAppBar(
            title: '安全报告',
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                onPressed: () {
                  context.read<ReportBloc>().add(const LoadReportHistory());
                },
              ),
            ],
          ),
          body: SafeArea(
            child: state.selectedReport != null
                ? _buildReportDetail(context, state.selectedReport!)
                : state.status == ReportStatus.loading
                ? _buildLoadingState()
                : state.reports.isEmpty
                ? _buildEmptyState()
                : _buildReportList(context, state),
          ),
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryNeon),
      ),
    );
  }

  Widget _buildEmptyState() {
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
                color: AppTheme.accentSuccess.withValues(alpha: 0.1),
                border: Border.all(
                  color: AppTheme.accentSuccess.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.verified_rounded,
                color: AppTheme.accentSuccess,
                size: 40,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '暂无安全报告',
              style: GoogleFonts.orbitron(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              '在蜜罐沙盒中完成APK分析后\n安全报告将显示在此处',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
                height: 1.8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportList(BuildContext context, ReportState state) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: state.reports.length,
      itemBuilder: (context, index) {
        final report = state.reports[index];
        return _ReportCard(
          report: report,
          onTap: () {
            context.read<ReportBloc>().add(SelectReport(report));
          },
          onDelete: () {
            context.read<ReportBloc>().add(DeleteReport(report.id));
          },
        );
      },
    );
  }

  Widget _buildReportDetail(BuildContext context, SecurityReport report) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              NezhaButton(
                label: '返回列表',
                variant: NezhaButtonVariant.ghost,
                icon: Icons.arrow_back_ios_new_rounded,
                isFullWidth: false,
                onPressed: () {
                  context.read<ReportBloc>().add(const ClearSelection());
                },
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: AppTheme.accentDanger,
                ),
                onPressed: () {
                  context.read<ReportBloc>().add(DeleteReport(report.id));
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          NezhaCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  report.appName,
                  style: GoogleFonts.orbitron(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  report.packageName,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 20),
                ReportChart(report: report),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildBehaviorEvents(report),
          const SizedBox(height: 16),
          _buildNetworkActivity(report),
          const SizedBox(height: 16),
          if (report.recommendations.isNotEmpty) _buildRecommendations(report),
        ],
      ),
    );
  }

  Widget _buildBehaviorEvents(SecurityReport report) {
    if (report.behaviorEvents.isEmpty) return const SizedBox.shrink();

    return NezhaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const NezhaCardHeader(
            title: '行为事件',
            icon: Icons.warning_rounded,
            iconColor: AppTheme.accentWarning,
          ),
          const SizedBox(height: 12),
          ...report.behaviorEvents
              .take(10)
              .map(
                (event) => _EventTile(
                  severity: event.severity,
                  description: event.description,
                  timestamp: event.timestamp,
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildNetworkActivity(SecurityReport report) {
    if (report.networkActivities.isEmpty) return const SizedBox.shrink();

    return NezhaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const NezhaCardHeader(
            title: '网络活动',
            icon: Icons.wifi_tethering_rounded,
            iconColor: AppTheme.primaryNeon,
          ),
          const SizedBox(height: 12),
          ...report.networkActivities
              .take(10)
              .map((activity) => _NetworkTile(activity: activity)),
        ],
      ),
    );
  }

  Widget _buildRecommendations(SecurityReport report) {
    return NezhaCard(
      borderColor: AppTheme.accentDanger.withValues(alpha: 0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const NezhaCardHeader(
            title: '安全建议',
            icon: Icons.lightbulb_rounded,
            iconColor: AppTheme.accentWarning,
          ),
          const SizedBox(height: 12),
          ...report.recommendations.map(
            (rec) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '• ',
                    style: TextStyle(
                      color: AppTheme.accentWarning,
                      fontSize: 14,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      rec,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final SecurityReport report;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ReportCard({
    required this.report,
    required this.onTap,
    required this.onDelete,
  });

  Color get _color {
    return report.threatScore > 60
        ? AppTheme.accentDanger
        : report.threatScore > 30
        ? AppTheme.accentWarning
        : AppTheme.accentSuccess;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderGlow.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              report.threatScore > 30
                  ? Icons.warning_rounded
                  : Icons.check_circle_rounded,
              color: _color,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: GestureDetector(
              onTap: onTap,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    report.appName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    report.generatedTime.toString().substring(0, 16),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Text(
            '威胁 ${report.threatScore}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _color,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onDelete,
            child: const Icon(
              Icons.close_rounded,
              color: AppTheme.textSecondary,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }
}

class _EventTile extends StatelessWidget {
  final String severity;
  final String description;
  final DateTime timestamp;

  const _EventTile({
    required this.severity,
    required this.description,
    required this.timestamp,
  });

  Color get _severityColor {
    switch (severity) {
      case 'critical':
        return AppTheme.accentDanger;
      case 'high':
        return AppTheme.accentWarning;
      default:
        return AppTheme.primaryNeon;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 3),
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _severityColor,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  timestamp.toString().substring(11, 19),
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NetworkTile extends StatelessWidget {
  final NetworkActivity activity;
  const _NetworkTile({required this.activity});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(
            activity.encrypted ? Icons.lock_rounded : Icons.lock_open_rounded,
            size: 14,
            color: activity.encrypted
                ? AppTheme.accentSuccess
                : AppTheme.accentWarning,
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
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 12,
                  ),
                ),
                Text(
                  '${activity.method}  ${activity.statusCode}  ${activity.timestamp.toString().substring(11, 19)}',
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
