import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

enum NezhaButtonVariant { primary, danger, outline, ghost }

class NezhaButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final NezhaButtonVariant variant;
  final IconData? icon;
  final bool isLoading;
  final bool isFullWidth;
  final double? width;
  final double? height;

  const NezhaButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = NezhaButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = true,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: isFullWidth ? (width ?? double.infinity) : width,
      height: height ?? 52,
      child: _buildButton(context),
    );
  }

  Widget _buildButton(BuildContext context) {
    switch (variant) {
      case NezhaButtonVariant.primary:
        return _primaryButton(context);
      case NezhaButtonVariant.danger:
        return _dangerButton(context);
      case NezhaButtonVariant.outline:
        return _outlineButton(context);
      case NezhaButtonVariant.ghost:
        return _ghostButton(context);
    }
  }

  Widget _primaryButton(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryNeon.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: _buildChild(AppTheme.primaryNeon),
      ),
    );
  }

  Widget _dangerButton(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: AppTheme.dangerGradient,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accentDanger.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: _buildChild(AppTheme.accentDanger),
      ),
    );
  }

  Widget _outlineButton(BuildContext context) {
    return OutlinedButton(
      onPressed: isLoading ? null : onPressed,
      style: OutlinedButton.styleFrom(
        side: BorderSide(
          color: AppTheme.primaryNeon.withValues(alpha: 0.5),
          width: 1.5,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: _buildChild(AppTheme.primaryNeon),
    );
  }

  Widget _ghostButton(BuildContext context) {
    return TextButton(
      onPressed: isLoading ? null : onPressed,
      child: _buildChild(AppTheme.primaryNeon),
    );
  }

  Widget _buildChild(Color loadingColor) {
    if (isLoading) {
      return SizedBox(
        height: 22,
        width: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(loadingColor),
        ),
      );
    }
    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 10),
          Text(label),
        ],
      );
    }
    return Text(label);
  }
}
