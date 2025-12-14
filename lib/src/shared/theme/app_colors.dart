import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  /// Main brand blue (from app header / drawer).
  static const Color primary = Color(0xFF062A5A);
  static const Color primaryDark = Color(0xFF041B3A);

  /// Accent yellow used for actions (e.g. طلب بطاقة).
  static const Color accent = Color(0xFFFFD230);

  /// Semantic colors.
  static const Color info = primary;
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFE9B949);
  static const Color error = Color(0xFFDC2626);

  /// Neutrals & surfaces.
  static const Color surface = Color(0xFFF7F9FC); // light warm background
  static const Color surfaceAlt = Colors.white; // cards / sheets
  static const Color neutralWarm = Color(0xFFF2E5C8); // used in some cards
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color border = Color(0xFFE5E7EB);

  /// Primary gradient blending brand blue + accent.
  static const LinearGradient brandGradient = LinearGradient(
    colors: [primary, Color.fromARGB(255, 0, 131, 218)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static AppThemeColors get light => const AppThemeColors(
    scaffold: surface,
    text: textPrimary,
    text70: textSecondary,
    accent: accent,
    error: error,
  );

  static AppThemeColors get dark => const AppThemeColors(
    scaffold: Color(0xFF0F172A),
    text: Colors.white,
    text70: Colors.white70,
    accent: Color(0xFF64B5F6),
    error: Color(0xFFFF8A80),
  );
}

class AppThemeColors {
  const AppThemeColors({
    required this.scaffold,
    required this.text,
    required this.text70,
    required this.accent,
    required this.error,
  });

  final Color scaffold;
  final Color text;
  final Color text70;
  final Color accent;
  final Color error;
}
