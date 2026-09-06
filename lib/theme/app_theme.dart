import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// SmritiVeda Design System
/// SOURCE OF TRUTH: Stitch export — stitch_smritiveda_elderly_cognitive_wellness_app
/// DO NOT CHANGE THESE TOKENS WITHOUT UPDATING THE STITCH DESIGN FIRST.
class AppColors {
  // ── Primary: Terracotta Rust (from Stitch: #983912) ──────────────────────
  static const Color primary = Color(0xFF983912);
  static const Color primaryContainer = Color(0xFFB85028); // hover/pressed
  static const Color primaryFixed = Color(0xFFFFDBCF);
  static const Color primaryFixedDim = Color(0xFFFFB59C);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onPrimaryContainer = Color(0xFFFFF2EE);
  static const Color onPrimaryFixed = Color(0xFF380C00);
  static const Color onPrimaryFixedVariant = Color(0xFF812901);
  static const Color inversePrimary = Color(0xFFFFB59C);

  // ── Secondary: Sage Green (#396754) ─────────────────────────────────────
  static const Color secondary = Color(0xFF396754);
  static const Color secondaryContainer = Color(0xFFBBEDD5);
  static const Color secondaryFixed = Color(0xFFBBEDD5);
  static const Color secondaryFixedDim = Color(0xFFA0D1BA);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color onSecondaryContainer = Color(0xFF3F6D5A);
  static const Color onSecondaryFixed = Color(0xFF002116);
  static const Color onSecondaryFixedVariant = Color(0xFF204F3D);

  // ── Tertiary: Warm Brown (#73502c) ───────────────────────────────────────
  static const Color tertiary = Color(0xFF73502C);
  static const Color tertiaryContainer = Color(0xFF8E6842);
  static const Color tertiaryFixed = Color(0xFFFFDCBE);
  static const Color tertiaryFixedDim = Color(0xFFEDBD91);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color onTertiaryContainer = Color(0xFFFFF2E9);
  static const Color onTertiaryFixed = Color(0xFF2C1600);
  static const Color onTertiaryFixedVariant = Color(0xFF60401D);

  // ── Surfaces ─────────────────────────────────────────────────────────────
  static const Color surface = Color(0xFFF7FAF6);            // page bg
  static const Color surfaceBright = Color(0xFFF7FAF6);
  static const Color surfaceDim = Color(0xFFD8DBD7);
  static const Color surfaceContainer = Color(0xFFECEFEB);
  static const Color surfaceContainerLow = Color(0xFFF1F4F1);
  static const Color surfaceContainerHigh = Color(0xFFE6E9E5);
  static const Color surfaceContainerHighest = Color(0xFFE0E3E0);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFE0E3E0);
  static const Color surfaceTint = Color(0xFFA13F18);
  static const Color inverseSurface = Color(0xFF2D312F);
  static const Color inverseOnSurface = Color(0xFFEEF1EE);
  static const Color onSurface = Color(0xFF181C1B);
  static const Color onSurfaceVariant = Color(0xFF57423B);
  static const Color onBackground = Color(0xFF181C1B);

  // ── Named semantic surfaces (from Stitch) ────────────────────────────────
  static const Color canvasIvory = Color(0xFFFBF9F5);      // header bg
  static const Color surfaceCream = Color(0xFFF7F4EE);     // section cards
  static const Color cardWhite = Color(0xFFFFFFFF);        // elevated cards
  static const Color sageSoft = Color(0xFFEBF2EE);         // secondary hl
  static const Color terracottaSoft = Color(0xFFF7ECE7);   // warm badge
  static const Color amberGentle = Color(0xFFD97706);      // timers, alerts
  static const Color alertSoft = Color(0xFFE0533C);        // error/alert

  // ── Text ─────────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF1F2421);
  static const Color textSecondary = Color(0xFF4E5450);
  static const Color textMuted = Color(0xFF6E7571);

  // ── Borders ──────────────────────────────────────────────────────────────
  static const Color outline = Color(0xFF8A726A);
  static const Color outlineVariant = Color(0xFFDDC0B7);
  static const Color borderSubtle = Color(0xFFEAE6DF);

  // ── Status ───────────────────────────────────────────────────────────────
  static const Color error = Color(0xFFBA1A1A);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color onErrorContainer = Color(0xFF93000A);

  // ── Background ───────────────────────────────────────────────────────────
  static const Color background = Color(0xFFF7FAF6);

  // ── Legacy compatibility aliases (keep so existing screens don't break) ──
  static const Color terracottaPrimary = primary;
  static const Color sageSecondary = secondary;
  static const Color sandalwoodGold = amberGentle;
  static const Color charcoalText = textPrimary;
  static const Color primaryGold = amberGentle;
  static const Color primarySaffron = primary;
  static const Color secondaryText = textSecondary;
  static const Color lightCard = cardWhite;
  static const Color lightSurface = surface;
  static const Color lightSurfaceCard = cardWhite;
  static const Color lightBorder = outlineVariant;
  static const Color border = outlineVariant;
  static const Color borderFocused = primaryFixed;
  static const Color textLightPrimary = textPrimary;
  static const Color textLightSecondary = textSecondary;

  // Dark mode (keep existing, secondary UI)
  static const Color darkBackground = Color(0xFF0F1410);
  static const Color darkSurface = Color(0xFF1A1F1D);
  static const Color darkBorder = Color(0xFF2D352F);
  static const Color darkCard = Color(0xFF1A1F1D);
  static const Color darkSurfaceCard = Color(0xFF1A1F1D);
  static const Color textDarkPrimary = Color(0xFFF1F5F2);
  static const Color textDarkSecondary = Color(0xFFB0B8B3);
  static const Color sandalwoodAccent = secondary;
  static const Color deepAmber = amberGentle;
  static const Color surfaceSubtle = surfaceContainerLow;
  static const Color accentCoral = alertSoft;
  static const Color accentAmber = amberGentle;
  static const Color success = secondary;
  static const Color warning = amberGentle;
}

