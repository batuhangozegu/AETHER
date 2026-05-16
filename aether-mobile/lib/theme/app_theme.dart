// lib/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    final base = ThemeData.dark();

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.bg0,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.accent,
        secondary: AppColors.profit,
        error: AppColors.loss,
        surface: AppColors.surface1,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.text1,
        onError: Colors.white,
      ),
      textTheme: GoogleFonts.spaceGroteskTextTheme(base.textTheme).copyWith(
        displayLarge: GoogleFonts.spaceGrotesk(
          color: AppColors.text1,
          fontSize: 42,
          fontWeight: FontWeight.w500,
          letterSpacing: -1.0,
        ),
        displayMedium: GoogleFonts.spaceGrotesk(
          color: AppColors.text1,
          fontSize: 28,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.5,
        ),
        headlineLarge: GoogleFonts.spaceGrotesk(
          color: AppColors.text1,
          fontSize: 24,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.5,
        ),
        headlineMedium: GoogleFonts.spaceGrotesk(
          color: AppColors.text1,
          fontSize: 21,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.4,
        ),
        titleLarge: GoogleFonts.spaceGrotesk(
          color: AppColors.text1,
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
        titleMedium: GoogleFonts.spaceGrotesk(
          color: AppColors.text1,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: GoogleFonts.spaceGrotesk(
          color: AppColors.text2,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        bodyMedium: GoogleFonts.spaceGrotesk(
          color: AppColors.text2,
          fontSize: 13,
          fontWeight: FontWeight.w400,
        ),
        bodySmall: GoogleFonts.spaceGrotesk(
          color: AppColors.text3,
          fontSize: 11,
          fontWeight: FontWeight.w400,
        ),
        labelSmall: GoogleFonts.spaceGrotesk(
          color: AppColors.text3,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarBrightness: Brightness.dark,
          statusBarIconBrightness: Brightness.light,
        ),
        titleTextStyle: GoogleFonts.spaceGrotesk(
          color: AppColors.text1,
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        selectedItemColor: AppColors.accent,
        unselectedItemColor: AppColors.text3,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface1,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.hairline, width: 0.5),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface1,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.hairline, width: 0.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.hairline, width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.accent, width: 1),
        ),
        labelStyle: GoogleFonts.spaceGrotesk(
          color: AppColors.text3,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: AppColors.accent,
        inactiveTrackColor: AppColors.surface3,
        thumbColor: AppColors.accent,
        overlayColor: AppColors.accentSoft,
        thumbShape: RoundSliderThumbShape(enabledThumbRadius: 11),
        trackHeight: 4,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.white
              : AppColors.text3,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.accent
              : AppColors.surface3,
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
    );
  }

  // Mono font için yardımcı
  static TextStyle mono({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w400,
    Color color = AppColors.text1,
    double letterSpacing = -0.5,
  }) =>
      GoogleFonts.jetBrainsMono(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing,
      );
}
