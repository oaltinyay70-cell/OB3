import 'package:flutter/material.dart';
import '../../core/theme/milstd_theme.dart';

/// Animated fuel color bar widget.
///
/// Displays fuel as a horizontal bar that smoothly transitions through
/// green → blue → orange → red as fuel depletes. No numeric value shown.
class FuelColorBar extends StatelessWidget {
  const FuelColorBar({
    super.key,
    required this.fuelPercent,
    this.height = 12.0,
    this.showLabel = true,
    this.showTickMarks = true,
  });

  /// Current fuel as a percentage (0.0 to 1.0).
  final double fuelPercent;

  /// Height of the bar itself.
  final double height;

  /// Whether to show the "FUEL" label above the bar.
  final bool showLabel;

  /// Whether to show tick marks at 25%, 50%, 75%.
  final bool showTickMarks;

  Color _barColor(double pct) {
    if (pct > 0.75) return MilstdTheme.statusOk;         // Green  (75-100%)
    if (pct > 0.40) return MilstdTheme.accentSecondary;   // Blue   (40-75%) PRD §6.1
    if (pct > 0.10) return MilstdTheme.statusWarning;     // Orange (10-40%)
    return MilstdTheme.statusCritical;                     // Red    (0-10%)
  }

  Color _labelColor(double pct) {
    if (pct > 0.75) return MilstdTheme.textSecondary;
    if (pct > 0.40) return MilstdTheme.accentSecondary;
    if (pct > 0.10) return MilstdTheme.accentWarm;
    return MilstdTheme.accentDanger;
  }

  List<BoxShadow>? _glow(double pct) {
    if (pct > 0.75) {
      return [const BoxShadow(color: Color(0x4D00E676), blurRadius: 12)]; // green
    }
    if (pct > 0.40) {
      return [const BoxShadow(color: Color(0x4D40C4FF), blurRadius: 12)]; // blue
    }
    if (pct > 0.10) {
      return [const BoxShadow(color: Color(0x4DFFB300), blurRadius: 12)]; // orange
    }
    return [const BoxShadow(color: Color(0x4DFF1744), blurRadius: 12)];   // red
  }

  @override
  Widget build(BuildContext context) {
    final clampedPct = fuelPercent.clamp(0.0, 1.0);
    final barColor = _barColor(clampedPct);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showLabel)
          Padding(
            padding: const EdgeInsets.only(bottom: 4.0),
            child: Text(
              'FUEL',
              style: TextStyle(
                fontFamily: 'ShareTechMono',
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: _labelColor(clampedPct),
                letterSpacing: 1.5,
              ),
            ),
          ),
        Container(
          height: height,
          decoration: BoxDecoration(
            color: MilstdTheme.backgroundTertiary,
            borderRadius: const BorderRadius.all(MilstdTheme.radiusXs),
            border: Border.all(color: MilstdTheme.borderDefault, width: 1),
          ),
          child: Stack(
            children: [
              // Filled portion
              AnimatedFractionallySizedBox(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                widthFactor: clampedPct,
                alignment: Alignment.centerLeft,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  decoration: BoxDecoration(
                    color: barColor,
                    borderRadius: const BorderRadius.all(MilstdTheme.radiusXs),
                    boxShadow: _glow(clampedPct),
                  ),
                ),
              ),
              // Tick marks at 25%, 50%, 75%
              if (showTickMarks)
                ...List.generate(3, (i) {
                  final position = (i + 1) * 0.25;
                  return Positioned(
                    left: 0,
                    right: 0,
                    top: 0,
                    bottom: 0,
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: position,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          width: 1,
                          color: MilstdTheme.textMuted.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  );
                }),
            ],
          ),
        ),
      ],
    );
  }
}

/// Animated version of FractionallySizedBox.
class AnimatedFractionallySizedBox extends ImplicitlyAnimatedWidget {
  const AnimatedFractionallySizedBox({
    super.key,
    required super.duration,
    super.curve,
    this.widthFactor,
    this.heightFactor,
    this.alignment = Alignment.center,
    this.child,
  });

  final double? widthFactor;
  final double? heightFactor;
  final AlignmentGeometry alignment;
  final Widget? child;

  @override
  AnimatedWidgetBaseState<AnimatedFractionallySizedBox> createState() =>
      _AnimatedFractionallySizedBoxState();
}

class _AnimatedFractionallySizedBoxState
    extends AnimatedWidgetBaseState<AnimatedFractionallySizedBox> {
  Tween<double>? _widthFactor;
  Tween<double>? _heightFactor;

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _widthFactor = visitor(
      _widthFactor,
      widget.widthFactor ?? 1.0,
      (dynamic value) => Tween<double>(begin: value as double),
    ) as Tween<double>?;
    _heightFactor = visitor(
      _heightFactor,
      widget.heightFactor ?? 1.0,
      (dynamic value) => Tween<double>(begin: value as double),
    ) as Tween<double>?;
  }

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: _widthFactor?.evaluate(animation),
      heightFactor: _heightFactor?.evaluate(animation),
      alignment: widget.alignment,
      child: widget.child,
    );
  }
}
