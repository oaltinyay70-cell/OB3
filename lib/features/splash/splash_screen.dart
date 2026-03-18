import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/milstd_theme.dart';

/// Splash Screen (S00) — design-system.md §2.13
///
/// Animation sequence:
/// 0–500ms:   Background fades in, radar rings appear with scale-up
/// 500–1200ms: Radar arm begins sweeping, title types in letter-by-letter
/// 1200–1500ms: Subtitle and version fade in
/// 1500ms+:   Loading bar fills; text cycles through status messages
/// On complete: Smooth crossfade to next screen
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.onComplete});

  /// Called when splash sequence is complete and ready to navigate.
  final VoidCallback onComplete;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Phase controllers
  late AnimationController _bgFadeController;      // 0–500ms
  late AnimationController _radarSweepController;   // 500ms+, continuous
  late AnimationController _titleTypeController;    // 500–1200ms
  late AnimationController _subtitleFadeController;  // 1200–1500ms
  late AnimationController _loadingBarController;   // 1500ms+

  // Typewriter state
  static const _titleText = 'DRONE COMMANDER';
  int _visibleChars = 0;
  Timer? _typewriterTimer;

  // Loading text cycling
  static const _loadingTexts = [
    'INITIALIZING SYSTEMS...',
    'LOADING DATABASE...',
    'CALIBRATING SENSORS...',
    'ESTABLISHING UPLINK...',
  ];
  int _currentLoadingTextIndex = 0;
  Timer? _loadingTextTimer;

  @override
  void initState() {
    super.initState();

    // Phase 1: Background fade (0–500ms)
    _bgFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    // Continuous radar sweep (3s per rotation)
    _radarSweepController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    // Title typewriter (700ms for all chars)
    _titleTypeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    // Subtitle fade (300ms)
    _subtitleFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    // Loading bar (2.5s to fill)
    _loadingBarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    _startSequence();
  }

  Future<void> _startSequence() async {
    // Phase 1: 0–500ms — background + radar rings scale in
    _bgFadeController.forward();
    await Future.delayed(const Duration(milliseconds: 500));

    // Phase 2: 500ms — start radar sweep + typewriter
    _radarSweepController.repeat();
    _startTypewriter();
    await Future.delayed(const Duration(milliseconds: 700));

    // Phase 3: 1200ms — subtitle + version fade in
    _subtitleFadeController.forward();
    await Future.delayed(const Duration(milliseconds: 300));

    // Phase 4: 1500ms — loading bar starts
    _loadingBarController.forward();
    _startLoadingTextCycle();

    // Wait for loading bar to complete
    await Future.delayed(const Duration(milliseconds: 2500));

    // Complete — notify parent
    if (mounted) {
      widget.onComplete();
    }
  }

  void _startTypewriter() {
    const charDelay = Duration(milliseconds: 47); // ~700ms / 15 chars
    _typewriterTimer = Timer.periodic(charDelay, (timer) {
      if (_visibleChars >= _titleText.length) {
        timer.cancel();
        return;
      }
      setState(() => _visibleChars++);
    });
  }

  void _startLoadingTextCycle() {
    _loadingTextTimer = Timer.periodic(
      const Duration(milliseconds: 800),
      (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        setState(() {
          _currentLoadingTextIndex =
              (_currentLoadingTextIndex + 1) % _loadingTexts.length;
        });
      },
    );
  }

  @override
  void dispose() {
    _bgFadeController.dispose();
    _radarSweepController.dispose();
    _titleTypeController.dispose();
    _subtitleFadeController.dispose();
    _loadingBarController.dispose();
    _typewriterTimer?.cancel();
    _loadingTextTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MilstdTheme.backgroundPrimary,
      body: FadeTransition(
        opacity: _bgFadeController,
        child: Stack(
          children: [
            // Topographic grid background
            const _TopoGridBackground(),

            // Main centered content — full width so text is centered
            Positioned.fill(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Radar sweep circle
                  SizedBox(
                    width: 240,
                    height: 240,
                    child: _RadarSweep(
                      sweepController: _radarSweepController,
                      bgFadeController: _bgFadeController,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Title — typewriter effect
                  Text(
                    _titleText.substring(0, _visibleChars),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Rajdhani',
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                      color: MilstdTheme.accentPrimary,
                      letterSpacing: 1.0,
                      shadows: [
                        Shadow(
                          color: Color(0x4D00E676),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 4),

                  // Subtitle + version — fade in
                  FadeTransition(
                    opacity: _subtitleFadeController,
                    child: const Column(
                      children: [
                        Text(
                          'OBSCURE BATTLES 3',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'IBMPlexSans',
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: MilstdTheme.accentSecondary,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'V3.1',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'IBMPlexMono',
                            fontSize: 12,
                            color: MilstdTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Loading bar + text at bottom
            Positioned(
              left: 32,
              right: 32,
              bottom: 80,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Loading bar — 4pt tall, per spec
                  AnimatedBuilder(
                    animation: _loadingBarController,
                    builder: (context, child) {
                      return Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: MilstdTheme.backgroundTertiary,
                          borderRadius:
                              const BorderRadius.all(MilstdTheme.radiusXs),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: _loadingBarController.value,
                          child: Container(
                            decoration: BoxDecoration(
                              color: MilstdTheme.accentPrimary,
                              borderRadius:
                                  const BorderRadius.all(MilstdTheme.radiusXs),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x4D00E676),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  // Loading text — cycles through status messages
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Text(
                      _loadingTexts[_currentLoadingTextIndex],
                      key: ValueKey(_currentLoadingTextIndex),
                      style: const TextStyle(
                        fontFamily: 'ShareTechMono',
                        fontSize: 10,
                        color: MilstdTheme.textSecondary,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Faint topographic grid lines on the background.
class _TopoGridBackground extends StatelessWidget {
  const _TopoGridBackground();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: MediaQuery.of(context).size,
      painter: _TopoGridPainter(),
    );
  }
}

class _TopoGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF111927)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    const spacing = 32.0;

    // Horizontal lines
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Vertical lines
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Concentric circles (topographic contour lines)
    final center = Offset(size.width * 0.5, size.height * 0.35);
    final contourPaint = Paint()
      ..color = const Color(0x0D111927)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    for (double r = 60; r < size.width; r += 50) {
      canvas.drawCircle(center, r, contourPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Radar sweep with concentric rings and rotating arm.
///
/// Spec: 240pt diameter, concentric rings at 15% opacity,
/// sweeping arm at 40% opacity, 360° in 3s.
class _RadarSweep extends StatelessWidget {
  const _RadarSweep({
    required this.sweepController,
    required this.bgFadeController,
  });

  final AnimationController sweepController;
  final AnimationController bgFadeController;

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: CurvedAnimation(
        parent: bgFadeController,
        curve: Curves.easeOutBack,
      ),
      child: AnimatedBuilder(
        animation: sweepController,
        builder: (context, child) {
          return CustomPaint(
            size: const Size(240, 240),
            painter: _RadarPainter(sweepAngle: sweepController.value * 2 * math.pi),
          );
        },
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  _RadarPainter({required this.sweepAngle});

  final double sweepAngle;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    // Concentric rings — 15% opacity accent-primary
    final ringPaint = Paint()
      ..color = const Color(0x2600E676) // 15% of #00E676
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    for (int i = 1; i <= 4; i++) {
      canvas.drawCircle(center, maxRadius * (i / 4), ringPaint);
    }

    // Cross hairs
    final crossPaint = Paint()
      ..color = const Color(0x1A00E676) // 10%
      ..strokeWidth = 0.5;
    canvas.drawLine(
      Offset(center.dx, 0),
      Offset(center.dx, size.height),
      crossPaint,
    );
    canvas.drawLine(
      Offset(0, center.dy),
      Offset(size.width, center.dy),
      crossPaint,
    );

    // Sweep arm — 40% opacity
    final armPaint = Paint()
      ..shader = SweepGradient(
        center: Alignment.center,
        startAngle: sweepAngle - 0.5,
        endAngle: sweepAngle,
        colors: const [
          Color(0x0000E676), // transparent
          Color(0x6600E676), // 40% green
        ],
      ).createShader(Rect.fromCircle(center: center, radius: maxRadius))
      ..style = PaintingStyle.fill;

    // Draw sweep sector
    final sweepPath = Path()
      ..moveTo(center.dx, center.dy)
      ..lineTo(
        center.dx + maxRadius * math.cos(sweepAngle),
        center.dy + maxRadius * math.sin(sweepAngle),
      )
      ..arcTo(
        Rect.fromCircle(center: center, radius: maxRadius),
        sweepAngle,
        -0.5,
        false,
      )
      ..close();

    canvas.drawPath(sweepPath, armPaint);

    // Sweep line itself
    final linePaint = Paint()
      ..color = const Color(0x9900E676) // 60%
      ..strokeWidth = 2;
    canvas.drawLine(
      center,
      Offset(
        center.dx + maxRadius * math.cos(sweepAngle),
        center.dy + maxRadius * math.sin(sweepAngle),
      ),
      linePaint,
    );

    // Center dot
    canvas.drawCircle(
      center,
      3,
      Paint()..color = MilstdTheme.accentPrimary,
    );
  }

  @override
  bool shouldRepaint(covariant _RadarPainter oldDelegate) =>
      oldDelegate.sweepAngle != sweepAngle;
}
