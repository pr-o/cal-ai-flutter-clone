import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class AppColors {
  // Backgrounds
  static const bgPrimaryLight = Color(0xFFFFFFFF);
  static const bgSecondaryLight = Color(0xFFF5F5F5);
  static const bgPrimaryDark = Color(0xFF111111);
  static const bgSecondaryDark = Color(0xFF1E1E1E);

  // Accent
  static const accentOrange = Color(0xFFFF5500);

  // Macros
  static const macroProtein = Color(0xFFFF6B35);
  static const macroCarbs = Color(0xFFFFB800);
  static const macroFat = Color(0xFF4A9EFF);

  // UI
  static const black = Color(0xFF000000);
  static const white = Color(0xFFFFFFFF);
  static const pillUnselected = Color(0xFFF0F0F0);
  static const pillUnselectedDark = Color(0xFF2A2A2A);
}

ThemeData _base(ColorScheme colorScheme) {
  final textTheme = GoogleFonts.interTextTheme(
    ThemeData(brightness: colorScheme.brightness).textTheme,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    textTheme: textTheme,
    scaffoldBackgroundColor: colorScheme.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: colorScheme.surface,
      elevation: 0,
      scrolledUnderElevation: 0,
      iconTheme: IconThemeData(color: colorScheme.onSurface),
      titleTextStyle: textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
        color: colorScheme.onSurface,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.black,
        foregroundColor: AppColors.white,
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        textStyle: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: colorScheme.onSurface,
        minimumSize: const Size(0, 52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        side: BorderSide(color: colorScheme.outline),
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: colorScheme.surface,
      selectedItemColor: AppColors.black,
      unselectedItemColor: colorScheme.onSurface.withValues(alpha: 0.4),
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    dividerTheme: DividerThemeData(
      color: colorScheme.onSurface.withValues(alpha: 0.08),
      space: 1,
      thickness: 1,
    ),
  );
}

final lightTheme = _base(
  const ColorScheme.light(
    surface: AppColors.bgPrimaryLight,
    onSurface: AppColors.black,
    surfaceContainerHighest: AppColors.bgSecondaryLight,
    primary: AppColors.black,
    onPrimary: AppColors.white,
    outline: Color(0xFFE0E0E0),
  ),
);

final darkTheme = _base(
  const ColorScheme.dark(
    surface: AppColors.bgPrimaryDark,
    onSurface: AppColors.white,
    surfaceContainerHighest: AppColors.bgSecondaryDark,
    primary: AppColors.white,
    onPrimary: AppColors.black,
    outline: Color(0xFF333333),
  ),
);
