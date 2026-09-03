import 'package:flutter/material.dart';

/// پاڵێتی ڕەنگ — وەک ThemeExtension بۆ دارک و لایت.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.background,
    required this.surface,
    required this.surfaceHigh,
    required this.stroke,
    required this.ink,
    required this.textMuted,
    required this.textFaint,
    required this.glowStrength,
  });

  // ── ڕەنگی براند (هەمانە لە هەردوو دۆخ) ─────────────────────────
  static const Color purple = Color(0xFF7B2CF5);
  static const Color purpleLight = Color(0xFFB35CFF);
  static const Color purpleDark = Color(0xFF5A18D6);
  /// دوگمەی سەرەکی — مۆری قووڵ، تەخت.
  static const Color cta = Color(0xFF6D28D9);
  static const Color success = Color(0xFF31D0AA);
  static const Color danger = Color(0xFFFF4D6D);
  static const Color warning = Color(0xFFFACC15);

  static const LinearGradient purpleGradient = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [purpleLight, purple, purpleDark],
    stops: [0.0, 0.55, 1.0],
  );

  /// بۆ گونجاویی کۆدە کۆنەکان — هەمان `ink`.
  Color get white => ink;

  final Color background;
  final Color surface;
  final Color surfaceHigh;
  final Color stroke;
  final Color ink;
  final Color textMuted;
  final Color textFaint;

  /// چەند بەهێز ڕووناکی پشتەوە بێت (دارک زیاتر، لایت کەمتر).
  final double glowStrength;

  static const AppColors dark = AppColors(
    background: Color(0xFF10172A),
    surface: Color(0xFF1A2338),
    surfaceHigh: Color(0xFF222D46),
    stroke: Color(0xFF2C3752),
    ink: Color(0xFFF5F5F7),
    textMuted: Color(0xFF8B95AE),
    textFaint: Color(0xFF5C6580),
    glowStrength: 1,
  );

  static const AppColors light = AppColors(
    background: Color(0xFFF3F1FA),
    surface: Color(0xFFFFFFFF),
    surfaceHigh: Color(0xFFEAE6F6),
    stroke: Color(0xFFD9D4E8),
    ink: Color(0xFF141B2D),
    textMuted: Color(0xFF6B7389),
    textFaint: Color(0xFF9AA3B8),
    glowStrength: 0.38,
  );

  static AppColors of(BuildContext context) {
    return Theme.of(context).extension<AppColors>() ?? AppColors.dark;
  }

  @override
  AppColors copyWith({
    Color? background,
    Color? surface,
    Color? surfaceHigh,
    Color? stroke,
    Color? ink,
    Color? textMuted,
    Color? textFaint,
    double? glowStrength,
  }) {
    return AppColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceHigh: surfaceHigh ?? this.surfaceHigh,
      stroke: stroke ?? this.stroke,
      ink: ink ?? this.ink,
      textMuted: textMuted ?? this.textMuted,
      textFaint: textFaint ?? this.textFaint,
      glowStrength: glowStrength ?? this.glowStrength,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceHigh: Color.lerp(surfaceHigh, other.surfaceHigh, t)!,
      stroke: Color.lerp(stroke, other.stroke, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      textFaint: Color.lerp(textFaint, other.textFaint, t)!,
      glowStrength: glowStrength + (other.glowStrength - glowStrength) * t,
    );
  }
}
