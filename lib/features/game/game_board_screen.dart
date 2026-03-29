import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/milstd_theme.dart';
import '../../models/game_enums.dart';
import '../../engine/game_state.dart';
import '../../shared/widgets/game_board_progress.dart';
import 'bloc/game_bloc.dart';

/// Game Board Screen (S05) — ux-architecture.md §S05
///
/// The primary game screen displaying the B0–B5 loop.
/// Layout zones (portrait):
///   TOP BAR — drone name, cycle#, VP score
///   PROGRESS BAR — B0→B5 stepper (per-box colors)
///   STATUS PANEL — fuel gauge, SI/SEN/COM/VIS ribbon, altitude
///   MAIN ACTION AREA — phase-specific content (scrollable)
///   ACTION LOG — last 3 lines
///   ACTION BUTTONS — context-sensitive
class GameBoardScreen extends StatelessWidget {
  const GameBoardScreen({
    super.key,
    required this.droneName,
    this.onGameOver,
  });

  final String droneName;
  final void Function(GameState finalState)? onGameOver;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<GameBloc, GameState>(
      listener: (context, state) {
        if (state.isGameOver && onGameOver != null) {
          onGameOver!(state);
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: MilstdTheme.backgroundPrimary,
          body: SafeArea(
            child: Column(
              children: [
                // ── TOP BAR ──
                _TopBar(
                  droneName: droneName,
                  cycleNumber: state.cycleNumber,
                  totalVP: state.totalVP,
                ),

                // ── PROGRESS BAR ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: GameBoardProgress(
                    currentPhaseIndex: _phaseToIndex(state.phase),
                  ),
                ),

                // ── FUEL GAUGE (full-width, thick, color-changing) ──
                _FuelGauge(state: state),

                // ── STATUS RIBBON (evenly spaced) ──
                _StatusRibbon(state: state),

                const Divider(
                    color: MilstdTheme.borderSubtle, height: 1, indent: 16, endIndent: 16),

                // ── MAIN ACTION AREA ──
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: _MainActionArea(state: state),
                  ),
                ),

                // ── ACTION LOG ──
                _ActionLog(entries: state.gameLog),

                // ── ACTION BUTTONS ──
                _ActionButtons(state: state),
              ],
            ),
          ),
        );
      },
    );
  }

  static int _phaseToIndex(GamePhase phase) {
    return switch (phase) {
      GamePhase.b0InTransit => 0,
      GamePhase.b1Search => 1,
      GamePhase.b2TargetAcq => 2,
      GamePhase.b3Positioning => 3,
      GamePhase.b4Attack => 4,
      GamePhase.b5Evasion => 5,
      _ => 0,
    };
  }
}

