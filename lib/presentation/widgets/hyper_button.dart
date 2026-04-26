import 'package:flutter/material.dart';
import '../../core/theme/theme_colors.dart';

enum HyperButtonVariant { primary, danger, outline, ghost }

class HyperButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final HyperButtonVariant variant;
  final IconData? icon;
  final bool isLoading;
  final bool fullWidth;

  const HyperButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = HyperButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.fullWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);
    return SizedBox(
      width: fullWidth ? double.infinity : null,
      height: 48,
      child: switch (variant) {
        HyperButtonVariant.primary => _gradientButton(
          colors.brandGradient,
          Colors.white,
          colors,
        ),
        HyperButtonVariant.danger => _gradientButton(
          colors.warningGradient,
          Colors.white,
          colors,
        ),
        HyperButtonVariant.outline => OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: colors.brandLight,
            side: BorderSide(color: colors.cardBorder, width: 1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _child(colors.brandLight),
        ),
        HyperButtonVariant.ghost => TextButton(
          onPressed: isLoading ? null : onPressed,
          child: _child(colors.brandLight),
        ),
      },
    );
  }

  Widget _gradientButton(Gradient gradient, Color fg, ThemeColors colors) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: gradient,
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          disabledBackgroundColor: colors.buttonDisabledBg,
          disabledForegroundColor: colors.buttonDisabledFg,
        ),
        child: _child(fg),
      ),
    );
  }

  Widget _child(Color color) {
    if (isLoading) {
      return SizedBox(
        height: 22,
        width: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation(color),
        ),
      );
    }
    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }
    return Text(
      label,
      style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.w600),
    );
  }
}
