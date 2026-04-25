import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/security_report.dart';

class ReportChart extends StatelessWidget {
  final SecurityReport report;

  const ReportChart({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildThreatScore(context),
        const SizedBox(height: 20),
        _buildBehaviorAnalysis(context),
      ],
    );
  }

  Widget _buildThreatScore(BuildContext context) {
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
                    color: AppTheme.accentSuccess.withValues(alpha: 0.3),
                    showTitle: false,
                  ),
                  PieChartSectionData(
                    value: score.toDouble(),
                    color: score > 60
                        ? AppTheme.accentDanger
                        : score > 30
                        ? AppTheme.accentWarning
                        : AppTheme.accentSuccess,
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
                      ? AppTheme.accentDanger
                      : score > 30
                      ? AppTheme.accentWarning
                      : AppTheme.accentSuccess,
                ),
              ),
              const Text(
                '威胁指数',
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBehaviorAnalysis(BuildContext context) {
    final Map<String, int> behaviorCount = {};
    for (final event in report.behaviorEvents) {
      behaviorCount[event.eventType] =
          (behaviorCount[event.eventType] ?? 0) + 1;
    }

    final entries = behaviorCount.entries.toList();
    if (entries.isEmpty) {
      return const Center(
        child: Text('无异常行为记录', style: TextStyle(color: AppTheme.textSecondary)),
      );
    }

    final maxCount = entries.map((e) => e.value).reduce(max).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '行为分析',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
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
                      color: _barColor(item.key),
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
                      if (value.toInt() >= entries.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          _behaviorLabel(entries[value.toInt()].key),
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppTheme.textSecondary,
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

  Color _barColor(String eventType) {
    switch (eventType) {
      case 'privacy_access':
        return AppTheme.accentDanger;
      case 'network_request':
        return AppTheme.accentWarning;
      case 'file_access':
        return AppTheme.primaryNeon;
      case 'sms_access':
        return AppTheme.accentDanger;
      case 'contact_access':
        return AppTheme.accentDanger;
      case 'location_access':
        return AppTheme.accentWarning;
      default:
        return AppTheme.primaryNeon;
    }
  }

  String _behaviorLabel(String eventType) {
    switch (eventType) {
      case 'privacy_access':
        return '隐私';
      case 'network_request':
        return '网络';
      case 'file_access':
        return '文件';
      case 'sms_access':
        return '短信';
      case 'contact_access':
        return '通讯录';
      case 'location_access':
        return '定位';
      default:
        return eventType;
    }
  }
}
