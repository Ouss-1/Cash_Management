import 'package:flutter/material.dart';

class AppTypography {
  static TextStyle poppins({
    TextStyle? textStyle,
    Color? color,
    Color? backgroundColor,
    double? fontSize,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    double? letterSpacing,
    double? wordSpacing,
    TextBaseline? textBaseline,
    double? height,
    Locale? locale,
    Paint? foreground,
    Paint? background,
    List<Shadow>? shadows,
    List<FontFeature>? fontFeatures,
    TextDecoration? decoration,
    Color? decorationColor,
    TextDecorationStyle? decorationStyle,
    double? decorationThickness,
  }) {
    return TextStyle(
      color: color,
      backgroundColor: backgroundColor,
      fontSize: fontSize,
      fontWeight: fontWeight,
      fontStyle: fontStyle,
      letterSpacing: letterSpacing,
      wordSpacing: wordSpacing,
      textBaseline: textBaseline,
      height: height,
      locale: locale,
      foreground: foreground,
      background: background,
      shadows: shadows,
      fontFeatures: fontFeatures,
      decoration: decoration,
      decorationColor: decorationColor,
      decorationStyle: decorationStyle,
      decorationThickness: decorationThickness,
      fontFamily: 'sans-serif',
    ).merge(textStyle);
  }

  static TextTheme poppinsTextTheme([TextTheme? base]) {
    final theme = base ?? const TextTheme();
    return theme.copyWith(
      displayLarge: theme.displayLarge?.copyWith(fontFamily: 'sans-serif'),
      displayMedium: theme.displayMedium?.copyWith(fontFamily: 'sans-serif'),
      displaySmall: theme.displaySmall?.copyWith(fontFamily: 'sans-serif'),
      headlineLarge: theme.headlineLarge?.copyWith(fontFamily: 'sans-serif'),
      headlineMedium: theme.headlineMedium?.copyWith(fontFamily: 'sans-serif'),
      headlineSmall: theme.headlineSmall?.copyWith(fontFamily: 'sans-serif'),
      titleLarge: theme.titleLarge?.copyWith(fontFamily: 'sans-serif'),
      titleMedium: theme.titleMedium?.copyWith(fontFamily: 'sans-serif'),
      titleSmall: theme.titleSmall?.copyWith(fontFamily: 'sans-serif'),
      bodyLarge: theme.bodyLarge?.copyWith(fontFamily: 'sans-serif'),
      bodyMedium: theme.bodyMedium?.copyWith(fontFamily: 'sans-serif'),
      bodySmall: theme.bodySmall?.copyWith(fontFamily: 'sans-serif'),
      labelLarge: theme.labelLarge?.copyWith(fontFamily: 'sans-serif'),
      labelMedium: theme.labelMedium?.copyWith(fontFamily: 'sans-serif'),
      labelSmall: theme.labelSmall?.copyWith(fontFamily: 'sans-serif'),
    );
  }
}
