import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/sandbox_app.dart';
import 'security_status_indicator.dart';

class SandboxAppTile extends StatelessWidget {
  final SandboxApp app;
  final VoidCallback? onTap;
  final VoidCallback? onStop;
  final VoidCallback? onAnalyze;
  final VoidCallback? onGenerateReport;

  const SandboxAppTile({
    super.key,
    required this.app,
    this.onTap,
    this.onStop,
    this.onAnalyze,
    this.onGenerateReport,
  });

  String get _sizeText {
    final mb = app.sizeBytes / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB';
  }

  String get _durationText {
    final diff = DateTime.now().difference(app.createdTime);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} 分钟前';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} 小时前';
    }
    return '${diff.inDays} 天前';
  }

  IconData get _statusIcon {
    switch (app.status) {
      case SandboxAppStatus.pending:
        return Icons.hourglass_empty;
      case SandboxAppStatus.running:
        return Icons.play_circle_fill_rounded;
      case SandboxAppStatus.analyzing:
        return Icons.biotech_rounded;
      case SandboxAppStatus.completed:
        return Icons.check_circle_rounded;
      case SandboxAppStatus.failed:
        return Icons.error_rounded;
    }
  }

  Color get _statusColor {
    switch (app.status) {
      case SandboxAppStatus.pending:
        return AppTheme.textSecondary;
      case SandboxAppStatus.running:
        return AppTheme.primaryNeon;
      case SandboxAppStatus.analyzing:
        return AppTheme.accentWarning;
      case SandboxAppStatus.completed:
        return AppTheme.accentSuccess;
      case SandboxAppStatus.failed:
        return AppTheme.accentDanger;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.borderGlow.withValues(alpha: 0.5),
            width: 1,
          ),
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
                    color: AppTheme.primaryNeon.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.android_rounded,
                    color: AppTheme.primaryNeon,
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
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        app.packageName,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                SecurityStatusIndicator(threatLevel: app.threatLevel),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _InfoChip(
                  icon: _statusIcon,
                  label: _durationText,
                  color: _statusColor,
                ),
                const SizedBox(width: 12),
                _InfoChip(
                  icon: Icons.storage_rounded,
                  label: _sizeText,
                  color: AppTheme.textSecondary,
                ),
                const SizedBox(width: 12),
                _InfoChip(
                  icon: Icons.warning_rounded,
                  label: '${app.blockedActions} 拦截',
                  color: AppTheme.accentWarning,
                ),
              ],
            ),
            if (app.status == SandboxAppStatus.running ||
                app.status == SandboxAppStatus.analyzing) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.stop_rounded,
                      label: '停止',
                      color: AppTheme.accentDanger,
                      onTap: onStop,
                    ),
                  ),
                  if (app.status != SandboxAppStatus.analyzing) ...[
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.biotech_rounded,
                        label: '分析',
                        color: AppTheme.accentWarning,
                        onTap: onAnalyze,
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
                child: _ActionButton(
                  icon: Icons.description_rounded,
                  label: '生成报告',
                  color: AppTheme.primaryNeon,
                  onTap: onGenerateReport,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

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

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
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
