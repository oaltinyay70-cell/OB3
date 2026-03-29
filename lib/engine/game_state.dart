import '../models/game_enums.dart';
import '../models/combat_card.dart';
import '../models/target_card.dart';
import '../models/threat_card.dart';
import '../models/weapon.dart';
import 'drone_state.dart';
import 'objective_evaluator.dart';

/// Associates a destroyed target with the weapon used to destroy it.
class KillRecord {
  const KillRecord({required this.target, required this.weaponName});
  final TargetCard target;
  final String weaponName;
}

/// Immutable snapshot of the full game state.
///
/// The GameEngine produces new GameState instances as the game progresses.
/// The UI layer observes state changes.
class GameState {
  const GameState({
    required this.phase,
    required this.cycleNumber,
    required this.droneState,
    required this.killRecords,
    required this.gameLog,
    this.currentTarget,
    this.currentThreat,
    this.currentCombatCard,
    this.combatCardDrawn = false,
    this.altitudeChangedThisPhase = false,
    this.lastCombatEffect,
    this.selectedAttackMode,
    this.selectedWeapon,
    this.isGameOver = false,
    this.gameOverReason,
    this.lastAttackResult,
    this.lastEvasionResult,
    this.scenarioObjectiveMet = false,
    this.primaryObjectiveStatus,
    this.secondaryObjectiveStatus,
    this.objectiveCompletionPromptNeeded = false,
    this.currentZone = 1,
  });

  /// Current game phase (B0–B6 or GameOver).
  final GamePhase phase;

  /// Current cycle number (1-based, increments each B0 pass).
  final int cycleNumber;

  /// Drone vital stats and loadout.
  final DroneState droneState;

  /// Target card drawn at B2 (null if not yet drawn).
  final TargetCard? currentTarget;

  /// Threat card drawn at B2 (null if not yet drawn).
  final ThreatCard? currentThreat;

  /// Combat card drawn at B1/B3 (null after auto-resolve clears it).
  final CombatCard? currentCombatCard;

  /// Whether a combat card was drawn this phase (stays true after resolve).
  final bool combatCardDrawn;

  /// Whether the altitude was already changed during the current phase.
  final bool altitudeChangedThisPhase;

  /// Result description of auto-resolved combat card effect.
  final String? lastCombatEffect;

  /// Selected attack mode at B4.
  final AttackMode? selectedAttackMode;

  /// Selected weapon at B4.
  final Weapon? selectedWeapon;

  /// Records of targets destroyed and weapons used.
  final List<KillRecord> killRecords;

  /// Cards destroyed by successful attacks (for VP scoring and display).
  List<TargetCard> get destroyedTargets =>
      killRecords.map((k) => k.target).toList();

  /// Game event log for display.
  final List<String> gameLog;

  /// Whether the game has ended.
  final bool isGameOver;

  /// Reason the game ended (if applicable).
  final String? gameOverReason;

  /// Result description of last attack.
  final String? lastAttackResult;

  /// Result description of last evasion.
  final String? lastEvasionResult;

  /// Whether the scenario primary objective has been met.
  final bool scenarioObjectiveMet;

  /// Live primary objective progress.
  final ObjectiveStatus? primaryObjectiveStatus;

  /// Live secondary objective progress.
  final ObjectiveStatus? secondaryObjectiveStatus;

  /// Whether the UI should show "RTB or continue?" prompt (QUICK_KILL mode).
  final bool objectiveCompletionPromptNeeded;

  /// Current zone number (for scenario games).
  final int currentZone;

  /// Total VP from destroyed targets.
  double get totalVP =>
      killRecords.fold(0.0, (sum, record) => sum + record.target.vp);
}
