import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get dark => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.primary,
          surface: AppColors.surface,
          error: AppColors.error,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: AppColors.onSurface,
        ),
        iconTheme: const IconThemeData(color: AppColors.onSurface),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            color: AppColors.onSurface,
            fontSize: 28,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
          bodyMedium: TextStyle(color: AppColors.onSurface, fontSize: 16),
          bodySmall: TextStyle(color: AppColors.onSurfaceSecondary, fontSize: 13),
        ),
        useMaterial3: true,
      );

  static CupertinoThemeData get cupertino => const CupertinoThemeData(
        brightness: Brightness.dark,
        primaryColor: AppColors.primary,
        barBackgroundColor: AppColors.surface,
        scaffoldBackgroundColor: AppColors.background,
        textTheme: CupertinoTextThemeData(
          primaryColor: AppColors.primary,
          textStyle: TextStyle(color: AppColors.onSurface, fontSize: 16),
        ),
      );
}
