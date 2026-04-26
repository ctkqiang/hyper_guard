import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../core/theme/theme_colors.dart';
import '../../data/models/security_report.dart';

class ReportChart extends StatelessWidget {
  final SecurityReport report;

  const ReportChart({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _threatScore(context, colors),
        const SizedBox(height: 20),
        _behaviorBars(context, colors),
      ],
    );
  }

  Widget _threatScore(BuildContext context, ThemeColors colors) {
    final score = report.threatScore.clamp(0, 100);
    return SizedBox(
      height: 180,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 150,
            height: 150,
            child: PieChart(
              PieChartData(
                sectionsSpace: 4,
                centerSpaceRadius: 55,
                sections: [
                  PieChartSectionData(
                    value: (100 - score).toDouble(),
                    color: colors.success.withValues(alpha: 0.1),
                    showTitle: false,
                  ),
                  PieChartSectionData(
                    value: score.toDouble(),
                    color: score > 60
                        ? colors.danger
                        : score > 30
                        ? colors.warning
                        : colors.success,
                    showTitle: false,
                  ),
                ],
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$score',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                  color: score > 60
                      ? colors.danger
                      : score > 30
                      ? colors.warning
                      : colors.success,
                ),
              ),
              Text(
                '威胁指数',
                style: TextStyle(fontSize: 12, color: colors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _behaviorBars(BuildContext context, ThemeColors colors) {
    final Map<String, int> counts = {};
    for (final e in report.behaviorEvents) {
      counts[e.eventType] = (counts[e.eventType] ?? 0) + 1;
    }
    final entries = counts.entries.toList();
    if (entries.isEmpty) {
      return Center(
        child: Text('无异常行为', style: TextStyle(color: colors.textSecondary)),
      );
    }
    final maxCount = entries.map((e) => e.value).reduce(max).toDouble();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '行为分析',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: entries.length * 44.0,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxCount * 1.2,
              barGroups: entries.asMap().entries.map((entry) {
                final idx = entry.key;
                final item = entry.value;
                return BarChartGroupData(
                  x: idx,
                  barRods: [
                    BarChartRodData(
                      toY: item.value.toDouble(),
                      color: _barColor(item.key, colors),
                      width: 16,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(4),
                        topRight: Radius.circular(4),
                      ),
                    ),
                  ],
                );
              }).toList(),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      if (value.toInt() >= entries.length)
                        return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          _behaviorLabel(entries[value.toInt()].key),
                          style: TextStyle(
                            fontSize: 10,
                            color: colors.textSecondary,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              borderData: FlBorderData(show: false),
              gridData: const FlGridData(show: false),
            ),
          ),
        ),
      ],
    );
  }

  Color _barColor(String type, ThemeColors colors) => switch (type) {
    'privacy_access' || 'sms_access' || 'contact_access' => colors.danger,
    'network_request' || 'location_access' => colors.warning,
    _ => colors.brandLight,
  };

  String _behaviorLabel(String type) => switch (type) {
    'privacy_access' => '隐私',
    'network_request' => '网络',
    'file_access' => '文件',
    'sms_access' => '短信',
    'contact_access' => '通讯录',
    'location_access' => '定位',
    _ => type,
  };
}
