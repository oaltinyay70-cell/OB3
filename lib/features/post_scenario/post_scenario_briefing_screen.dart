import 'package:flutter/material.dart';
import '../../core/theme/milstd_theme.dart';
import '../../engine/game_state.dart';

/// Post-Scenario Briefing Screen — matching post_mission.png mockup.
///
/// Layout:
///   MISSION COMPLETE / OPERATION NAME
///   ┌─ MISSION STATISTICS ─────────────┐
///   │  Targets Destroyed: 4/6          │
///   │  VP Earned: 14                   │
///   │  Time: 12:34                     │
///   ├─ PERFORMANCE RATING ─────────────┤
///   │  ★★★☆☆                          │
///   │  COMMENDABLE                     │
///   ├─ DRONE STATUS ───────────────────┤
///   │  BAYRAKTAR TB2                   │
///   │  Integrity: 5/7 ●●●●●○○         │
///   │  Sensors: -2 damage              │
///   │  RTB: SUCCESSFUL                 │
///   └──────────────────────────────────┘
///   [ PLAY AGAIN ]  [ MAIN MENU ]
class PostScenarioBriefingScreen extends StatelessWidget {
  const PostScenarioBriefingScreen({
    super.key,
    required this.finalState,
    required this.droneName,
    required this.onReturnToMenu,
    this.onReplay,
  });

  final GameState finalState;
  final String droneName;
  final VoidCallback onReturnToMenu;
  final VoidCallback? onReplay;

  _OutcomeType get _outcome {
    final reason = finalState.gameOverReason ?? '';
    if (reason.contains('estroyed')) return _OutcomeType.destroyed;
    if (reason.contains('fuel')) return _OutcomeType.forcedRtb;
    if (reason.contains('COMMS')) return _OutcomeType.destroyed;
    return _OutcomeType.complete;
  }

  /// Calculate star rating (1–5) based on VP earned.
  int get _starRating {
    final vp = finalState.totalVP;
    if (vp >= 25) return 5; // EXCEPTIONAL
    if (vp >= 18) return 4; // OUTSTANDING
    if (vp >= 12) return 3; // COMMENDABLE
    if (vp >= 6) return 2;  // SATISFACTORY
    return 1;               // MARGINAL
  }

  String get _ratingLabel {
    return switch (_starRating) {
      5 => 'EXCEPTIONAL',
      4 => 'OUTSTANDING',
      3 => 'COMMENDABLE',
      2 => 'SATISFACTORY',
      _ => 'MARGINAL',
    };
  }