class AppTextStyles {
  // Newsreader serif — headlines only
  static TextStyle headlineLg({Color color = AppColors.textPrimary, double scale = 1.0}) =>
      GoogleFonts.newsreader(fontSize: 32 * scale, fontWeight: FontWeight.w600,
          letterSpacing: -0.005 * 32, height: 40 / 32, color: color);

  static TextStyle headlineMd({Color color = AppColors.textPrimary, double scale = 1.0}) =>
      GoogleFonts.newsreader(fontSize: 26 * scale, fontWeight: FontWeight.w600,
          height: 34 / 26, color: color);

  static TextStyle headlineSm({Color color = AppColors.textPrimary, double scale = 1.0}) =>
      GoogleFonts.newsreader(fontSize: 22 * scale, fontWeight: FontWeight.w600,
          height: 30 / 22, color: color);

  // Atkinson Hyperlegible — all body, titles, labels
  static TextStyle titleLg({Color color = AppColors.textPrimary, double scale = 1.0}) =>
      GoogleFonts.atkinsonHyperlegible(fontSize: 20 * scale, fontWeight: FontWeight.w600,
          height: 28 / 20, color: color);

  static TextStyle titleMd({Color color = AppColors.textPrimary, double scale = 1.0}) =>
      GoogleFonts.atkinsonHyperlegible(fontSize: 18 * scale, fontWeight: FontWeight.w600,
          height: 26 / 18, color: color);

  static TextStyle bodyLg({Color color = AppColors.textPrimary, double scale = 1.0}) =>
      GoogleFonts.atkinsonHyperlegible(fontSize: 18 * scale, fontWeight: FontWeight.w400,
          height: 28 / 18, color: color);

  static TextStyle bodyMd({Color color = AppColors.textPrimary, double scale = 1.0}) =>
      GoogleFonts.atkinsonHyperlegible(fontSize: 16 * scale, fontWeight: FontWeight.w400,
          height: 26 / 16, color: color);

  static TextStyle bodySm({Color color = AppColors.textPrimary, double scale = 1.0}) =>
      GoogleFonts.atkinsonHyperlegible(fontSize: 14 * scale, fontWeight: FontWeight.w500,
          height: 22 / 14, color: color);

  static TextStyle labelLg({Color color = AppColors.textPrimary, double scale = 1.0}) =>
      GoogleFonts.atkinsonHyperlegible(fontSize: 16 * scale, fontWeight: FontWeight.w600,
          letterSpacing: 0.01 * 16, height: 22 / 16, color: color);

  static TextStyle labelMd({Color color = AppColors.textPrimary, double scale = 1.0}) =>
      GoogleFonts.atkinsonHyperlegible(fontSize: 14 * scale, fontWeight: FontWeight.w600,
          letterSpacing: 0.02 * 14, height: 20 / 14, color: color);

