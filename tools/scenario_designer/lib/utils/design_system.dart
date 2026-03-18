import 'package:flutter/material.dart';

/// Sprint 6 (US-8.1): Centralised design system for Drone Commander.
/// All screens should import this file instead of hard-coding colours,
/// text styles, or spacing values.

// ---------------------------------------------------------------------------
// COLOURS
// ---------------------------------------------------------------------------

class AppColors {
  AppColors._();

  // Background layers
  static const Color background = Color(0xFF0A0A12);
  static const Color surface = Color(0xFF13131F);
  static const Color surfaceElevated = Color(0xFF1C1C2E);
  static const Color surfaceBorder = Color(0xFF2A2A40);

  // Brand / accent
  static const Color primary = Color(0xFF00E5FF); // cyan
  static const Color primaryDim = Color(0xFF0097A7);
  static const Color secondary = Color(0xFF7C4DFF); // purple
  static const Color accent = Color(0xFFFFD740); // amber

  // Semantic
  static const Color success = Color(0xFF00E676);
  static const Color warning = Color(0xFFFFAB40);
  static const Color danger = Color(0xFFFF5252);
  static const Color info = Color(0xFF40C4FF);

  // Text
  static const Color textPrimary = Color(0xFFEEEEEE);
  static const Color textSecondary = Color(0xFF9E9E9E);
  static const Color textDisabled = Color(0xFF424242);
  static const Color textOnPrimary = Color(0xFF000000);

  // Overlays
  static const Color overlayLight = Color(0x14FFFFFF);
  static const Color overlayDark = Color(0x80000000);
}

// ---------------------------------------------------------------------------
// TYPOGRAPHY
// ---------------------------------------------------------------------------

class AppTextStyles {
  AppTextStyles._();

  static const String _mono = 'Courier';

  static const TextStyle h1 = TextStyle(
    fontFamily: _mono,
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    letterSpacing: 3.0,
  );

  static const TextStyle h2 = TextStyle(
    fontFamily: _mono,
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    letterSpacing: 2.0,
  );

  static const TextStyle h3 = TextStyle(
    fontFamily: _mono,
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    letterSpacing: 1.5,
  );

  static const TextStyle body = TextStyle(
    fontFamily: _mono,
    fontSize: 14,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodySecondary = TextStyle(
    fontFamily: _mono,
    fontSize: 14,
    color: AppColors.textSecondary,
  );

  static const TextStyle small = TextStyle(
    fontFamily: _mono,
    fontSize: 12,
    color: AppColors.textSecondary,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: _mono,
    fontSize: 10,
    color: AppColors.textDisabled,
    letterSpacing: 1.0,
  );

  static const TextStyle label = TextStyle(
    fontFamily: _mono,
    fontSize: 12,
    fontWeight: FontWeight.bold,
    color: AppColors.primary,
    letterSpacing: 2.0,
  );
}

// ---------------------------------------------------------------------------
// SPACING  (8-pt grid)
// ---------------------------------------------------------------------------

class AppSpacing {
  AppSpacing._();

  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}

// ---------------------------------------------------------------------------
// RADII
// ---------------------------------------------------------------------------

class AppRadius {
  AppRadius._();

  static const double sm = 4.0;
  static const double md = 8.0;
  static const double lg = 12.0;
  static const BorderRadius card = BorderRadius.all(Radius.circular(md));
  static const BorderRadius button = BorderRadius.all(Radius.circular(sm));
}

// ---------------------------------------------------------------------------
// SHADOWS
// ---------------------------------------------------------------------------

class AppShadows {
  AppShadows._();

  static List<BoxShadow> get glow => [
    BoxShadow(
      color: AppColors.primary.withValues(alpha: 0.25),
      blurRadius: 16,
      spreadRadius: 2,
    ),
  ];

  static List<BoxShadow> get card => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.4),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
  ];
}

// ---------------------------------------------------------------------------
// REUSABLE WIDGETS
// ---------------------------------------------------------------------------

/// A styled primary button matching the Drone Commander design language.
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color? color;
  final IconData? icon;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primary;
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: c, width: 1.5),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.button),
          backgroundColor: c.withValues(alpha: 0.08),
          foregroundColor: c,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: c),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: AppTextStyles.body.copyWith(
                color: c,
                letterSpacing: 1.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A styled section card used across screens.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? borderColor;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: AppRadius.card,
        border: Border.all(color: borderColor ?? AppColors.surfaceBorder),
        boxShadow: AppShadows.card,
      ),
      child: child,
    );
  }
}

/// Section header label used inside cards.
class AppSectionLabel extends StatelessWidget {
  final String text;
  final Color? color;

  const AppSectionLabel(this.text, {super.key, this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTextStyles.label.copyWith(color: color ?? AppColors.primary),
    );
  }
}
