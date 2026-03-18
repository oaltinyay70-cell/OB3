import 'package:flutter/material.dart';
import '../service_locator.dart';
import '../services/local_file_service.dart';

// ---------------------------------------------------------------------------
// Theme mode enum
// ---------------------------------------------------------------------------

enum AppThemeMode { standard, milstd }

// ---------------------------------------------------------------------------
// Theme provider — holds the current mode and notifies listeners on change.
// ---------------------------------------------------------------------------

class AppThemeProvider extends ChangeNotifier {
  static const String _storageKey = 'ui_theme';

  AppThemeMode _mode = AppThemeMode.standard;
  AppThemeMode get mode => _mode;

  /// Call once at startup to restore the saved preference.
  Future<void> init() async {
    final stored = await getIt<LocalFileService>().getData(_storageKey);
    if (stored == 'milstd') {
      _mode = AppThemeMode.milstd;
    }
  }

  Future<void> setMode(AppThemeMode m) async {
    if (_mode == m) return;
    _mode = m;
    notifyListeners();
    await getIt<LocalFileService>().saveData(
      _storageKey,
      m == AppThemeMode.milstd ? 'milstd' : 'standard',
    );
  }

  bool get isMilStd => _mode == AppThemeMode.milstd;
}

// ---------------------------------------------------------------------------
// Colour palettes
// ---------------------------------------------------------------------------

class ThemeColors {
  final Color background;
  final Color surface;
  final Color surfaceElevated;
  final Color surfaceBorder;

  final Color primary;
  final Color primaryDim;
  final Color secondary;
  final Color accent;

  final Color success;
  final Color warning;
  final Color danger;
  final Color info;

  final Color textPrimary;
  final Color textSecondary;
  final Color textDisabled;
  final Color textOnPrimary;

  final Color overlayLight;
  final Color overlayDark;

  final double cardRadius;

  const ThemeColors({
    required this.background,
    required this.surface,
    required this.surfaceElevated,
    required this.surfaceBorder,
    required this.primary,
    required this.primaryDim,
    required this.secondary,
    required this.accent,
    required this.success,
    required this.warning,
    required this.danger,
    required this.info,
    required this.textPrimary,
    required this.textSecondary,
    required this.textDisabled,
    required this.textOnPrimary,
    required this.overlayLight,
    required this.overlayDark,
    this.cardRadius = 8.0,
  });

  // ── Standard (current cyan/dark blue) ──────────────────────────────────

  static const standard = ThemeColors(
    background: Color(0xFF0A0A12),
    surface: Color(0xFF13131F),
    surfaceElevated: Color(0xFF1C1C2E),
    surfaceBorder: Color(0xFF2A2A40),
    primary: Color(0xFF00E5FF),
    primaryDim: Color(0xFF0097A7),
    secondary: Color(0xFF7C4DFF),
    accent: Color(0xFFFFD740),
    success: Color(0xFF00E676),
    warning: Color(0xFFFFAB40),
    danger: Color(0xFFFF5252),
    info: Color(0xFF40C4FF),
    textPrimary: Color(0xFFEEEEEE),
    textSecondary: Color(0xFF9E9E9E),
    textDisabled: Color(0xFF424242),
    textOnPrimary: Color(0xFF000000),
    overlayLight: Color(0x14FFFFFF),
    overlayDark: Color(0x80000000),
    cardRadius: 8.0,
  );

  // ── MILSTD (green/black terminal) ──────────────────────────────────────

  static const milstd = ThemeColors(
    background: Color(0xFF0D0D0D),
    surface: Color(0xFF111111),
    surfaceElevated: Color(0xFF161616),
    surfaceBorder: Color(0xFF1A3A1A),
    primary: Color(0xFF00FF41),       // terminal green
    primaryDim: Color(0xFF009926),
    secondary: Color(0xFFFF6B00),     // orange
    accent: Color(0xFFFF6B00),
    success: Color(0xFF00FF41),
    warning: Color(0xFFFF6B00),
    danger: Color(0xFFFF3D00),
    info: Color(0xFF00FF41),
    textPrimary: Color(0xFFC0FFC0),   // green-tinted
    textSecondary: Color(0xFF608060),
    textDisabled: Color(0xFF2A3A2A),
    textOnPrimary: Color(0xFF000000),
    overlayLight: Color(0x1400FF41),
    overlayDark: Color(0x80000000),
    cardRadius: 2.0,                  // sharp corners
  );

  static ThemeColors of(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.standard:
        return standard;
      case AppThemeMode.milstd:
        return milstd;
    }
  }
}