// =============================================================================
// TOP BAR
// =============================================================================

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.droneName,
    required this.cycleNumber,
    required this.totalVP,
  });

  final String droneName;
  final int cycleNumber;
  final double totalVP;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      color: MilstdTheme.backgroundSecondary,
      child: Row(
        children: [
          // Drone icon placeholder — will use per-drone icon from DB
          const Icon(Icons.flight, size: 16, color: MilstdTheme.accentSecondary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              droneName.toUpperCase(),
              style: const TextStyle(
                fontFamily: 'Rajdhani',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: MilstdTheme.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Cycle counter
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: MilstdTheme.backgroundTertiary,
              borderRadius: const BorderRadius.all(MilstdTheme.radiusXs),
            ),
            child: Text(
              'CYCLE $cycleNumber',
              style: const TextStyle(
                fontFamily: 'IBMPlexMono',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: MilstdTheme.accentSecondary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // VP Score
          Row(
            children: [
              const Icon(Icons.star, size: 14, color: MilstdTheme.accentWarm),
              const SizedBox(width: 2),
              Text(
                '${totalVP.toStringAsFixed(0)} VP',
                style: const TextStyle(
                  fontFamily: 'IBMPlexMono',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: MilstdTheme.accentWarm,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// FUEL GAUGE — full-width, thick, color-changing (#3, #4)
// =============================================================================

class _FuelGauge extends StatelessWidget {
  const _FuelGauge({required this.state});
  final GameState state;

  /// Color transitions: green → yellow → orange → red as fuel depletes
  Color _fuelColor(double fraction) {
    if (fraction > 0.6) return const Color(0xFF10B981); // green
    if (fraction > 0.35) return const Color(0xFFF59E0B); // amber
    if (fraction > 0.15) return const Color(0xFFF97316); // orange
    return const Color(0xFFEF4444); // red — critical
  }

  @override
  Widget build(BuildContext context) {
    final ds = state.droneState;
    final fraction = ds.fuelFraction;

    final color = _fuelColor(fraction);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 0, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Label
          Text(
            'FUEL',
            style: TextStyle(
              fontFamily: 'IBMPlexSans',
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(width: 12),
          // Gauge bar
          Expanded(
            child: SizedBox(
              height: 14,
              child: Stack(
                children: [
                // Background track
                Container(
                  decoration: BoxDecoration(
                    color: MilstdTheme.backgroundTertiary,
                    border: Border.all(
                      color: MilstdTheme.borderSubtle,
                      width: 0.5,
                    ),
                  ),
                ),
                // Fill
                FractionallySizedBox(
                  widthFactor: fraction.clamp(0.0, 1.0),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          color.withValues(alpha: 0.9),
                          color,
                        ],
                      ),
                    ),
                  ),
                ),
                // Tick marks every 10%
                Row(
                  children: List.generate(9, (i) {
                    return Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border(
                            right: BorderSide(
                              color: MilstdTheme.backgroundPrimary.withValues(alpha: 0.4),
                              width: 1,
                            ),
                          ),
                        ),
                      ),
                    );
                  })..add(const Expanded(child: SizedBox())),
                ),
              ],
            ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// STATUS RIBBON — evenly spaced stats (#5)
// =============================================================================

class _StatusRibbon extends StatelessWidget {
  const _StatusRibbon({required this.state});
  final GameState state;

  @override
  Widget build(BuildContext context) {
    final ds = state.droneState;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          _IntegrityBar(
            damage: ds.structuralDamage,
            maxIntegrity: ds.maxIntegrity,
          ),
          _RibbonDivider(),
          _RibbonStat(
            label: 'SENSORS',
            value: '${ds.sensorsDamage}',
            color: ds.sensorsDamage > 0
                ? MilstdTheme.statusWarning
                : MilstdTheme.textSecondary,
            icon: Icons.radar,
          ),
          _RibbonDivider(),
          _RibbonStat(
            label: 'COMMS',
            value: '${ds.commsDamage}',
            color: ds.commsDamage > 2
                ? MilstdTheme.statusCritical
                : ds.commsDamage > 0
                    ? MilstdTheme.statusWarning
                    : MilstdTheme.textSecondary,
            icon: Icons.cell_tower,
          ),
          _RibbonDivider(),
          _RibbonStat(
            label: 'VIS/RCS',
            value: '${ds.vis}',
            color: ds.vis > 3
                ? MilstdTheme.statusCritical
                : MilstdTheme.textSecondary,
            icon: Icons.visibility,
          ),
        ],
      ),
    );
  }
}

class _RibbonStat extends StatelessWidget {
  const _RibbonStat({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'IBMPlexSans',
              fontSize: 8,
              fontWeight: FontWeight.w600,
              color: MilstdTheme.textMuted,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 3),
              Text(
                value,
                style: TextStyle(
                  fontFamily: 'IBMPlexMono',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RibbonDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 24,
      color: MilstdTheme.borderSubtle,
    );
  }
}

/// Chevron-based integrity display. More chevrons = more SI.
/// Chevrons dissolve from right-to-left as the drone takes damage.
class _IntegrityBar extends StatelessWidget {
  const _IntegrityBar({required this.damage, required this.maxIntegrity});
  final int damage;
  final int maxIntegrity;

  @override
  Widget build(BuildContext context) {
    final remaining = (maxIntegrity - damage).clamp(0, maxIntegrity);
    final fraction = maxIntegrity > 0 ? remaining / maxIntegrity : 1.0;

    // 1 chevron per 25 SI, minimum 3, maximum 18
    final totalChevrons = (maxIntegrity / 25).ceil().clamp(3, 18);
    // How many chevrons are "alive" (fractional for partial)
    final aliveChevrons = fraction * totalChevrons;

    final color = fraction > 0.5
        ? MilstdTheme.statusOk
        : fraction > 0.25
            ? MilstdTheme.statusWarning
            : MilstdTheme.statusCritical;

    return Expanded(
      child: Column(
        children: [
          const Text(
            'INTEGRITY',
            style: TextStyle(
              fontFamily: 'IBMPlexSans',
              fontSize: 8,
              fontWeight: FontWeight.w600,
              color: MilstdTheme.textMuted,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 3),
          SizedBox(
            height: 10,
            child: Row(
              children: List.generate(totalChevrons, (i) {
                // Determine opacity for this chevron
                double opacity;
                if (i < aliveChevrons.floor()) {
                  opacity = 1.0; // fully alive
                } else if (i < aliveChevrons) {
                  opacity = aliveChevrons - i; // partially alive (fractional)
                } else {
                  opacity = 0.12; // dead — ghost outline
                }

                return Expanded(
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 400),
                    opacity: opacity,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 0.5),
                      decoration: BoxDecoration(
                        color: opacity > 0.15 ? color : Colors.transparent,
                        border: Border.all(
                          color: opacity > 0.15
                              ? color.withValues(alpha: 0.6)
                              : MilstdTheme.borderDefault.withValues(alpha: 0.3),
                          width: 0.5,
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(1),
                          topRight: Radius.circular(3),
                          bottomRight: Radius.circular(1),
                          bottomLeft: Radius.circular(3),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact loadout row showing weapon names + remaining counts.
class _LoadoutRow extends StatelessWidget {
  const _LoadoutRow({required this.state});
  final GameState state;

  @override
  Widget build(BuildContext context) {
    final slots = state.droneState.loadout;
    if (slots.isEmpty) return const SizedBox.shrink();

    final allItems = slots.expand((slot) {
      return List.generate(slot.initialQuantity, (index) {
        final isExpended = index >= slot.quantity;
        final color = isExpended ? MilstdTheme.textMuted : MilstdTheme.accentPrimary;
        final bgColor = isExpended ? Colors.transparent : MilstdTheme.accentPrimary.withValues(alpha: 0.1);
        final borderColor = isExpended ? MilstdTheme.borderDefault : MilstdTheme.accentPrimary.withValues(alpha: 0.5);

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          decoration: BoxDecoration(
            color: bgColor,
            border: Border.all(color: borderColor, width: 1),
            borderRadius: const BorderRadius.all(MilstdTheme.radiusXs),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.inventory_2_outlined, size: 12, color: color),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  slot.weapon.name,
                  style: TextStyle(
                    fontFamily: 'IBMPlexMono',
                    fontSize: 10,
                    fontWeight: isExpended ? FontWeight.w400 : FontWeight.w600,
                    color: color,
                    decoration: isExpended ? TextDecoration.lineThrough : null,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      });
    }).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final count = allItems.length;
        if (count == 0) return const SizedBox.shrink();

        int cols = 4;
        if (count <= 4) cols = count;
        else if (count == 5 || count == 6) cols = 3;
        else cols = 4;

        const double spacing = 8.0;
        final double itemWidth = ((constraints.maxWidth - (spacing * (cols - 1))) / cols).floorToDouble();

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          alignment: WrapAlignment.center,
          children: allItems.map((child) => SizedBox(width: itemWidth, child: child)).toList(),
        );
      },
    );
  }
}

// =============================================================================
// MAIN ACTION AREA — phase-specific content
// =============================================================================

class _MainActionArea extends StatelessWidget {
  const _MainActionArea({required this.state});
  final GameState state;

  @override
  Widget build(BuildContext context) {
    if (state.isGameOver) {
      return _GameOverContent(reason: state.gameOverReason ?? 'Game Over');
    }

    final phaseContent = switch (state.phase) {
      GamePhase.setup => const _SetupContent(),
      GamePhase.b0InTransit => const _B0Content(),
      GamePhase.b1Search => _B1Content(state: state),
      GamePhase.b2TargetAcq => _B2Content(state: state),
      GamePhase.b3Positioning => _B3Content(state: state),
      GamePhase.b4Attack => _B4Content(state: state),
      GamePhase.b5Evasion => _B5Content(state: state),
      _ => const _SetupContent(),
    };

    if (state.phase == GamePhase.setup) return phaseContent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AltitudeSelector(
          state: state,
          locked: (state.phase != GamePhase.b1Search && state.phase != GamePhase.b3Positioning && state.phase != GamePhase.b4Attack) ||
                  (state.phase == GamePhase.b1Search && state.combatCardDrawn) ||
                  state.altitudeChangedThisPhase,
        ),
        const SizedBox(height: 8),
        _LoadoutRow(state: state),
        const SizedBox(height: 8),
        phaseContent,
      ],
    );
  }
}

class _SetupContent extends StatelessWidget {
  const _SetupContent();
  @override
  Widget build(BuildContext context) {
    return const _PhaseHeader(
      title: 'READY FOR LAUNCH',
      subtitle: 'Tap START GAME to begin your mission.',
      icon: Icons.rocket_launch,
      color: MilstdTheme.accentPrimary,
    );
  }
}

class _B0Content extends StatelessWidget {
  const _B0Content();
  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

class _B1Content extends StatelessWidget {
  const _B1Content({required this.state});
  final GameState state;

  @override
  Widget build(BuildContext context) {
    if (state.currentCombatCard == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (state.currentCombatCard != null)
          _CombatCardVisual(
            cardName: state.currentCombatCard!.cardName,
            instruction: state.currentCombatCard!.instructions,
            effectResult: state.lastCombatEffect,
            imageBytes: state.currentCombatCard!.imageBytes,
          ),
      ],
    );
  }
}

class _B2Content extends StatelessWidget {
  const _B2Content({required this.state});
  final GameState state;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),
        if (state.currentTarget != null || state.currentThreat != null)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (state.currentTarget != null)
                Expanded(
                  child: _CardImageDisplay(
                    imageBytes: state.currentTarget!.imageBytes,
                    fallbackTitle: state.currentTarget!.cardName,
                    fallbackBody: '${state.currentTarget!.targetType.dbValue}\nVP: ${state.currentTarget!.vp}',
                    fallbackBorderColor: MilstdTheme.accentSecondary,
                    fallbackHeaderLabel: 'TARGET',
                  ),
                ),
              if (state.currentTarget != null && state.currentThreat != null)
                const SizedBox(width: 8),
              if (state.currentThreat != null)
                Expanded(
                  child: _CardImageDisplay(
                    imageBytes: state.currentThreat!.imageBytes,
                    fallbackTitle: state.currentThreat!.cardName,
                    fallbackBody: state.currentThreat!.subCategory,
                    fallbackBorderColor: MilstdTheme.accentDanger,
                    fallbackHeaderLabel: 'THREAT',
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

class _B3Content extends StatelessWidget {
  const _B3Content({required this.state});
  final GameState state;

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

/// B4 — Attack screen: Height → Weapon → Attack Mode → Execute
class _B4Content extends StatelessWidget {
  const _B4Content({required this.state});
  final GameState state;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<GameBloc>();
    final alt = state.droneState.altitude;

    // Determine which modes are available at current altitude
    final bool canStandOff = alt == Altitude.medium || alt == Altitude.high;
    final bool canCloseIn = alt == Altitude.vlow || alt == Altitude.low;
    final bool canFoLaze = alt == Altitude.vlow || alt == Altitude.low || alt == Altitude.medium; // FO/Laze: LOW + MEDIUM only

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _PhaseHeader(
          title: 'B4 — DRONE ATTACK',
          subtitle: 'Select height, weapon, and attack mode.',
          icon: Icons.local_fire_department,
          color: Color(0xFFEF4444),
        ),
        const SizedBox(height: 12),

        // STEP 1: Height instruction
        const _SectionLabel2('① SELECT HEIGHT'),
        const SizedBox(height: 4),
        Text(
          'Current: ${alt.name.toUpperCase()} — Use altitude bar above to change (2F↑ / 1F↓)',
          style: const TextStyle(
            fontFamily: 'IBMPlexSans',
            fontSize: 12,
            color: MilstdTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 16),

        // STEP 2: Weapon selection
        const _SectionLabel2('② SELECT WEAPON'),
        const SizedBox(height: 6),
        if (state.droneState.loadout.any((s) => s.hasAmmo))
          ...state.droneState.loadout
              .where((slot) => slot.hasAmmo)
              .map((slot) {
                // A weapon is available if it can fire at the current altitude
                final canUseAlt = slot.weapon.canFireAtAltitude(alt);
                // Also check if weapon can engage the current target type
                final canEngageTarget = state.currentTarget == null ||
                    slot.weapon.canEngageTargetType(state.currentTarget!.targetType);
                final isAvailable = canUseAlt && canEngageTarget;
                final isSelected = state.selectedWeapon?.id == slot.weapon.id;

                // Derive the modes this weapon supports
                final modes = slot.weapon.allowedAttackModes
                    .map((m) => m.label)
                    .join(' / ');

                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: GestureDetector(
                    onTap: () {
                      if (!canUseAlt) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(
                            '${slot.weapon.name} cannot fire at ${alt.name.toUpperCase()}',
                            style: const TextStyle(fontFamily: 'IBMPlexSans'),
                          ),
                          backgroundColor: MilstdTheme.statusCritical,
                          duration: const Duration(seconds: 2),
                        ));
                        return;
                      }
                      if (!canEngageTarget) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(
                            '${slot.weapon.name} cannot engage ${state.currentTarget?.cardName ?? 'this target'}',
                            style: const TextStyle(fontFamily: 'IBMPlexSans'),
                          ),
                          backgroundColor: MilstdTheme.statusCritical,
                          duration: const Duration(seconds: 2),
                        ));
                        return;
                      }
                      // When weapon is selected, auto-pick the first compatible mode
                      final weaponModes = slot.weapon.allowedAttackModes;
                      AttackMode? autoMode;
                      for (final m in weaponModes) {
                        if (m == AttackMode.standOff && canStandOff) { autoMode = m; break; }
                        if (m == AttackMode.closeIn && canCloseIn) { autoMode = m; break; }
                      }
                      if (autoMode != null) {
                        bloc.add(GameSelectAttack(mode: autoMode, weapon: slot.weapon));
                      } else {
                        // Weapon supports modes not available at this altitude
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(
                            '${slot.weapon.name} modes ($modes) not available at ${alt.name.toUpperCase()}',
                            style: const TextStyle(fontFamily: 'IBMPlexSans'),
                          ),
                          backgroundColor: MilstdTheme.statusWarning,
                          duration: const Duration(seconds: 2),
                        ));
                      }
                    },
                    child: Opacity(
                      opacity: isAvailable ? 1.0 : 0.35,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFEF4444).withValues(alpha: 0.12)
                              : MilstdTheme.surface,
                          borderRadius: const BorderRadius.all(MilstdTheme.radiusSm),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFFEF4444)
                                : MilstdTheme.borderDefault,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    slot.weapon.name,
                                    style: const TextStyle(
                                      fontFamily: 'Rajdhani',
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: MilstdTheme.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    modes,
                                    style: TextStyle(
                                      fontFamily: 'IBMPlexSans',
                                      fontSize: 10,
                                      color: MilstdTheme.textMuted.withValues(alpha: 0.7),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: MilstdTheme.accentPrimary.withValues(alpha: 0.15),
                                borderRadius: const BorderRadius.all(MilstdTheme.radiusXs),
                              ),
                              child: Text(
                                '×${slot.quantity}',
                                style: const TextStyle(
                                  fontFamily: 'IBMPlexMono',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: MilstdTheme.accentPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
        const SizedBox(height: 16),

        // STEP 3: Attack mode (highlighted based on altitude availability)
        const _SectionLabel2('③ ATTACK MODE'),
        const SizedBox(height: 6),
        Row(
          children: [
            for (final mode in AttackMode.values) ...[
              Expanded(
                child: Builder(builder: (context) {
                  final bool modeAvailable = switch (mode) {
                    AttackMode.standOff => canStandOff,
                    AttackMode.closeIn => canCloseIn,
                    AttackMode.foLaze => canFoLaze, // HIGH altitude disables FO/Laze
                  };
                  final isSelected = state.selectedAttackMode == mode;

                  // Check if selected weapon supports this mode
                  final weaponSupportsMode = state.selectedWeapon == null ||
                      state.selectedWeapon!.canFireInMode(mode);

                  final isUsable = modeAvailable && weaponSupportsMode;

                  return GestureDetector(
                    onTap: () {
                      if (!modeAvailable) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(
                            '${mode.label} not available at ${alt.name.toUpperCase()}',
                            style: const TextStyle(fontFamily: 'IBMPlexSans'),
                          ),
                          backgroundColor: MilstdTheme.statusWarning,
                          duration: const Duration(seconds: 2),
                        ));
                        return;
                      }
                      if (!weaponSupportsMode && state.selectedWeapon != null) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(
                            '${state.selectedWeapon!.name} cannot use ${mode.label} mode',
                            style: const TextStyle(fontFamily: 'IBMPlexSans'),
                          ),
                          backgroundColor: MilstdTheme.statusWarning,
                          duration: const Duration(seconds: 2),
                        ));
                        return;
                      }
                      if (mode == AttackMode.foLaze) {
                        bloc.add(GameSelectAttack(mode: mode, weapon: null));
                      } else if (state.selectedWeapon != null) {
                        bloc.add(GameSelectAttack(mode: mode, weapon: state.selectedWeapon));
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFEF4444).withValues(alpha: 0.2)
                            : isUsable
                                ? const Color(0xFF22C55E).withValues(alpha: 0.12)
                                : MilstdTheme.surface.withValues(alpha: 0.3),
                        borderRadius: const BorderRadius.all(MilstdTheme.radiusSm),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFFEF4444)
                              : isUsable
                                  ? const Color(0xFF22C55E).withValues(alpha: 0.5)
                                  : MilstdTheme.borderDefault.withValues(alpha: 0.3),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Text(
                        mode.label.toUpperCase(),
                        style: TextStyle(
                          fontFamily: 'Rajdhani',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? const Color(0xFFEF4444)
                              : isUsable
                                  ? const Color(0xFF22C55E)
                                  : MilstdTheme.textMuted.withValues(alpha: 0.4),
                        ),
                      ),
                    ),
                  );
                }),
              ),
              if (mode != AttackMode.values.last) const SizedBox(width: 6),
            ],
          ],
        ),
      ],
    );
  }
}

class _B5Content extends StatelessWidget {
  const _B5Content({required this.state});
  final GameState state;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _PhaseHeader(
          title: 'B5 — EVASIVE ACTION',
          subtitle: 'Counterfire resolution and commander decision.',
          icon: Icons.shield,
          color: Color(0xFFF97316),
        ),
        const SizedBox(height: 12),

        // Attack result from B4 (shown first in EGRESS)
        if (state.lastAttackResult != null) ...[
          const _SectionLabel2('ATTACK RESULT'),
          const SizedBox(height: 6),
          _ResultBanner(
            text: state.lastAttackResult!,
            isHit: state.lastAttackResult!.contains('HIT'),
          ),
          const SizedBox(height: 12),
        ],

        // Evasion result
        if (state.lastEvasionResult != null) ...[
          const _SectionLabel2('COUNTERFIRE RESULT'),
          const SizedBox(height: 6),
          _ResultBanner(
            text: state.lastEvasionResult!,
            isHit: state.lastEvasionResult!.contains('damage'),
          ),
        ],
      ],
    );
  }
}

class _GameOverContent extends StatelessWidget {
  const _GameOverContent({required this.reason});
  final String reason;

  @override
  Widget build(BuildContext context) {
    final isDestroyed = reason.contains('estroyed');
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isDestroyed ? Icons.dangerous : Icons.home,
            size: 64,
            color: isDestroyed ? MilstdTheme.accentDanger : MilstdTheme.accentWarm,
          ),
          const SizedBox(height: 16),
          Text(
            isDestroyed ? 'DRONE DESTROYED' : 'MISSION COMPLETE',
            style: TextStyle(
              fontFamily: 'Rajdhani',
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: isDestroyed ? MilstdTheme.accentDanger : MilstdTheme.accentPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            reason,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'IBMPlexSans',
              fontSize: 14,
              color: MilstdTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// SHARED SUB-WIDGETS
// =============================================================================

class _PhaseHeader extends StatelessWidget {
  const _PhaseHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: const BorderRadius.all(MilstdTheme.radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, size: 28, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Rajdhani',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontFamily: 'IBMPlexSans',
                    fontSize: 12,
                    color: MilstdTheme.textSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CardDisplay extends StatelessWidget {
  const _CardDisplay({
    required this.title,
    required this.body,
    required this.borderColor,
    this.headerLabel,
  });
  final String title;
  final String body;
  final Color borderColor;
  final String? headerLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: MilstdTheme.surface,
        borderRadius: const BorderRadius.all(MilstdTheme.radiusMd),
        border: Border.all(color: borderColor.withValues(alpha: 0.6), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (headerLabel != null) ...[
            Text(
              headerLabel!,
              style: TextStyle(
                fontFamily: 'IBMPlexSans',
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: borderColor,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 4),
          ],
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Rajdhani',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: MilstdTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            body,
            style: const TextStyle(
              fontFamily: 'IBMPlexSans',
              fontSize: 12,
              color: MilstdTheme.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

/// Card display that prefers an asset image, falling back to _CardDisplay text.
class _CardImageDisplay extends StatelessWidget {
  const _CardImageDisplay({
    required this.fallbackTitle,
    required this.fallbackBody,
    required this.fallbackBorderColor,
    this.fallbackHeaderLabel,
    this.imageBytes,
  });
  final String fallbackTitle;
  final String fallbackBody;
  final Color fallbackBorderColor;
  final String? fallbackHeaderLabel;
  final Uint8List? imageBytes;

  @override
  Widget build(BuildContext context) {
    // Tier 1: Try DB BLOB image
    if (imageBytes != null && imageBytes!.isNotEmpty) {
      return ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(8)),
        child: Image.memory(
          imageBytes!,
          width: double.infinity,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => _CardDisplay(
            title: fallbackTitle,
            body: fallbackBody,
            borderColor: fallbackBorderColor,
            headerLabel: fallbackHeaderLabel,
          ),
        ),
      );
    }
    // Tier 2: Styled text fallback
    return _CardDisplay(
      title: fallbackTitle,
      body: fallbackBody,
      borderColor: fallbackBorderColor,
      headerLabel: fallbackHeaderLabel,
    );
  }
}

class _AltitudeSelector extends StatelessWidget {
  const _AltitudeSelector({required this.state, this.locked = false});
  final GameState state;
  final bool locked;

  void _showLockedPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: MilstdTheme.backgroundSecondary,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          side: BorderSide(color: MilstdTheme.borderSubtle),
        ),
        title: const Text(
          'ALTITUDE LOCKED',
          style: TextStyle(
            fontFamily: 'Rajdhani', fontSize: 18, fontWeight: FontWeight.w700,
            color: MilstdTheme.accentWarm,
          ),
        ),
        content: Text(
          state.altitudeChangedThisPhase
              ? 'Altitude change limit reached.\n\nYou can only change altitude once per phase.'
              : 'Altitude cannot be changed after drawing a combat card.\n\nYou must make altitude changes BEFORE drawing.',
          style: const TextStyle(
            fontFamily: 'IBMPlexSans', fontSize: 13, color: MilstdTheme.textSecondary, height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK', style: TextStyle(fontFamily: 'Rajdhani', fontWeight: FontWeight.w600, color: MilstdTheme.accentPrimary)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allowed = state.droneState.allowedAltitudes;
    final current = state.droneState.altitude;

    return Row(
      children: [
        if (locked) ...const [
          Icon(Icons.lock, size: 10, color: MilstdTheme.textMuted),
          SizedBox(width: 8),
        ],
        for (final alt in Altitude.values.reversed) ...[
          Expanded(
            child: GestureDetector(
              onTap: locked
                  ? () => _showLockedPopup(context)
                  : (allowed.contains(alt)
                      ? () => context.read<GameBloc>().add(GameChangeAltitude(alt))
                      : null),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: current == alt
                      ? (locked
                          ? MilstdTheme.accentPrimary.withValues(alpha: 0.1)
                          : MilstdTheme.accentPrimary.withValues(alpha: 0.2))
                      : MilstdTheme.surface,
                  borderRadius: const BorderRadius.all(MilstdTheme.radiusSm),
                  border: Border.all(
                    color: current == alt
                        ? (locked ? MilstdTheme.textMuted : MilstdTheme.accentPrimary)
                        : allowed.contains(alt) && !locked
                            ? MilstdTheme.borderDefault
                            : MilstdTheme.borderSubtle,
                    width: current == alt ? 2 : 1,
                  ),
                ),
                child: Text(
                  alt.name.toUpperCase(),
                  style: TextStyle(
                    fontFamily: 'IBMPlexMono',
                    fontSize: 9,
                    fontWeight: current == alt ? FontWeight.w700 : FontWeight.w500,
                    color: current == alt
                        ? (locked ? MilstdTheme.textMuted : MilstdTheme.accentPrimary)
                        : locked
                            ? MilstdTheme.textMuted
                            : allowed.contains(alt)
                                ? MilstdTheme.textSecondary
                                : MilstdTheme.textMuted,
                  ),
                ),
              ),
            ),
          ),
          if (alt != Altitude.values.first) const SizedBox(width: 4),
        ],
      ],
    );
  }
}

/// Visual display for a drawn+resolved combat card.
class _CombatCardVisual extends StatelessWidget {
  const _CombatCardVisual({
    required this.cardName,
    required this.instruction,
    this.effectResult,
    this.imageBytes,
  });
  final String cardName;
  final String instruction;
  final String? effectResult;
  final Uint8List? imageBytes;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Card image: prefer asset file → DB BLOB → text fallback
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 280),
          child: ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(8)),
            child: _buildCardImage(),
          ),
        ),
        // Effect result badge (compact)
        if (effectResult != null) ...[
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF00E676).withValues(alpha: 0.12),
              borderRadius: const BorderRadius.all(Radius.circular(4)),
              border: Border.all(color: const Color(0xFF00E676).withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, size: 12, color: Color(0xFF00E676)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    effectResult!,
                    style: const TextStyle(
                      fontFamily: 'Rajdhani', fontSize: 11, fontWeight: FontWeight.w600,
                      color: Color(0xFF00E676),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCardImage() {
    // 1st priority: DB BLOB image
    if (imageBytes != null && imageBytes!.isNotEmpty) {
      return Image.memory(
        imageBytes!,
        width: double.infinity,
        fit: BoxFit.contain,
      );
    }
    // 2nd: text fallback
    return _buildFallback();
  }

  Widget _buildFallback() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0A1A0F),
        borderRadius: const BorderRadius.all(MilstdTheme.radiusMd),
        border: Border.all(color: const Color(0xFF00E676).withValues(alpha: 0.5), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'COMBAT CARD',
            style: TextStyle(
              fontFamily: 'IBMPlexSans', fontSize: 9, fontWeight: FontWeight.w700,
              color: Color(0xFF00E676), letterSpacing: 2.0,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            cardName.toUpperCase(),
            style: const TextStyle(
              fontFamily: 'Rajdhani', fontSize: 20, fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            instruction,
            style: const TextStyle(
              fontFamily: 'IBMPlexSans', fontSize: 12, color: Color(0xFF8BA992), height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}


class _ResultBanner extends StatelessWidget {
  const _ResultBanner({required this.text, required this.isHit});
  final String text;
  final bool isHit;

  @override
  Widget build(BuildContext context) {
    final color = isHit ? MilstdTheme.accentDanger : MilstdTheme.accentPrimary;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: const BorderRadius.all(MilstdTheme.radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'Rajdhani',
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}


class _SectionLabel2 extends StatelessWidget {
  const _SectionLabel2(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'IBMPlexSans',
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: MilstdTheme.textSecondary,
        letterSpacing: 1.5,
      ),
    );
  }
}

// =============================================================================
// ACTION LOG
// =============================================================================

class _ActionLog extends StatelessWidget {
  const _ActionLog({required this.entries});
  final List<String> entries;

  @override
  Widget build(BuildContext context) {
    final visible = entries.length > 3
        ? entries.sublist(entries.length - 3)
        : entries;

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: const BoxDecoration(
        color: MilstdTheme.backgroundSecondary,
        border: Border(
          top: BorderSide(color: MilstdTheme.borderSubtle, width: 1),
        ),
      ),
      child: ListView(
        children: visible.map((e) => Text(
          '> $e',
          style: const TextStyle(
            fontFamily: 'IBMPlexMono',
            fontSize: 9,
            color: MilstdTheme.textMuted,
            height: 1.4,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        )).toList(),
      ),
    );
  }
}

// =============================================================================
// ACTION BUTTONS — context-sensitive per phase
// =============================================================================

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({required this.state});
  final GameState state;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<GameBloc>();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: const BoxDecoration(
        color: MilstdTheme.backgroundSecondary,
        border: Border(
          top: BorderSide(color: MilstdTheme.borderSubtle, width: 1),
        ),
      ),
      child: Row(
        children: _buildButtons(bloc, state),
      ),
    );
  }

  List<Widget> _buildButtons(GameBloc bloc, GameState state) {
    if (state.isGameOver) {
      return [const Expanded(child: SizedBox())];
    }

    return switch (state.phase) {
      GamePhase.setup => [
        Expanded(child: _PrimaryBtn('START GAME', () => bloc.add(const GameStarted()))),
      ],
      GamePhase.b0InTransit => [
        Expanded(child: _PrimaryBtn('PROCESS TRANSIT', () => bloc.add(const GameProcessB0()))),
      ],
      GamePhase.b1Search => [
        if (!state.combatCardDrawn)
          Expanded(child: _PrimaryBtn('DRAW COMBAT', () => bloc.add(const GameDrawAndResolveCombatCard())))
        else
          Expanded(child: _DisabledBtn('CARD RESOLVED')),
        const SizedBox(width: 8),
        Expanded(
          child: state.combatCardDrawn
              ? _SecondaryBtn('CONTACT → B2', () => bloc.add(const GameAdvanceFromB1()))
              : _DisabledBtn('CONTACT → B2'),
        ),
      ],
      GamePhase.b2TargetAcq => [
        if (state.currentTarget == null)
          Expanded(child: _PrimaryBtn('ROLL TARGET', () => bloc.add(const GameRollTargetAcq())))
        else if (state.currentThreat == null)
          Expanded(child: _PrimaryBtn('ROLL THREAT', () => bloc.add(const GameRollThreatDetermination())))
        else ...[
          Expanded(child: _PrimaryBtn('ENGAGE', () => bloc.add(const GameDecideEngage()))),
          const SizedBox(width: 8),
          Expanded(child: _DangerBtn('RETREAT', () => bloc.add(const GameDecideRetreat()))),
        ],
      ],
      GamePhase.b3Positioning => [
        Expanded(
          child: _PrimaryBtn('CONTACT → B4', () => bloc.add(const GameAdvanceFromB3())),
        ),
      ],
      GamePhase.b4Attack => [
        Expanded(
          child: (state.selectedAttackMode == AttackMode.foLaze) || 
                 (state.selectedAttackMode != null && state.selectedWeapon != null)
              ? _PrimaryBtn('EXECUTE ATTACK', () => bloc.add(const GameExecuteAttack()))
              : _DisabledBtn('SELECT MODE & WEAPON'),
        ),
      ],
      GamePhase.b5Evasion => [
        if (state.lastEvasionResult == null)
          Expanded(child: _PrimaryBtn('RESOLVE EVASION', () => bloc.add(const GameExecuteEvasion())))
        else ...[
          Expanded(child: _PrimaryBtn('CONTINUE', () => bloc.add(const GameDecideContinue()))),
          const SizedBox(width: 8),
          Expanded(child: _SecondaryBtn('RTB', () => bloc.add(const GameDecideRTB()))),
        ],
      ],
      _ => [const Expanded(child: SizedBox())],
    };
  }
}

class _PrimaryBtn extends StatelessWidget {
  const _PrimaryBtn(this.label, this.onTap);
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: MilstdTheme.accentPrimary,
          foregroundColor: MilstdTheme.textInverse,
          textStyle: const TextStyle(fontFamily: 'Rajdhani', fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.5),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(MilstdTheme.radiusSm)),
        ),
        child: Text(label),
      ),
    );
  }
}

