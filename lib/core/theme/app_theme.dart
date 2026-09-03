import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'theme_controller.dart';

abstract final class AppTheme {
  static const String fontFamily = 'NotoKufiArabic';

  /// نووسینی کوردی/عەرەبی بەرزی دێڕی زیاتری دەوێت لە لاتینی.
  static const double _bodyHeight = 1.75;
  static const double _headingHeight = 1.45;

  static ThemeData dark() => _build(
        brightness: Brightness.dark,
        colors: AppColors.dark,
        overlay: AppThemeOverlay.dark,
      );

  static ThemeData light() => _build(
        brightness: Brightness.light,
        colors: AppColors.light,
        overlay: AppThemeOverlay.light,
      );

  /// بۆ گونجاویی کۆدی کۆن — هەمان دارک.
  static ThemeData build() => dark();

  static ThemeData _build({
    required Brightness brightness,
    required AppColors colors,
    required SystemUiOverlayStyle overlay,
  }) {
    final isDark = brightness == Brightness.dark;
    final colorScheme = (isDark ? ColorScheme.dark : ColorScheme.light)(
      primary: AppColors.purple,
      onPrimary: const Color(0xFFF5F5F7),
      primaryContainer: AppColors.purpleDark,
      secondary: AppColors.purpleLight,
      onSecondary: const Color(0xFFF5F5F7),
      surface: colors.surface,
      onSurface: colors.ink,
      error: AppColors.danger,
      onError: const Color(0xFFF5F5F7),
      outline: colors.stroke,
    );

    final textTheme = _textTheme(colors.ink, colors.textMuted);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colors.background,
      canvasColor: colors.background,
      fontFamily: fontFamily,
      textTheme: textTheme,
      extensions: [colors],
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: overlay,
        iconTheme: IconThemeData(color: colors.ink),
      ),
      dividerTheme: DividerThemeData(
        color: colors.stroke,
        thickness: 1,
        space: 1,
      ),
      iconTheme: IconThemeData(color: colors.ink, size: 22),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colors.surfaceHigh,
        contentTextStyle: textTheme.bodyMedium,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.purpleLight,
        selectionColor: Color(0x407B2CF5),
        selectionHandleColor: AppColors.purpleLight,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }

  static TextTheme _textTheme(Color ink, Color muted) {
    final base = TextStyle(color: ink, fontFamily: fontFamily);
    return TextTheme(
      displaySmall: base.copyWith(
        fontSize: 30,
        fontWeight: FontWeight.w700,
        height: _headingHeight,
        letterSpacing: -0.2,
      ),
      headlineMedium: base.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        height: _headingHeight,
      ),
      headlineSmall: base.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        height: _headingHeight,
      ),
      titleLarge: base.copyWith(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        height: _headingHeight,
      ),
      titleMedium: base.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        height: _headingHeight,
      ),
      bodyLarge: base.copyWith(fontSize: 15, height: _bodyHeight),
      bodyMedium: base.copyWith(fontSize: 13.5, height: _bodyHeight),
      bodySmall: base.copyWith(
        fontSize: 12,
        height: _bodyHeight,
        color: muted,
      ),
      labelLarge: base.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        height: 1.2,
        color: const Color(0xFFF5F5F7),
      ),
      labelMedium: base.copyWith(
        fontSize: 12.5,
        fontWeight: FontWeight.w700,
        height: 1.2,
      ),
    );
  }
}
