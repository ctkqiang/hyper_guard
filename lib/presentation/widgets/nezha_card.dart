import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';

class NezhaCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final double? height;
  final double? width;
  final Color? borderColor;
  final Gradient? gradient;
  final bool hasGlow;
  final double elevation;

  const NezhaCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.height,
    this.width,
    this.borderColor,
    this.gradient,
    this.hasGlow = true,
    this.elevation = 4,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        width: width,
        margin:
            margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          gradient: gradient,
          color: gradient == null ? AppTheme.bgCard : null,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: borderColor ?? AppTheme.borderGlow.withValues(alpha: 0.5),
            width: 1,
          ),
          boxShadow: hasGlow
              ? [
                  BoxShadow(
                    color: AppTheme.primaryNeon.withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(20),
            child: child,
          ),
        ),
      ),
    );
  }
}

class NezhaCardHeader extends StatelessWidget {
  final String title;
  final IconData? icon;
  final Color? iconColor;
  final Widget? trailing;

  const NezhaCardHeader({
    super.key,
    required this.title,
    this.icon,
    this.iconColor,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (icon != null) ...[
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (iconColor ?? AppTheme.primaryNeon).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: iconColor ?? AppTheme.primaryNeon,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.orbitron(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
              letterSpacing: 0.8,
            ),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}