  static TextStyle labelSm({Color color = AppColors.textPrimary, double scale = 1.0}) =>
      GoogleFonts.atkinsonHyperlegible(fontSize: 12 * scale, fontWeight: FontWeight.w700,
          letterSpacing: 0.03 * 12, height: 18 / 12, color: color);
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.surface,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        primaryContainer: AppColors.primaryContainer,
        onPrimaryContainer: AppColors.onPrimaryContainer,
        secondary: AppColors.secondary,
        onSecondary: AppColors.onSecondary,
        secondaryContainer: AppColors.secondaryContainer,
        onSecondaryContainer: AppColors.onSecondaryContainer,
        tertiary: AppColors.tertiary,
        onTertiary: AppColors.onTertiary,
        surface: AppColors.surface,
        onSurface: AppColors.onSurface,
        error: AppColors.error,
        onError: AppColors.onError,
      ),
      textTheme: TextTheme(
        // Map Flutter text roles to Stitch typography
        displayLarge: GoogleFonts.newsreader(fontSize: 32, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        displayMedium: GoogleFonts.newsreader(fontSize: 26, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        displaySmall: GoogleFonts.newsreader(fontSize: 22, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        headlineLarge: GoogleFonts.newsreader(fontSize: 32, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        headlineMedium: GoogleFonts.newsreader(fontSize: 26, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        headlineSmall: GoogleFonts.newsreader(fontSize: 22, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        titleLarge: GoogleFonts.atkinsonHyperlegible(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        titleMedium: GoogleFonts.atkinsonHyperlegible(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        titleSmall: GoogleFonts.atkinsonHyperlegible(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        bodyLarge: GoogleFonts.atkinsonHyperlegible(fontSize: 18, fontWeight: FontWeight.w400, color: AppColors.textPrimary),
        bodyMedium: GoogleFonts.atkinsonHyperlegible(fontSize: 16, fontWeight: FontWeight.w400, color: AppColors.textSecondary),
        bodySmall: GoogleFonts.atkinsonHyperlegible(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
        labelLarge: GoogleFonts.atkinsonHyperlegible(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.onPrimary),
        labelMedium: GoogleFonts.atkinsonHyperlegible(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        labelSmall: GoogleFonts.atkinsonHyperlegible(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: AppColors.textSecondary),
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardWhite,
        elevation: 1,
        shadowColor: const Color(0x142D241C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          minimumSize: const Size(double.infinity, 56), // Stitch: h-14
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: GoogleFonts.atkinsonHyperlegible(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.01 * 16),
          elevation: 2,
          shadowColor: AppColors.primary.withValues(alpha: 0.25),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          minimumSize: const Size(double.infinity, 56),
          side: const BorderSide(color: AppColors.outlineVariant, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: GoogleFonts.atkinsonHyperlegible(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceCream,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        labelStyle: GoogleFonts.atkinsonHyperlegible(color: AppColors.textSecondary),
        hintStyle: GoogleFonts.atkinsonHyperlegible(color: AppColors.textMuted),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.canvasIvory,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        shadowColor: const Color(0x0A2D241C),
        titleTextStyle: GoogleFonts.newsreader(
          fontSize: 22, fontWeight: FontWeight.w600, color: AppColors.primary,
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.canvasIvory,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: GoogleFonts.atkinsonHyperlegible(fontWeight: FontWeight.w700, fontSize: 12),
        unselectedLabelStyle: GoogleFonts.atkinsonHyperlegible(fontSize: 12),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceCream,
        selectedColor: AppColors.secondaryContainer,
        labelStyle: GoogleFonts.atkinsonHyperlegible(fontSize: 14, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: BorderSide.none,
      ),
      dividerTheme: const DividerThemeData(color: AppColors.borderSubtle, thickness: 1),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.inverseSurface,
        contentTextStyle: GoogleFonts.atkinsonHyperlegible(color: AppColors.inverseOnSurface, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryFixedDim,
        onPrimary: AppColors.onPrimaryFixed,
        secondary: AppColors.secondaryFixedDim,
        onSecondary: AppColors.onSecondaryFixed,
        surface: AppColors.darkSurface,
        onSurface: AppColors.textDarkPrimary,
        error: AppColors.error,
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.newsreader(fontSize: 32, fontWeight: FontWeight.w600, color: AppColors.textDarkPrimary),
        headlineLarge: GoogleFonts.newsreader(fontSize: 32, fontWeight: FontWeight.w600, color: AppColors.textDarkPrimary),
        headlineMedium: GoogleFonts.newsreader(fontSize: 26, fontWeight: FontWeight.w600, color: AppColors.textDarkPrimary),
        headlineSmall: GoogleFonts.newsreader(fontSize: 22, fontWeight: FontWeight.w600, color: AppColors.textDarkPrimary),
        titleLarge: GoogleFonts.atkinsonHyperlegible(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.textDarkPrimary),
        titleMedium: GoogleFonts.atkinsonHyperlegible(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textDarkPrimary),
        bodyLarge: GoogleFonts.atkinsonHyperlegible(fontSize: 18, fontWeight: FontWeight.w400, color: AppColors.textDarkPrimary),
        bodyMedium: GoogleFonts.atkinsonHyperlegible(fontSize: 16, fontWeight: FontWeight.w400, color: AppColors.textDarkSecondary),
        bodySmall: GoogleFonts.atkinsonHyperlegible(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textDarkSecondary),
        labelLarge: GoogleFonts.atkinsonHyperlegible(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
        labelMedium: GoogleFonts.atkinsonHyperlegible(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textDarkPrimary),
        labelSmall: GoogleFonts.atkinsonHyperlegible(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textDarkSecondary),
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.darkBorder, width: 1),
        ),
      ),
    );
  }

  // Utility: Devanagari / traditional text (keep for existing screens)
  static TextStyle devanagariStyle({required double fontSize, required Color color, FontWeight fontWeight = FontWeight.bold}) {
    return GoogleFonts.newsreader(fontSize: fontSize, color: color, fontWeight: fontWeight);
  }
}
