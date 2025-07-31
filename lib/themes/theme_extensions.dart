import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/theme_provider.dart';
import 'app_colors.dart';

// Predefined container decorations that automatically adapt to theme
class ThemeContainers {
  static BoxDecoration card(BuildContext context) {
    final isDark = context.isDarkMode;

    return BoxDecoration(
      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: isDark ? AppColors.darkShadow : AppColors.lightShadow,
          spreadRadius: 1,
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  static BoxDecoration elevatedContainer(BuildContext context) {
    final isDark = context.isDarkMode;
    return BoxDecoration(
      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: isDark ? AppColors.darkShadow : AppColors.lightShadow,
          spreadRadius: 2,
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  static BoxDecoration roundedContainer(
    BuildContext context, {
    double radius = 12,
  }) {
    final isDark = context.isDarkMode;
    return BoxDecoration(
      color:
          isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant,
      borderRadius: BorderRadius.circular(radius),
    );
  }
}

extension ThemeExtension on BuildContext {
  // Common background colors
  Color get backgroundColor => colors.surface;
  // Quick access to theme colors
  ColorScheme get colors => Theme.of(this).colorScheme;

  // Check if dark mode - uses ThemeProvider for consistent theme detection
  bool get isDarkMode {
    try {
      final themeProvider = Provider.of<ThemeProvider>(this, listen: false);
      switch (themeProvider.themeMode) {
        case ThemeMode.dark:
          return true;
        case ThemeMode.light:
          return false;
        case ThemeMode.system:
          return MediaQuery.of(this).platformBrightness == Brightness.dark;
      }
    } catch (e) {
      // Fallback to Theme.of(context) if ThemeProvider is not available
      return MediaQuery.of(this).platformBrightness == Brightness.dark;
    }
  }

  // Common text colors
  Color get onBackground => colors.onSurface;
  Color get onSurface => colors.onSurface;

  Color get onSurfaceVariant => colors.onSurfaceVariant;
  Color get primaryColor => colors.primary;
  Color get surfaceColor => colors.surface;

  TextTheme get textTheme => Theme.of(this).textTheme;
}
