import 'package:flutter/material.dart';
import 'app_theme.dart';

class ThemeColors {
  final bool isDark;

  const ThemeColors._(this.isDark);

  factory ThemeColors.of(BuildContext context) {
    return ThemeColors._(Theme.of(context).brightness == Brightness.dark);
  }

  Color get background => isDark ? AppTheme.slate900 : AppTheme.slate50;

  Color get surface => isDark ? AppTheme.slate900 : Colors.white;

  Color get card => isDark ? AppTheme.slate850 : Colors.white;

  Color get cardBorder => isDark ? AppTheme.slate700 : AppTheme.slate200;

  Color get textPrimary => isDark ? AppTheme.slate100 : AppTheme.slate900;

  Color get textSecondary => isDark ? AppTheme.slate400 : AppTheme.slate500;

  Color get textMuted => isDark ? AppTheme.slate500 : AppTheme.slate400;

  Color get divider => isDark ? AppTheme.slate700 : AppTheme.slate200;

  Color get navBarBackground => isDark ? AppTheme.slate900 : Colors.white;

  Color get navBarBorder => isDark ? AppTheme.slate700 : AppTheme.slate200;

  Color get elevatedBackground =>
      isDark ? AppTheme.slate800 : AppTheme.slate100;

  Color get buttonDisabledBg => isDark ? AppTheme.slate800 : AppTheme.slate200;

  Color get buttonDisabledFg => isDark ? AppTheme.slate500 : AppTheme.slate400;

  Color get iconMuted => isDark ? AppTheme.slate500 : AppTheme.slate300;

  Color get brandLight => AppTheme.blue400;

  Color get brandMain => AppTheme.blue600;

  Color get brandOnDark => AppTheme.blue500;

  Color get danger => AppTheme.rose500;

  Color get warning => AppTheme.amber500;

  Color get success => AppTheme.emerald500;

  Color get successLight => AppTheme.emerald400;

  Gradient get brandGradient => AppTheme.gradientBrand;

  Gradient get successGradient => AppTheme.gradientSuccess;

  Gradient get warningGradient => AppTheme.gradientWarning;
}
