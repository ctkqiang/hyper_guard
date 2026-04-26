import 'package:flutter/material.dart';
import '../../core/theme/theme_colors.dart';
import '../../data/models/sandbox_app.dart';

class ThreatBadge extends StatelessWidget {
  final ThreatLevel threatLevel;
  final double fontSize;

  const ThreatBadge({super.key, required this.threatLevel, this.fontSize = 11});

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);
    final color = switch (threatLevel) {
      ThreatLevel.safe => colors.success,
      ThreatLevel.suspicious => colors.warning,
      ThreatLevel.dangerous || ThreatLevel.malicious => colors.danger,
    };
    final icon = switch (threatLevel) {
      ThreatLevel.safe => Icons.shield_rounded,
      ThreatLevel.suspicious => Icons.warning_amber_rounded,
      ThreatLevel.dangerous || ThreatLevel.malicious => Icons.gpp_bad_rounded,
    };
    final label = switch (threatLevel) {
      ThreatLevel.safe => '安全',
      ThreatLevel.suspicious => '可疑',
      ThreatLevel.dangerous => '危险',
      ThreatLevel.malicious => '恶意',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: fontSize + 2, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class SandboxAppListTile extends StatelessWidget {
  final SandboxApp app;
  final VoidCallback? onTap;
  final VoidCallback? onStop;
  final VoidCallback? onAnalyze;
  final VoidCallback? onReport;

  const SandboxAppListTile({
    super.key,
    required this.app,
    this.onTap,
    this.onStop,
    this.onAnalyze,
    this.onReport,
  });

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.cardBorder, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: colors.brandLight.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.android_rounded,
                    color: colors.brandLight,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        app.appName,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        app.packageName,
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                ThreatBadge(threatLevel: app.threatLevel),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _Chip(
                  Icons.hourglass_empty,
                  _fmtDuration(app.createdTime),
                  colors.textSecondary,
                ),
                const SizedBox(width: 12),
                _Chip(
                  Icons.storage_rounded,
                  _fmtSize(app.sizeBytes),
                  colors.textSecondary,
                ),
                const SizedBox(width: 12),
                _Chip(
                  Icons.warning_rounded,
                  '${app.blockedActions} 拦截',
                  colors.warning,
                ),
              ],
            ),
            if (app.status == SandboxAppStatus.running ||
                app.status == SandboxAppStatus.analyzing) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _ActionBtn(
                      Icons.stop_rounded,
                      '停止',
                      colors.danger,
                      onStop,
                    ),
                  ),
                  if (app.status != SandboxAppStatus.analyzing) ...[
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ActionBtn(
                        Icons.biotech_rounded,
                        '深度分析',
                        colors.warning,
                        onAnalyze,
                      ),
                    ),
                  ],
                ],
              ),
            ],
            if (app.status == SandboxAppStatus.completed &&
                app.threatLevel != ThreatLevel.safe) ...[
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: _ActionBtn(
                  Icons.description_rounded,
                  '生成安全报告',
                  colors.brandLight,
                  onReport,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _fmtDuration(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 60) return '${diff.inMinutes} 分钟前';
    if (diff.inHours < 24) return '${diff.inHours} 小时前';
    return '${diff.inDays} 天前';
  }

  static String _fmtSize(int bytes) {
    final mb = bytes / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB';
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _Chip(this.icon, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 11, color: color)),
      ],
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;
  const _ActionBtn(this.icon, this.label, this.color, this.onTap);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2), width: 0.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
