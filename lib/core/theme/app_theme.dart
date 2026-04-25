import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  static const Color primaryNeon = Color(0xFF00D4FF);
  static const Color primaryDark = Color(0xFF0078D4);
  static const Color accentDanger = Color(0xFFFF3366);
  static const Color accentSuccess = Color(0xFF00FF88);
  static const Color accentWarning = Color(0xFFFFB800);
  static const Color bgDeep = Color(0xFF0A0E1A);
  static const Color bgSurface = Color(0xFF141929);
  static const Color bgCard = Color(0xFF1A2035);
  static const Color textPrimary = Color(0xFFE8ECF4);
  static const Color textSecondary = Color(0xFF8E97B0);
  static const Color borderGlow = Color(0xFF2A3350);
  static const Color shieldGold = Color(0xFFD4AF37);

  static const Gradient primaryGradient = LinearGradient(
    colors: [primaryNeon, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient dangerGradient = LinearGradient(
    colors: [accentDanger, Color(0xFFCC0044)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static ThemeData get darkTheme {
    final textTheme = GoogleFonts.orbitronTextTheme(ThemeData.dark().textTheme);

    final bodyText = GoogleFonts.interTextTheme();

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgDeep,
      colorScheme: const ColorScheme.dark(
        primary: primaryNeon,
        secondary: primaryDark,
        surface: bgSurface,
        error: accentDanger,
        onPrimary: Colors.black,
        onSecondary: Colors.white,
        onSurface: textPrimary,
        onError: Colors.white,
      ),
      textTheme: textTheme.copyWith(
        bodyLarge: bodyText.bodyLarge?.copyWith(color: textPrimary),
        bodyMedium: bodyText.bodyMedium?.copyWith(color: textSecondary),
        bodySmall: bodyText.bodySmall?.copyWith(color: textSecondary),
        labelLarge: bodyText.labelLarge?.copyWith(color: textPrimary),
        labelMedium: bodyText.labelMedium?.copyWith(color: textSecondary),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bgSurface.withValues(alpha: 0.8),
        elevation: 0,
        centerTitle: true,
        titleTextStyle: textTheme.titleLarge?.copyWith(color: primaryNeon),
        iconTheme: const IconThemeData(color: primaryNeon),
      ),
      cardTheme: CardThemeData(
        color: bgCard,
        elevation: 4,
        shadowColor: primaryNeon.withValues(alpha: 0.15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: borderGlow.withValues(alpha: 0.5), width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryNeon,
          foregroundColor: Colors.black,
          elevation: 4,
          shadowColor: primaryNeon.withValues(alpha: 0.4),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.orbitron(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryNeon,
          side: const BorderSide(color: primaryNeon, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: bgSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderGlow),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderGlow),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryNeon, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: accentDanger),
        ),
        labelStyle: const TextStyle(color: textSecondary),
        hintStyle: const TextStyle(color: textSecondary),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: borderGlow, width: 1),
        ),
        titleTextStyle: textTheme.titleMedium?.copyWith(color: primaryNeon),
      ),
    );
  }
}
