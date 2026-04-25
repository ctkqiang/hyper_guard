import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/sandbox_app.dart';

class SecurityStatusIndicator extends StatelessWidget {
  final ThreatLevel threatLevel;
  final double size;

  const SecurityStatusIndicator({
    super.key,
    required this.threatLevel,
    this.size = 16,
  });

  Color get _color {
    switch (threatLevel) {
      case ThreatLevel.safe:
        return AppTheme.accentSuccess;
      case ThreatLevel.suspicious:
        return AppTheme.accentWarning;
      case ThreatLevel.dangerous:
        return AppTheme.accentDanger;
      case ThreatLevel.malicious:
        return AppTheme.accentDanger;
    }
  }

  IconData get _icon {
    switch (threatLevel) {
      case ThreatLevel.safe:
        return Icons.shield_rounded;
      case ThreatLevel.suspicious:
        return Icons.warning_amber_rounded;
      case ThreatLevel.dangerous:
        return Icons.gpp_bad_rounded;
      case ThreatLevel.malicious:
        return Icons.bug_report_rounded;
    }
  }

  String get _label {
    switch (threatLevel) {
      case ThreatLevel.safe:
        return '安全';
      case ThreatLevel.suspicious:
        return '可疑';
      case ThreatLevel.dangerous:
        return '危险';
      case ThreatLevel.malicious:
        return '恶意';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withValues(alpha: 0.4), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, size: size - 2, color: _color),
          const SizedBox(width: 5),
          Text(
            _label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: _color,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}
