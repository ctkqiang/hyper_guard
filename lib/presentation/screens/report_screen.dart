import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/theme_colors.dart';
import '../widgets/hyper_card.dart';
import '../widgets/hyper_app_bar.dart';
import '../widgets/hyper_button.dart';
import '../widgets/report_chart.dart';
import '../bloc/report/report_bloc.dart';
import '../bloc/report/report_event.dart';
import '../bloc/report/report_state.dart';
import '../../data/models/security_report.dart';

class ReportScreen extends StatelessWidget {
  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReportBloc, ReportState>(
      builder: (context, state) {
        final colors = ThemeColors.of(context);
        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: const HyperAppBar(title: '安全报告'),
          body: SafeArea(
            child: state.selectedReport != null
                ? _buildDetail(context, state.selectedReport!, colors)
                : state.status == ReportStatus.loading
                ? Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        colors.brandLight,
                      ),
                    ),
                  )
                : state.reports.isEmpty
                ? _buildEmpty(colors)
                : _buildList(context, state, colors),
          ),
        );
      },
    );
  }

  Widget _buildEmpty(ThemeColors colors) {
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
                color: colors.success.withValues(alpha: 0.06),
              ),
              child: Icon(
                Icons.verified_rounded,
                color: colors.success,
                size: 36,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '暂无安全报告',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '在蜜罐沙盒中完成 APK 分析后\n安全报告将自动生成',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 13,
                height: 1.8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(
    BuildContext context,
    ReportState state,
    ThemeColors colors,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: state.reports.length,
      itemBuilder: (_, i) {
        final report = state.reports[i];
        return _ReportCard(
          report: report,
          colors: colors,
          onTap: () => context.read<ReportBloc>().add(SelectReport(report)),
          onDelete: () =>
              context.read<ReportBloc>().add(DeleteReport(report.id)),
        );
      },
    );
  }

  Widget _buildDetail(
    BuildContext context,
    SecurityReport report,
    ThemeColors colors,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              HyperButton(
                label: '返回',
                variant: HyperButtonVariant.ghost,
                icon: Icons.arrow_back_ios_new_rounded,
                fullWidth: false,
                onPressed: () =>
                    context.read<ReportBloc>().add(const ClearSelection()),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(Icons.delete_outline_rounded, color: colors.danger),
                onPressed: () =>
                    context.read<ReportBloc>().add(DeleteReport(report.id)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          HyperCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  report.appName,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  report.packageName,
                  style: TextStyle(fontSize: 12, color: colors.textSecondary),
                ),
                const SizedBox(height: 20),
                ReportChart(report: report),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (report.behaviorEvents.isNotEmpty)
            _eventsSection(report.behaviorEvents, colors),
          const SizedBox(height: 16),
          if (report.networkActivities.isNotEmpty)
            _networkSection(report.networkActivities, colors),
          const SizedBox(height: 16),
          if (report.recommendations.isNotEmpty)
            _recommendationsSection(report, colors),
        ],
      ),
    );
  }

  Widget _eventsSection(List<BehaviorEvent> events, ThemeColors colors) {
    return HyperCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: '行为事件',
            icon: Icons.warning_rounded,
            iconColor: null,
          ),
          const SizedBox(height: 12),
          ...events.take(10).map((e) => _EventTile(e, colors)),
        ],
      ),
    );
  }

  Widget _networkSection(List<NetworkActivity> activities, ThemeColors colors) {
    return HyperCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: '网络活动',
            icon: Icons.wifi_tethering_rounded,
            iconColor: null,
          ),
          const SizedBox(height: 12),
          ...activities.take(10).map((a) => _NetworkTile(a, colors)),
        ],
      ),
    );
  }

  Widget _recommendationsSection(SecurityReport report, ThemeColors colors) {
    return HyperCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: '安全建议',
            icon: Icons.lightbulb_rounded,
            iconColor: null,
          ),
          const SizedBox(height: 12),
          ...report.recommendations.map(
            (r) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '• ',
                    style: TextStyle(color: colors.warning, fontSize: 14),
                  ),
                  Expanded(
                    child: Text(
                      r,
                      style: TextStyle(
                        color: colors.textSecondary,
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
  final ThemeColors colors;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ReportCard({
    required this.report,
    required this.colors,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final color = report.threatScore > 60
        ? colors.danger
        : report.threatScore > 30
        ? colors.warning
        : colors.success;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.cardBorder, width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              report.threatScore > 30
                  ? Icons.warning_rounded
                  : Icons.check_circle_rounded,
              color: color,
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
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    report.generatedTime.toString().substring(0, 16),
                    style: TextStyle(fontSize: 11, color: colors.textMuted),
                  ),
                ],
              ),
            ),
          ),
          Text(
            '威胁 ${report.threatScore}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onDelete,
            child: Icon(Icons.close_rounded, color: colors.textMuted, size: 18),
          ),
        ],
      ),
    );
  }
}

class _EventTile extends StatelessWidget {
  final BehaviorEvent event;
  final ThemeColors colors;
  const _EventTile(this.event, this.colors);

  @override
  Widget build(BuildContext context) {
    final color = switch (event.severity) {
      'critical' => colors.danger,
      'high' => colors.warning,
      _ => colors.brandLight,
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 4),
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
                const SizedBox(height: 2),
                Text(
                  event.timestamp.toString().substring(11, 19),
                  style: TextStyle(fontSize: 10, color: colors.textMuted),
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
  final ThemeColors colors;
  const _NetworkTile(this.activity, this.colors);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
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
                  '${activity.method}  ${activity.statusCode}  ${activity.timestamp.toString().substring(11, 19)}',
                  style: TextStyle(fontSize: 10, color: colors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
