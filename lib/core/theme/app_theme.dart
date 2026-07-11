import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';
import '../constants/app_radius.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: Colors.white,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.accent,
        onPrimary: AppColors.textInverted,
        secondary: AppColors.secondary,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        error: AppColors.error,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: AppTextStyles.titleLarge,
        iconTheme: const IconThemeData(color: AppColors.icon),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.textInverted,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusMd),
          textStyle: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.bold),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.accent,
          side: const BorderSide(color: AppColors.accent),
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusMd),
          textStyle: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.accent,
          textStyle: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.inputBackground,
        border: OutlineInputBorder(
          borderRadius: AppRadius.radiusMd,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.radiusMd,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.radiusMd,
          borderSide: const BorderSide(color: AppColors.accent, width: 1),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.radiusMd,
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
        hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textTertiary),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      cardTheme: CardThemeData(
        color: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusLg),
        elevation: 0,
        margin: EdgeInsets.zero,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.accent,
        unselectedItemColor: AppColors.textTertiary,
        selectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 12),
        type: BottomNavigationBarType.fixed,
        elevation: 20,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusLg),
        titleTextStyle: AppTextStyles.titleLarge,
        contentTextStyle: AppTextStyles.bodyMedium,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.card,
        contentTextStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusMd),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.accent;
          return Colors.transparent;
        }),
        side: const BorderSide(color: AppColors.textTertiary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return AppColors.textTertiary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.accent;
          return AppColors.card;
        }),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.all(AppColors.accent),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.card,
        disabledColor: AppColors.card.withValues(alpha: 0.5),
        selectedColor: AppColors.accent,
        secondarySelectedColor: AppColors.accent,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusSm),
        labelStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary),
        secondaryLabelStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.textInverted),
        brightness: Brightness.dark,
      ),
    );
  }


}
