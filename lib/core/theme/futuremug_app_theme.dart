import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:futuremug_interviewer/core/theme/futuremug_colors.dart';

/// App-wide theme. Widgets should read colours and text styles from
/// `Theme.of(context)` rather than hard-coding [FuturemugColors], so a dark
/// theme can be added in Phase 2 without touching every screen.
abstract final class FuturemugAppTheme {
  static const String fontFamily = 'Plus Jakarta Sans';

  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 20;
  static const double minTouchTarget = 48;

  static ThemeData get whiteTheme {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: FuturemugColors.navyPrimary,
      onPrimary: Colors.white,
      primaryContainer: FuturemugColors.navySubtle,
      onPrimaryContainer: FuturemugColors.navyPrimary,
      secondary: FuturemugColors.blueAccent,
      onSecondary: Colors.white,
      secondaryContainer: FuturemugColors.blueSubtle,
      onSecondaryContainer: Color(0xFF1D4ED8),
      tertiary: FuturemugColors.successEmerald,
      onTertiary: Colors.white,
      error: FuturemugColors.dangerRose,
      onError: Colors.white,
      surface: FuturemugColors.surfacePureWhite,
      onSurface: FuturemugColors.textPrimary,
      onSurfaceVariant: FuturemugColors.textSecondary,
      surfaceContainerLowest: FuturemugColors.surfacePureWhite,
      surfaceContainerLow: FuturemugColors.surfaceContainerLow,
      surfaceContainer: FuturemugColors.surfaceContainer,
      surfaceContainerHigh: FuturemugColors.surfaceContainerHigh,
      surfaceContainerHighest: FuturemugColors.surfaceContainerHighest,
      outline: FuturemugColors.borderMedium,
      outlineVariant: FuturemugColors.borderSubtle,
    );

    final base = ThemeData(
      brightness: Brightness.light,
      colorScheme: colorScheme,
      fontFamily: fontFamily,
      scaffoldBackgroundColor: FuturemugColors.canvasAlabaster,
      canvasColor: FuturemugColors.canvasAlabaster,
    );

    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(radiusMd),
      borderSide: const BorderSide(color: FuturemugColors.borderSubtle),
    );

    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: FuturemugColors.textPrimary,
        displayColor: FuturemugColors.textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: FuturemugColors.canvasAlabaster,
        foregroundColor: FuturemugColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: FuturemugColors.navyPrimary,
        ),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
      ),
      cardTheme: CardThemeData(
        color: FuturemugColors.surfacePureWhite,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          side: const BorderSide(color: FuturemugColors.borderSubtle),
        ),
        margin: const EdgeInsets.symmetric(vertical: 6),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: FuturemugColors.surfaceContainerLow,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: const TextStyle(color: FuturemugColors.textMuted),
        prefixIconColor: FuturemugColors.textTertiary,
        suffixIconColor: FuturemugColors.textTertiary,
        border: inputBorder,
        enabledBorder: inputBorder,
        focusedBorder: inputBorder.copyWith(
          borderSide: const BorderSide(color: FuturemugColors.blueAccent, width: 2),
        ),
        errorBorder: inputBorder.copyWith(
          borderSide: const BorderSide(color: FuturemugColors.dangerRose),
        ),
        focusedErrorBorder: inputBorder.copyWith(
          borderSide: const BorderSide(color: FuturemugColors.dangerRose, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: FuturemugColors.navyPrimary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: FuturemugColors.surfaceContainerHigh,
          disabledForegroundColor: FuturemugColors.textMuted,
          elevation: 0,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: FuturemugColors.navyPrimary,
          minimumSize: const Size.fromHeight(52),
          side: const BorderSide(color: FuturemugColors.borderMedium),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: FuturemugColors.blueAccent,
          minimumSize: const Size(minTouchTarget, minTouchTarget),
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: FuturemugColors.surfacePureWhite,
        indicatorColor: FuturemugColors.navySubtle,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? FuturemugColors.navyPrimary
                : FuturemugColors.textTertiary,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontFamily: fontFamily,
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? FuturemugColors.navyPrimary
                : FuturemugColors.textTertiary,
          ),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
      dividerTheme: const DividerThemeData(
        color: FuturemugColors.borderSubtle,
        space: 1,
        thickness: 1,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: FuturemugColors.blueAccent,
        linearTrackColor: FuturemugColors.surfaceContainer,
      ),
    );
  }
}
