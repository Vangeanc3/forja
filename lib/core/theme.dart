import 'package:flutter/material.dart';

abstract final class ForjaColors {
  static const background = Color(0xFF0D0D0D);
  static const surface = Color(0xFF1A1A1A);
  static const surfaceVariant = Color(0xFF242424);
  static const ember = Color(0xFFFF6B1A);
  static const emberDim = Color(0xFFCC4A00);
  static const emberGlow = Color(0xFFFF9A56);
  static const onEmber = Color(0xFFFFFFFF);
  static const textPrimary = Color(0xFFF0EDE8);
  static const textSecondary = Color(0xFF9E9E9E);
  static const divider = Color(0xFF2A2A2A);
  static const error = Color(0xFFCF6679);
}

final forjaDarkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  scaffoldBackgroundColor: ForjaColors.background,
  colorScheme: const ColorScheme.dark(
    primary: ForjaColors.ember,
    onPrimary: ForjaColors.onEmber,
    secondary: ForjaColors.emberGlow,
    onSecondary: ForjaColors.background,
    surface: ForjaColors.surface,
    onSurface: ForjaColors.textPrimary,
    surfaceContainerHighest: ForjaColors.surfaceVariant,
    error: ForjaColors.error,
    outline: ForjaColors.divider,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: ForjaColors.background,
    foregroundColor: ForjaColors.textPrimary,
    elevation: 0,
    scrolledUnderElevation: 0,
    centerTitle: true,
  ),
  textTheme: const TextTheme(
    displayLarge: TextStyle(
      color: ForjaColors.textPrimary,
      fontWeight: FontWeight.w800,
      letterSpacing: -1.5,
    ),
    displayMedium: TextStyle(
      color: ForjaColors.textPrimary,
      fontWeight: FontWeight.w700,
      letterSpacing: -1.0,
    ),
    headlineLarge: TextStyle(
      color: ForjaColors.textPrimary,
      fontWeight: FontWeight.w700,
    ),
    headlineMedium: TextStyle(
      color: ForjaColors.textPrimary,
      fontWeight: FontWeight.w600,
    ),
    titleLarge: TextStyle(
      color: ForjaColors.textPrimary,
      fontWeight: FontWeight.w600,
    ),
    bodyLarge: TextStyle(color: ForjaColors.textPrimary),
    bodyMedium: TextStyle(color: ForjaColors.textSecondary),
    labelLarge: TextStyle(
      color: ForjaColors.ember,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.2,
    ),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: ForjaColors.ember,
      foregroundColor: ForjaColors.onEmber,
      minimumSize: const Size(double.infinity, 52),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: ForjaColors.ember,
      side: const BorderSide(color: ForjaColors.ember),
      minimumSize: const Size(double.infinity, 52),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  ),
  cardTheme: CardThemeData(
    color: ForjaColors.surface,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: ForjaColors.divider),
    ),
    margin: EdgeInsets.zero,
  ),
  dividerTheme: const DividerThemeData(
    color: ForjaColors.divider,
    thickness: 1,
  ),
  navigationBarTheme: NavigationBarThemeData(
    backgroundColor: ForjaColors.surface,
    indicatorColor: ForjaColors.ember.withValues(alpha: 0.15),
    iconTheme: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return const IconThemeData(color: ForjaColors.ember);
      }
      return const IconThemeData(color: ForjaColors.textSecondary);
    }),
    labelTextStyle: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return const TextStyle(
          color: ForjaColors.ember,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        );
      }
      return const TextStyle(color: ForjaColors.textSecondary, fontSize: 12);
    }),
  ),
);
