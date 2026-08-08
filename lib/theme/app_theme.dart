import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/typography.dart';

class AppTheme {
  // Primary Colors — White + Purple palette
  static const Color primaryPurple = Color(0xFF7B2CBF);
  static const Color accentPurple = Color(0xFF9D4EDD);
  static const Color deepPurple = Color(0xFF5A189A);
  static const Color lightPurple = Color(0xFFE8D5F5);
  static const Color ultraLightPurple = Color(0xFFF3EAFA);

  // Semantic Colors
  static const Color incomeGreen = Color(0xFF2ECC71);
  static const Color expenseRed = Color(0xFFE74C3C);
  static const Color warningYellow = Color(0xFFF1C40F);

  // Light theme surfaces
  static const Color lightBackground = Color(0xFFF7F5FB);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightSurface = Color(0xFFFFFFFF);

  // Dark theme surfaces (kept as fallback)
  static const Color darkBackground = Color(0xFF0D0D15);
  static const Color darkCard = Color(0xFF13131F);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [deepPurple, primaryPurple, accentPurple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient softGradient = LinearGradient(
    colors: [ultraLightPurple, lightPurple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightBackground,
      colorScheme: const ColorScheme.light(
        primary: primaryPurple,
        secondary: accentPurple,
        surface: lightCard,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Color(0xFF1A1A2E),
      ),
      textTheme: AppTypography.poppinsTextTheme(),
      cardTheme: CardThemeData(
        color: lightCard,
        elevation: 0,
        shadowColor: Colors.black.withOpacity(0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        iconTheme: const IconThemeData(color: Color(0xFF1A1A2E)),
        titleTextStyle: AppTypography.poppins(
          color: const Color(0xFF1A1A2E),
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryPurple,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ultraLightPurple,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: lightPurple.withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primaryPurple, width: 1.5),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryPurple,
        foregroundColor: Colors.white,
        elevation: 6,
      ),
      dividerTheme: DividerThemeData(
        color: lightPurple.withOpacity(0.5),
        thickness: 1,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: primaryPurple,
        secondary: accentPurple,
        surface: darkCard,
      ),
      textTheme: AppTypography.poppinsTextTheme(ThemeData.dark().textTheme),
      cardTheme: CardThemeData(
        color: darkCard,
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: AppTypography.poppins(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
