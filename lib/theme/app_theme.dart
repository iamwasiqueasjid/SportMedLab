import 'package:flutter/material.dart';
import 'colors.dart';

/// Light Theme
final ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  primaryColor: AppColors.lightPrimary,
  secondaryHeaderColor: AppColors.lightSecondary,
  scaffoldBackgroundColor: AppColors.lightBackground,
  colorScheme: ColorScheme.light(
    primary: AppColors.lightPrimary,
    onPrimary: Colors.white, // Text on primary buttons
    surface: AppColors.lightBackground,
    onSurface: AppColors.lightTextPrimary,
    secondary: AppColors.lightTextSecondary,
  ),
  textTheme: TextTheme(
    bodyLarge: TextStyle(
      color: AppColors.lightTextPrimary,
      fontFamily: 'Inter',
    ),
    bodyMedium: TextStyle(
      color: AppColors.lightTextSecondary,
      fontFamily: 'Inter',
    ),
    bodySmall: TextStyle(
      color: AppColors.lightTextSecondary,
      fontFamily: 'Inter',
    ),
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: AppColors.lightPrimary,
    titleTextStyle: TextStyle(
      color: AppColors.lightTextPrimary,
      fontWeight: FontWeight.bold,
      fontFamily: 'Inter',
    ),
    iconTheme: IconThemeData(color: AppColors.lightTextPrimary),
  ),
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    backgroundColor: AppColors.lightPrimary,
  ),
);

final ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  primaryColor: AppColors.darkPrimary,
  secondaryHeaderColor: AppColors.lightSecondary,
  scaffoldBackgroundColor: AppColors.darkBackground,
  colorScheme: ColorScheme.dark(
    primary: AppColors.darkPrimary,
    onPrimary: Colors.white,
    surface: AppColors.darkBackground,
    onSurface: AppColors.darkTextPrimary,
    secondary: AppColors.darkTextSecondary,
  ),
  textTheme: TextTheme(
    bodyLarge: TextStyle(color: AppColors.darkTextPrimary, fontFamily: 'Inter'),
    bodyMedium: TextStyle(
      color: AppColors.darkTextSecondary,
      fontFamily: 'Inter',
    ),
    bodySmall: TextStyle(
      color: AppColors.darkTextSecondary,
      fontFamily: 'Inter',
    ),
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: AppColors.darkPrimary,
    titleTextStyle: TextStyle(
      color: AppColors.darkTextPrimary,
      fontWeight: FontWeight.bold,
      fontFamily: 'Inter',
    ),
    iconTheme: IconThemeData(color: AppColors.darkTextPrimary),
  ),
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    backgroundColor: AppColors.darkPrimary,
  ),
);
