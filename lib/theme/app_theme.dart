import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Sacred Saffron & Gold Theme Palette
  static const Color primarySaffron = Color(0xFFE65100);
  static const Color primaryGold = Color(0xFFD4AF37);
  static const Color lightGold = Color(0xFFFFD54F);
  static const Color deepAmber = Color(0xFFFF6F00);
  
  // Dark Theme Colors (Temple Obsidian)
  static const Color darkBackground = Color(0xFF121016);
  static const Color darkSurface = Color(0xFF1E1B26);
  static const Color darkSurfaceCard = Color(0xFF282434);
  static const Color darkBorder = Color(0xFF3B354A);
  
  // Light Theme Colors (Vedic Parchment)
  static const Color lightBackground = Color(0xFFFFFDF7);
  static const Color lightSurface = Color(0xFFFFF7E6);
  static const Color lightSurfaceCard = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFFFE0B2);
  
  // Accent & Text Colors
  static const Color textDarkPrimary = Color(0xFFF2ECFF);
  static const Color textDarkSecondary = Color(0xFFB3ABCA);
  static const Color textLightPrimary = Color(0xFF2C1D11);
  static const Color textLightSecondary = Color(0xFF755B46);
  static const Color sacredRed = Color(0xFFB71C1C);
  static const Color lotusPink = Color(0xFFEC407A);
}

class AppTheme {
  static ThemeData get darkTheme {
    final baseTextTheme = ThemeData.dark().textTheme;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryGold,
        secondary: AppColors.primarySaffron,
        surface: AppColors.darkSurface,
        onPrimary: Colors.black,
        onSecondary: Colors.white,
        onSurface: AppColors.textDarkPrimary,
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkSurfaceCard,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.darkBorder, width: 1),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkSurface,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.cinzel(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: AppColors.primaryGold,
          letterSpacing: 1.2,
        ),
        iconTheme: const IconThemeData(color: AppColors.primaryGold),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.darkSurface,
        selectedItemColor: AppColors.primaryGold,
        unselectedItemColor: AppColors.textDarkSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 12,
      ),
      textTheme: GoogleFonts.outfitTextTheme(baseTextTheme).copyWith(
        displayLarge: GoogleFonts.cinzel(color: AppColors.primaryGold, fontWeight: FontWeight.bold),
        headlineMedium: GoogleFonts.cinzel(color: AppColors.primaryGold, fontWeight: FontWeight.w600),
        titleLarge: GoogleFonts.outfit(color: AppColors.textDarkPrimary, fontWeight: FontWeight.w600),
        bodyLarge: GoogleFonts.outfit(color: AppColors.textDarkPrimary),
        bodyMedium: GoogleFonts.outfit(color: AppColors.textDarkSecondary),
      ),
    );
  }

  static ThemeData get lightTheme {
    final baseTextTheme = ThemeData.light().textTheme;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.lightBackground,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primarySaffron,
        secondary: AppColors.primaryGold,
        surface: AppColors.lightSurface,
        onPrimary: Colors.white,
        onSecondary: Colors.black,
        onSurface: AppColors.textLightPrimary,
      ),
      cardTheme: CardThemeData(
        color: AppColors.lightSurfaceCard,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.lightBorder, width: 1),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.lightSurface,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.cinzel(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: AppColors.primarySaffron,
          letterSpacing: 1.2,
        ),
        iconTheme: const IconThemeData(color: AppColors.primarySaffron),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.lightSurface,
        selectedItemColor: AppColors.primarySaffron,
        unselectedItemColor: AppColors.textLightSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      textTheme: GoogleFonts.outfitTextTheme(baseTextTheme).copyWith(
        displayLarge: GoogleFonts.cinzel(color: AppColors.primarySaffron, fontWeight: FontWeight.bold),
        headlineMedium: GoogleFonts.cinzel(color: AppColors.primarySaffron, fontWeight: FontWeight.w600),
        titleLarge: GoogleFonts.outfit(color: AppColors.textLightPrimary, fontWeight: FontWeight.w600),
        bodyLarge: GoogleFonts.outfit(color: AppColors.textLightPrimary),
        bodyMedium: GoogleFonts.outfit(color: AppColors.textLightSecondary),
      ),
    );
  }

  // Devanagari Sanskrit Font Style Helper
  static TextStyle devanagariStyle({
    required double fontSize,
    required Color color,
    FontWeight fontWeight = FontWeight.w600,
    double height = 1.6,
  }) {
    return GoogleFonts.notoSerifDevanagari(
      fontSize: fontSize,
      color: color,
      fontWeight: fontWeight,
      height: height,
    );
  }
}
