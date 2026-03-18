import 'package:flutter/material.dart';
import '../../core/theme/milstd_theme.dart';

/// Chevron Arrow Chain progress stepper for the game board.
///
/// 6 chevron/arrow-shaped segments: INGRESS → RECON → CONTACT → IP → WPN HOT → EGRESS
/// - Completed: dark green fill with green text + border
/// - Current: red/orange glow with white text
/// - Future: dark gray fill with muted text
class GameBoardProgress extends StatelessWidget {
  const GameBoardProgress({
    super.key,
    required this.currentPhaseIndex,
  });

  /// 0-based index: 0=B0, 1=B1, 2=B2, 3=B3, 4=B4, 5=B5
  final int currentPhaseIndex;

  static const _labels = [
    'INGRESS',
    'RECON',
    'CONTACT',
    'IP',
    'WPN HOT',
    'EGRESS',
  ];

  /// Per-phase accent colors (used for the active chevron)
  static const _phaseColors = [
    Color(0xFF06B6D4), // B0 — Cyan
    Color(0xFF3B82F6), // B1 — Blue
    Color(0xFF8B5CF6), // B2 — Purple
    Color(0xFFEC4899), // B3 — Pink
    Color(0xFFEF4444), // B4 — Red
    Color(0xFFF97316), // B5 — Orange
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: SizedBox(
        height: 32,
        child: Row(
          children: List.generate(_labels.length, (i) {
            final isCompleted = i < currentPhaseIndex;
            final isCurrent = i == currentPhaseIndex;
            final isFuture = i > currentPhaseIndex;

            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(left: i == 0 ? 0 : 2),
                child: CustomPaint(
                  painter: _ChevronPainter(
                    isFirst: i == 0,
                    isLast: i == _labels.length - 1,
                    isCompleted: isCompleted,
                    isCurrent: isCurrent,
                    isFuture: isFuture,
                    activeColor: _phaseColors[i],
                  ),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: Text(
                        _labels[i],
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.visible,
                        style: TextStyle(
                          fontFamily: 'IBMPlexSans',
                          fontSize: i == 4 ? 7 : 8, // WPN HOT is longer
                          fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                          color: isCurrent
                              ? Colors.white
                              : isCompleted
                                  ? MilstdTheme.accentPrimary
                                  : MilstdTheme.textMuted,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

/// Custom painter that draws a single chevron/arrow shape.
///
/// Shape: flat left edge (or notched for non-first), pointed right edge.
///
///   ┌─────────╲
///   │          ╲   ← arrow point
///   │          ╱
///   └─────────╱
///
/// For non-first chevrons, the left edge has a matching notch:
///
///   ╲─────────╲
///    ╲         ╲
///    ╱          ╱
///   ╱──────────╱
class _ChevronPainter extends CustomPainter {
  _ChevronPainter({
    required this.isFirst,
    required this.isLast,
    required this.isCompleted,
    required this.isCurrent,
    required this.isFuture,
    required this.activeColor,
  });

  final bool isFirst;
  final bool isLast;
  final bool isCompleted;
  final bool isCurrent;
  final bool isFuture;
  final Color activeColor;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final arrowDepth = h * 0.3; // how deep the arrow point goes

    // Build the chevron path
    final path = Path();

    if (isFirst) {
      // First chevron: flat left, pointed right
      path.moveTo(0, 0);
      path.lineTo(w - arrowDepth, 0);
      path.lineTo(w, h / 2);
      path.lineTo(w - arrowDepth, h);
      path.lineTo(0, h);
      path.close();
    } else if (isLast) {
      // Last chevron: notched left, flat right
      path.moveTo(0, 0);
      path.lineTo(w, 0);
      path.lineTo(w, h);
      path.lineTo(0, h);
      path.lineTo(arrowDepth, h / 2);
      path.close();
    } else {
      // Middle chevron: notched left, pointed right
      path.moveTo(0, 0);
      path.lineTo(w - arrowDepth, 0);
      path.lineTo(w, h / 2);
      path.lineTo(w - arrowDepth, h);
      path.lineTo(0, h);
      path.lineTo(arrowDepth, h / 2);
      path.close();
    }

    // Fill color
    Color fillColor;
    Color borderColor;

    if (isCurrent) {
      fillColor = activeColor.withValues(alpha: 0.35);
      borderColor = activeColor;
    } else if (isCompleted) {
      fillColor = MilstdTheme.accentPrimary.withValues(alpha: 0.15);
      borderColor = MilstdTheme.accentPrimary.withValues(alpha: 0.6);
    } else {
      fillColor = MilstdTheme.backgroundTertiary;
      borderColor = MilstdTheme.borderSubtle;
    }

    // Draw fill
    canvas.drawPath(
      path,
      Paint()
        ..color = fillColor
        ..style = PaintingStyle.fill,
    );

    // Draw border
    canvas.drawPath(
      path,
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = isCurrent ? 1.5 : 1.0,
    );

    // Glow effect for current phase
    if (isCurrent) {
      canvas.drawPath(
        path,
        Paint()
          ..color = activeColor.withValues(alpha: 0.2)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.0
          ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 4),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ChevronPainter oldDelegate) =>
      oldDelegate.isCurrent != isCurrent ||
      oldDelegate.isCompleted != isCompleted;
}