class _SecondaryBtn extends StatelessWidget {
  const _SecondaryBtn(this.label, this.onTap);
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: MilstdTheme.accentSecondary,
          side: const BorderSide(color: MilstdTheme.accentSecondary, width: 1),
          textStyle: const TextStyle(fontFamily: 'Rajdhani', fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.5),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(MilstdTheme.radiusSm)),
        ),
        child: Text(label),
      ),
    );
  }
}

class _DangerBtn extends StatelessWidget {
  const _DangerBtn(this.label, this.onTap);
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: MilstdTheme.accentDanger,
          side: const BorderSide(color: MilstdTheme.accentDanger, width: 1),
          textStyle: const TextStyle(fontFamily: 'Rajdhani', fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.5),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(MilstdTheme.radiusSm)),
        ),
        child: Text(label),
      ),
    );
  }
}

class _DisabledBtn extends StatelessWidget {
  const _DisabledBtn(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ElevatedButton(
        onPressed: null,
        style: ElevatedButton.styleFrom(
          backgroundColor: MilstdTheme.surface,
          disabledBackgroundColor: MilstdTheme.surface,
          disabledForegroundColor: MilstdTheme.textMuted,
          textStyle: const TextStyle(fontFamily: 'Rajdhani', fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.5),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(MilstdTheme.radiusSm)),
        ),
        child: Text(label),
      ),
    );
  }
}
