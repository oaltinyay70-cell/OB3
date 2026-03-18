import 'package:flutter/material.dart';

class MilstdTheme {
  // Color tokens
  static const Color backgroundPrimary = Color(0xFF0A0E14);
  static const Color backgroundSecondary = Color(0xFF111927);
  static const Color backgroundTertiary = Color(0xFF1A2332);
  static const Color backgroundOverlay = Color(0xCC0A0E14);
  static const Color surface = Color(0xFF1E293B);
  static const Color surfaceHover = Color(0xFF253347);

  static const Color accentPrimary = Color(0xFF00E676);
  static const Color accentPrimaryDim = Color(0x4000C864);
  static const Color accentSecondary = Color(0xFF40C4FF);
  static const Color accentWarm = Color(0xFFFFB300);
  static const Color accentDanger = Color(0xFFFF1744);

  static const Color statusOk = Color(0xFF00E676);
  static const Color statusCaution = Color(0xFFFFD600);
  static const Color statusWarning = Color(0xFFFF9100);
  static const Color statusCritical = Color(0xFFFF1744);
  static const Color statusDestroyed = Color(0xFFB71C1C);

  static const Color textPrimary = Color(0xFFE0E7EF);
  static const Color textSecondary = Color(0xFF8B9BB4);
  static const Color textMuted = Color(0xFF4A5568);
  static const Color textInverse = Color(0xFF0A0E14);
  static const Color textHud = Color(0xFF00E676);

  static const Color borderSubtle = Color(0xFF1E293B);
  static const Color borderDefault = Color(0xFF2D3F56);
  static const Color borderActive = Color(0xFF00E676);
  static const Color borderDanger = Color(0xFFFF1744);

  // Spacing System (Base unit: 4pt)
  static const double space1 = 4.0;
  static const double space2 = 8.0;
  static const double space3 = 12.0;
  static const double space4 = 16.0;
  static const double space5 = 20.0;
  static const double space6 = 24.0;
  static const double space8 = 32.0;
  static const double space10 = 40.0;
  static const double space12 = 48.0;

  // Border Radius
  static const Radius radiusXs = Radius.circular(2.0);
  static const Radius radiusSm = Radius.circular(4.0);
  static const Radius radiusMd = Radius.circular(6.0);
  static const Radius radiusLg = Radius.circular(8.0);
  static const Radius radiusFull = Radius.circular(999.0);

  static ThemeData get themeData {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: backgroundPrimary,
      primaryColor: accentPrimary,
      canvasColor: backgroundSecondary,
      cardColor: surface,
      dividerColor: borderDefault,
      colorScheme: const ColorScheme.dark(
        primary: accentPrimary,
        secondary: accentSecondary,
        surface: surface,
        error: accentDanger,
        onPrimary: textInverse,
        onSecondary: textInverse,
        onSurface: textPrimary,
        onError: textInverse,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontFamily: 'Rajdhani', fontSize: 32, fontWeight: FontWeight.w700, height: 1.1, color: textPrimary, letterSpacing: 0.5),
        displayMedium: TextStyle(fontFamily: 'Rajdhani', fontSize: 24, fontWeight: FontWeight.w600, height: 1.2, color: textPrimary, letterSpacing: 0.5),
        headlineLarge: TextStyle(fontFamily: 'Rajdhani', fontSize: 20, fontWeight: FontWeight.w600, height: 1.3, color: textPrimary, letterSpacing: 0.5),
        headlineMedium: TextStyle(fontFamily: 'Rajdhani', fontSize: 16, fontWeight: FontWeight.w600, height: 1.3, color: textPrimary, letterSpacing: 0.5),
        bodyLarge: TextStyle(fontFamily: 'IBMPlexSans', fontSize: 16, fontWeight: FontWeight.w400, height: 1.5, color: textPrimary),
        bodyMedium: TextStyle(fontFamily: 'IBMPlexSans', fontSize: 14, fontWeight: FontWeight.w400, height: 1.5, color: textSecondary),
        bodySmall: TextStyle(fontFamily: 'IBMPlexSans', fontSize: 12, fontWeight: FontWeight.w400, height: 1.4, color: textMuted),
        labelSmall: TextStyle(fontFamily: 'IBMPlexSans', fontSize: 10, fontWeight: FontWeight.w600, height: 1.2, color: textSecondary, letterSpacing: 1.5),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundSecondary,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: accentPrimary),
        titleTextStyle: TextStyle(fontFamily: 'Rajdhani', fontSize: 20, fontWeight: FontWeight.w600, color: textPrimary, letterSpacing: 0.5),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentPrimary,
          foregroundColor: textInverse,
          textStyle: const TextStyle(fontFamily: 'Rajdhani', fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 1.0),
          padding: const EdgeInsets.symmetric(horizontal: space4, vertical: space3),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(radiusSm)),
          elevation: 2,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: accentSecondary,
          side: const BorderSide(color: accentSecondary, width: 1),
          textStyle: const TextStyle(fontFamily: 'Rajdhani', fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 1.0),
          padding: const EdgeInsets.symmetric(horizontal: space4, vertical: space3),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(radiusSm)),
        ),
      ),
      cardTheme: const CardThemeData(
        color: surface,
        elevation: 1,
        shadowColor: Colors.black45,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(radiusMd),
          side: BorderSide(color: borderDefault, width: 1),
        ),
        margin: EdgeInsets.all(space2),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: backgroundSecondary,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(radiusLg), side: BorderSide(color: borderActive, width: 1)),
      ),
    );
  }
}
