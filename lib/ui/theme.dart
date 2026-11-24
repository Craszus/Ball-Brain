import 'package:flutter/material.dart';

/// Palett fra designbriefen «Premium Nattkamp / Stadion-gull». Bruk disse eksakt.
class AppColors {
  static const pitch = Color(0xFF0B3D2E); // bakgrunn
  static const card = Color(0xFF145A42); // kort
  static const gold = Color(0xFFF5B301); // gull primær
  static const goldLight = Color(0xFFFFD84D); // gull lys
  static const goldLighter = Color(0xFFFFE27A);
  static const goldDark = Color(0xFFD99A00); // slutt på gull-gradient
  static const tile = Color(0xFF0A1224); // ikonbrikke
  static const textSecondary = Color(0xFFC9D6C8);
  static const grass = Color(0xFF2E9E5B); // riktig
  static const ink = Color(0xFF0E1F18); // mørk tekst på gull

  static const goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [goldLight, gold, goldDark],
  );
}

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.grass,
    brightness: Brightness.dark,
  ).copyWith(
    surface: AppColors.pitch,
    primary: AppColors.gold,
    onPrimary: AppColors.ink,
  );
  final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(16));
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.pitch,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        letterSpacing: 1,
        color: Colors.white,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.card,
      elevation: 6,
      shadowColor: Colors.black54,
      margin: const EdgeInsets.symmetric(vertical: 5),
      // Alle kort: radius 16, 1 px kant (grønn som standard, gull for fremhevede kort), skygge.
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.grass.withValues(alpha: 0.55)),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected) ? AppColors.ink : AppColors.textSecondary),
      trackColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected) ? AppColors.gold : Colors.white24),
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: AppColors.gold,
      inactiveTrackColor: Colors.white24,
      thumbColor: AppColors.gold,
      overlayColor: AppColors.gold.withValues(alpha: 0.2),
      valueIndicatorColor: AppColors.gold,
      valueIndicatorTextStyle: const TextStyle(
          color: AppColors.ink, fontWeight: FontWeight.w900),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.gold),
      ),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppColors.gold),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.gold,
        foregroundColor: AppColors.ink,
        disabledBackgroundColor: AppColors.card,
        disabledForegroundColor: Colors.white38,
        minimumSize: const Size.fromHeight(56),
        shape: shape,
        textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: Colors.white.withValues(alpha: 0.08),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.25)),
        minimumSize: const Size.fromHeight(56),
        shape: shape,
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
  );
}