  @override
  Widget build(BuildContext context) {
    final outcome = _outcome;
    final ds = finalState.droneState;
    final integrityRemaining = ds.maxIntegrity - ds.structuralDamage;

    return Scaffold(
      backgroundColor: MilstdTheme.backgroundPrimary,
      body: SafeArea(
        child: Column(
          children: [
            // Header: MISSION COMPLETE + OPERATION NAME
            Padding(
              padding: const EdgeInsets.only(top: 32),
              child: Column(
                children: [
                  Text(
                    outcome == _OutcomeType.complete
                        ? 'MISSION COMPLETE'
                        : outcome == _OutcomeType.destroyed
                            ? 'DRONE DESTROYED'
                            : 'FORCED RTB',
                    style: TextStyle(
                      fontFamily: 'Rajdhani',
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: outcome == _OutcomeType.complete
                          ? MilstdTheme.accentPrimary
                          : outcome == _OutcomeType.destroyed
                              ? MilstdTheme.accentDanger
                              : MilstdTheme.accentWarm,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'OPERATION IRON VIPER',
                    style: TextStyle(
                      fontFamily: 'IBMPlexSans',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: MilstdTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Stats sections
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: MilstdTheme.backgroundSecondary,
                    borderRadius: const BorderRadius.all(MilstdTheme.radiusMd),
                    border: Border.all(
                        color: MilstdTheme.borderDefault, width: 1),
                  ),
                  child: Column(
                    children: [
                      // MISSION STATISTICS
                      _SectionHeader('MISSION STATISTICS'),
                      _DataRow('Targets Destroyed',
                          '${finalState.destroyedTargets.length}/${finalState.destroyedTargets.length + 2}',
                          valueColor: MilstdTheme.accentPrimary),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Center(
                          child: Text(
                            'VP Earned: ${finalState.totalVP.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontFamily: 'Rajdhani',
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                              color: MilstdTheme.textPrimary,
                            ),
                          ),
                        ),
                      ),
                      _DataRow('Time', '${finalState.cycleNumber}:00'),
                      const Divider(
                          color: MilstdTheme.borderSubtle, height: 1),

                      // PERFORMANCE RATING
                      _SectionHeader('PERFORMANCE RATING'),
                      const SizedBox(height: 8),
                      // Stars
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (i) {
                          return Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 3),
                            child: Icon(
                              i < _starRating
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              size: 40,
                              color: i < _starRating
                                  ? MilstdTheme.accentWarm
                                  : MilstdTheme.textMuted,
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 6),
                      Center(
                        child: Text(
                          _ratingLabel,
                          style: const TextStyle(
                            fontFamily: 'Rajdhani',
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: MilstdTheme.accentPrimary,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Divider(
                          color: MilstdTheme.borderSubtle, height: 1),

                      // DRONE STATUS
                      _SectionHeader('DRONE STATUS'),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        child: Center(
                          child: Text(
                            droneName.toUpperCase(),
                            style: const TextStyle(
                              fontFamily: 'Rajdhani',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: MilstdTheme.textPrimary,
                            ),
                          ),
                        ),
                      ),
                      // Integrity dots
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Integrity: ',
                              style: const TextStyle(
                                fontFamily: 'IBMPlexSans',
                                fontSize: 13,
                                color: MilstdTheme.textSecondary,
                              ),
                            ),
                            Text(
                              '$integrityRemaining/${ds.maxIntegrity}',
                              style: TextStyle(
                                fontFamily: 'IBMPlexMono',
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: integrityRemaining > ds.maxIntegrity / 2
                                    ? MilstdTheme.accentPrimary
                                    : MilstdTheme.accentWarm,
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Dots
                            ...List.generate(ds.maxIntegrity, (i) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 2),
                                child: Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: i < integrityRemaining
                                        ? MilstdTheme.accentWarm
                                        : MilstdTheme.backgroundTertiary,
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                      _DataRow('Sensors',
                          ds.sensorsDamage > 0
                              ? '-${ds.sensorsDamage} damage'
                              : 'No damage',
                          valueColor: ds.sensorsDamage > 0
                              ? MilstdTheme.accentWarm
                              : MilstdTheme.textSecondary),
                      _DataRow(
                        'RTB',
                        ds.isDestroyed ? 'FAILED' : 'SUCCESSFUL',
                        valueColor: ds.isDestroyed
                            ? MilstdTheme.accentDanger
                            : MilstdTheme.accentPrimary,
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Action buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Row(
                children: [
                  if (onReplay != null)
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: onReplay,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: MilstdTheme.surface,
                            foregroundColor: MilstdTheme.textPrimary,
                            side: const BorderSide(
                                color: MilstdTheme.borderDefault, width: 1),
                            textStyle: const TextStyle(
                              fontFamily: 'Rajdhani',
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                            shape: const RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.all(MilstdTheme.radiusSm),
                            ),
                          ),
                          child: const Text('PLAY AGAIN'),
                        ),
                      ),
                    ),
                  if (onReplay != null) const SizedBox(width: 10),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton(
                        onPressed: onReturnToMenu,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: MilstdTheme.textSecondary,
                          side: const BorderSide(
                              color: MilstdTheme.borderDefault, width: 1),
                          textStyle: const TextStyle(
                            fontFamily: 'Rajdhani',
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                          shape: const RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.all(MilstdTheme.radiusSm),
                          ),
                        ),
                        child: const Text('MAIN MENU'),
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

// =============================================================================
// Sub-widgets
// =============================================================================

enum _OutcomeType { complete, destroyed, forcedRtb }

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: MilstdTheme.borderSubtle, width: 0.5),
        ),
      ),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(
            fontFamily: 'IBMPlexSans',
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: MilstdTheme.accentPrimary,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }
}

class _DataRow extends StatelessWidget {
  const _DataRow(this.label, this.value, {this.valueColor});
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontFamily: 'IBMPlexSans',
              fontSize: 13,
              color: MilstdTheme.textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'IBMPlexMono',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: valueColor ?? MilstdTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
