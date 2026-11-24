import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'futuremug_colors.dart';

class FuturemugAppTheme {
  FuturemugAppTheme._();

  static ThemeData get whiteTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: FuturemugColors.navyPrimary,
      scaffoldBackgroundColor: FuturemugColors.canvasAlabaster,
      fontFamily: 'Plus Jakarta Sans',
      canvasColor: FuturemugColors.canvasAlabaster,
      colorScheme: const ColorScheme(
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
        outline: FuturemugColors.borderSubtle,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: FuturemugColors.surfacePureWhite,
        foregroundColor: FuturemugColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
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
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: FuturemugColors.borderSubtle, width: 1),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: FuturemugColors.navyPrimary,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
