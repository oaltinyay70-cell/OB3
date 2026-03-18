
import '../models/combat_card.dart';
import '../models/game_enums.dart';
import '../models/scenario.dart';
import '../models/target_card.dart';
import '../models/threat_card.dart';
import '../models/weapon.dart';
import 'combat_card_handler.dart';
import 'combat_resolution.dart';
import 'damage_system.dart';
import 'deck_manager.dart';
import 'dice_service.dart';
import 'drone_state.dart';
import 'game_state.dart';
import 'objective_evaluator.dart';
import 'scenario_loader.dart';
import 'target_acquisition.dart' as ta;
import 'threat_determination.dart' as td;

/// Callback type for state change notifications.
typedef GameStateCallback = void Function(GameState state);

/// The central game engine orchestrating the B0→B5 game loop.
///
/// Manages the phase state machine, dice rolls, CRT lookups, damage,
/// card management, and scoring. The UI layer observes state changes
/// via the [onStateChanged] callback.
class GameEngine {
  GameEngine({
    required GameSetup setup,
    DiceService? diceService,
    this.onStateChanged,
  })  : _setup = setup,
        _dice = diceService ?? DiceService(),
        _droneState = setup.droneState,
        _combatDeck = setup.combatDeck,
        _targetDecks = setup.targetDecks,
        _threatDecks = setup.threatDecks,
        _targetRanges = setup.targetRanges.isNotEmpty
            ? setup.targetRanges
            : null,
        _threatRanges = setup.threatRanges.isNotEmpty
            ? setup.threatRanges
            : null,
        _scoringMode = setup.scoringMode,
        _primaryCondition = _buildCondition(
          setup.scenario?.primaryObjectiveCardName,
          setup.scenario?.primaryObjectiveQty ?? 1,
          setup.scenario?.primaryObjectiveWeaponReq,
          setup.scenario?.primaryObjective,
        ),
        _secondaryCondition = _buildCondition(
          setup.scenario?.secondaryObjectiveCardName,
          setup.scenario?.secondaryObjectiveQty ?? 1,
          setup.scenario?.secondaryObjectiveWeaponReq,
          setup.scenario?.secondaryObjective,
        ) {
    _log('Game initialized. Drone: ${setup.drone.name}');
  }

  final GameSetup _setup;
  final DiceService _dice;
  final DroneState _droneState;
  final DeckManager<CombatCard> _combatDeck;
  final Map<String, DeckManager<TargetCard>> _targetDecks;
  final Map<String, DeckManager<ThreatCard>> _threatDecks;
  final List<ProbabilityRange>? _targetRanges;
  final List<ProbabilityRange>? _threatRanges;
  final ScoringMode _scoringMode;

  // Objective conditions built from scenario
  final ObjectiveCondition _primaryCondition;
  final ObjectiveCondition _secondaryCondition;

  /// Callback invoked whenever the game state changes.
  GameStateCallback? onStateChanged;

  // ---------------------------------------------------------------------------
  // Scenario Modifiers (from editor, default 0 = no effect)
  // ---------------------------------------------------------------------------
  int get _modFuelCost => _setup.scenario?.modifierFuelCost ?? 0;
  int get _modAttackRoll => _setup.scenario?.modifierAttackRoll ?? 0;
  int get _modEvasion => _setup.scenario?.modifierEvasion ?? 0;
  int get _modAltitudeCost => _setup.scenario?.modifierAltitudeCost ?? 0;
  int get _modTargetAcq => _setup.scenario?.modifierTargetAcquisition ?? 0;
  int get _modThreatDet => _setup.scenario?.modifierThreatDetermination ?? 0;

  // ---------------------------------------------------------------------------
  // Internal State
  // ---------------------------------------------------------------------------
  GamePhase _phase = GamePhase.setup;
  int _cycleNumber = 0;
  TargetCard? _currentTarget;
  ThreatCard? _currentThreat;
  CombatCard? _currentCombatCard;
  AttackMode? _selectedAttackMode;
  Weapon? _selectedWeapon;
  final List<TargetCard> _destroyedTargets = [];
  final List<String> _weaponsUsedPerKill = []; // parallel to _destroyedTargets
  final List<String> _gameLog = [];
  bool _isGameOver = false;
  String? _gameOverReason;
  String? _lastAttackResult;
  String? _lastEvasionResult;
  ObjectiveStatus? _primaryObjectiveStatus;
  ObjectiveStatus? _secondaryObjectiveStatus;
  bool _objectiveCompletionPromptNeeded = false;
  // ignore: prefer_final_fields
  int _currentZone = 1;

  // Combat card active restrictions
  String? _attackModeRestriction;

  // Track whether combat card was drawn this phase (for altitude lock)
  bool _combatCardDrawn = false;
  String? _lastCombatEffect;
  bool _altitudeChangedThisPhase = false;

  // ---------------------------------------------------------------------------
  // Static helper to build ObjectiveCondition from scenario fields
  // ---------------------------------------------------------------------------
  static ObjectiveCondition _buildCondition(
    String? cardNameOrCategory,
    int qty,
    String? weaponReq,
    String? description,
  ) {
    return ObjectiveCondition(
      cardNameOrCategory: cardNameOrCategory ?? 'NONE',
      requiredQty: qty,
      weaponRequired: weaponReq,
      description: description,
    );
  }

  // ---------------------------------------------------------------------------
  // Public API: State Snapshots
  // ---------------------------------------------------------------------------

  /// Current game state snapshot.
  GameState get state => GameState(
        phase: _phase,
        cycleNumber: _cycleNumber,
        droneState: _droneState,
        currentTarget: _currentTarget,
        currentThreat: _currentThreat,
        currentCombatCard: _currentCombatCard,
        combatCardDrawn: _combatCardDrawn,
        altitudeChangedThisPhase: _altitudeChangedThisPhase,
        lastCombatEffect: _lastCombatEffect,
        selectedAttackMode: _selectedAttackMode,
        selectedWeapon: _selectedWeapon,
        destroyedTargets: List.unmodifiable(_destroyedTargets),
        gameLog: List.unmodifiable(_gameLog),
        isGameOver: _isGameOver,
        gameOverReason: _gameOverReason,
        lastAttackResult: _lastAttackResult,
        lastEvasionResult: _lastEvasionResult,
        scenarioObjectiveMet: _primaryObjectiveStatus?.isMet ?? false,
        primaryObjectiveStatus: _primaryObjectiveStatus,
        secondaryObjectiveStatus: _secondaryObjectiveStatus,
        objectiveCompletionPromptNeeded: _objectiveCompletionPromptNeeded,
        currentZone: _currentZone,
      );

  // ---------------------------------------------------------------------------
  // Public API: Game Flow
  // ---------------------------------------------------------------------------

  /// Start the game — move to B0.
  void startGame() {
    if (_phase != GamePhase.setup) return;
    _cycleNumber = 1;
    _phase = GamePhase.b0InTransit;
    _log('=== Cycle $_cycleNumber begins ===');
    _log('Drone at B0 — In Transit. Altitude: ${_droneState.altitude.name.toUpperCase()}');
    _notifyState();
  }

  /// B0 — Process In Transit (COMMS check if needed, then advance to B1).
  ///
  /// Returns COMMS check result: 0=OK, 1=penalty, 2=destroyed, -1=no check needed.
  int processB0() {
    _ensurePhase(GamePhase.b0InTransit);

    int commsResult = -1;

    // COMMS check if damage > 2 AND not first cycle
    if (_droneState.requiresCommsCheck && _cycleNumber > 1) {
      final roll = _dice.rollD6();
      final drm = roll + _droneState.commsDamage +
          _droneState.commsCheckDrmReduction;
      commsResult = CombatResolution.resolveCommsCheck(drm);

      _log('B0: COMMS Check — Roll $roll + ${_droneState.commsDamage} COMMS dmg + ${_droneState.commsCheckDrmReduction} capability = DRM $drm');

      switch (commsResult) {
        case 0:
          _log('B0: COMMS OK — all clear.');
          _droneState.commsCheckPenalty = 0;
        case 1:
          _log('B0: COMMS difficulty — -1 attack penalty this turn.');
          _droneState.commsCheckPenalty = -1;
        case 2:
          _log('B0: COMMS FAILURE — Drone uncontrollable! Game Over.');
          _endGame('Drone lost — COMMS failure. Uncontrollable.');
          return commsResult;
      }
    }

    _phase = GamePhase.b1Search;
    _currentCombatCard = null;
    _combatCardDrawn = false;
    _lastCombatEffect = null;
    _altitudeChangedThisPhase = false;
    _log('Moving to B1 — Search.');
    _notifyState();
    return commsResult;
  }

  /// B1/B3 — Change altitude (optional).
  ///
  /// Returns fuel cost, or -1 on failure.
  int changeAltitude(Altitude newAltitude) {
    _ensurePhases([GamePhase.b1Search, GamePhase.b3Positioning]);

    if (_altitudeChangedThisPhase) {
      _log('Altitude already changed this phase. Only one change allowed.');
      return -1;
    }

    if (newAltitude == _droneState.altitude) return 0;

    final baseCost = _droneState.changeAltitude(newAltitude);
    if (baseCost < 0) {
      _log('Cannot change to ${newAltitude.name} — insufficient fuel or altitude not allowed.');
      return -1;
    }

    // Apply scenario altitude cost modifier
    final modCost = _modAltitudeCost;
    if (modCost != 0 && baseCost > 0) {
      _droneState.spendFuel(modCost);
    }
    final totalCost = baseCost + (baseCost > 0 ? modCost : 0);

    _log('Altitude changed to ${newAltitude.name.toUpperCase()} (cost: ${totalCost}F${modCost != 0 ? ", mod: ${modCost > 0 ? "+" : ""}$modCost" : ""}).');

    if (_droneState.fuel <= 0) {
      _endGame('Out of fuel — forced RTB.');
      return totalCost;
    }

    _altitudeChangedThisPhase = true;
    _notifyState();
    return totalCost;
  }

  /// B1/B3 — Draw and immediately auto-resolve a combat card.
  ///
  /// B1 — Draw and auto-resolve a combat card.
  ///
  /// Combines draw + execute into a single action. Only 1 draw per phase.
  /// Combat cards are NOT drawn at B3 (positioning-only phase).
  void drawAndResolveCombatCard() {
    _ensurePhase(GamePhase.b1Search);

    if (_combatCardDrawn) {
      _log('Combat card already drawn this phase.');
      _notifyState();
      return;
    }

    // Draw
    final card = _combatDeck.draw();
    if (card == null) {
      _log('Combat deck exhausted and reshuffled.');
      _combatCardDrawn = true;
      _lastCombatEffect = 'NO EVENT — deck exhausted';
      _notifyState();
      return;
    }

    _currentCombatCard = card;
    _combatCardDrawn = true;
    _log('Combat Card drawn: ${card.cardName}');

    // Auto-resolve
    final effect = CombatCardHandler.apply(card, _droneState);
    _lastCombatEffect = effect.description;
    _log('Auto-resolved: ${effect.description}');

    // Track attack mode restrictions
    if (effect.type == CombatCardEffectType.attackModeRestriction) {
      _attackModeRestriction = effect.attackModeRestriction;
    }

    // Discard after resolve (keep card ref for display via currentCombatCard)
    _combatDeck.discard(card);
    // Don't clear _currentCombatCard — keep it for UI display until phase advances

    _notifyState();
  }

  /// B1 — Draw a combat card (required).
  ///
  /// Returns the drawn card.
  @Deprecated('Use drawAndResolveCombatCard() instead')
  CombatCard? drawCombatCard() {
    _ensurePhase(GamePhase.b1Search);

    final card = _combatDeck.draw();
    if (card == null) {
      _log('Combat deck exhausted and reshuffled.');
      return null;
    }

    _currentCombatCard = card;
    _combatCardDrawn = true;
    _log('Combat Card drawn: ${card.cardName}');
    _notifyState();
    return card;
  }

  /// B1 — Execute the drawn combat card's effect.
  ///
  /// Returns the effect description.
  @Deprecated('Use drawAndResolveCombatCard() instead')
  CombatCardEffect executeCombatCard() {
    _ensurePhase(GamePhase.b1Search);

    final card = _currentCombatCard;
    if (card == null) {
      return CombatCardEffect.noEvent;
    }

    final effect = CombatCardHandler.apply(card, _droneState);
    _log('Combat Card effect: ${effect.description}');

    // Track attack mode restrictions
    if (effect.type == CombatCardEffectType.attackModeRestriction) {
      _attackModeRestriction = effect.attackModeRestriction;
    }

    // Discard the combat card
    _combatDeck.discard(card);
    _currentCombatCard = null;

    _notifyState();
    return effect;
  }

  /// B1 — Advance from Search to B2 Target Acquisition.
  void advanceFromB1() {
    _ensurePhase(GamePhase.b1Search);

    // Spend 1F fuel for B2 + scenario fuel cost modifier
    final fuelCost = 1 + _modFuelCost;
    if (!_droneState.spendFuel(fuelCost)) {
      _endGame('Out of fuel — forced RTB.');
      return;
    }
    _log('Fuel spent: ${fuelCost}F for target search${_modFuelCost != 0 ? " (mod: ${_modFuelCost > 0 ? "+" : ""}$_modFuelCost)" : ""}. Remaining: ${_droneState.fuel}F');

    _phase = GamePhase.b2TargetAcq;
    _currentTarget = null;
    _currentThreat = null;
    _log('Moving to B2 — Target Acquisition & Threat Determination.');
    _notifyState();
  }

  /// B2 — Roll for target acquisition.
  ///
  /// Returns the drawn target card (or null if all targets exhausted).
  TargetCard? rollTargetAcquisition() {
    _ensurePhase(GamePhase.b2TargetAcq);

    final roll = _dice.roll2D10();
    final baseDrm = _droneState.targetAcquisitionDrm;
    final drm = baseDrm + _modTargetAcq;
    final finalRoll = roll.value + drm;

    _log('Target Acquisition: Roll ${roll.value} + DRM $baseDrm${_modTargetAcq != 0 ? " + mod $_modTargetAcq" : ""} = $finalRoll');

    // Get available target types
    final availableTypes = _targetDecks.entries
        .where((e) => e.value.drawPileSize > 0 || e.value.discardPileSize > 0)
        .map((e) => e.key)
        .toSet();

    if (availableTypes.isEmpty) {
      _log('All target cards exhausted!');
      _endGame('All targets exhausted — mission complete.');
      return null;
    }

    final typeName = ta.lookupTargetType(
      roll: roll.value,
      drm: drm,
      customRanges: _targetRanges,
      availableTypes: availableTypes,
    );

    if (typeName == null) {
      _log('No matching target type available.');
      return null;
    }

    _log('Target type: $typeName');

    final deck = _targetDecks[typeName];
    final card = deck?.draw();

    if (card == null) {
      _log('No cards available for type $typeName.');
      return null;
    }

    _currentTarget = card;
    _log('Target drawn: ${card.cardName} (${card.vp} VP)');
    _notifyState();
    return card;
  }

  /// B2 — Roll for threat determination.
  ///
  /// Returns the drawn threat card (or null if none available).
  ThreatCard? rollThreatDetermination() {
    _ensurePhase(GamePhase.b2TargetAcq);

    final roll = _dice.roll2D10();
    final baseDrm = _droneState.threatDeterminationDrm;
    final drm = baseDrm + _modThreatDet;
    final finalRoll = roll.value + drm;

    _log('Threat Determination: Roll ${roll.value} + DRM $baseDrm${_modThreatDet != 0 ? " + mod $_modThreatDet" : ""} = $finalRoll');

    final availableTypes = _threatDecks.entries
        .where((e) => e.value.totalInPlay > 0)
        .map((e) => e.key)
        .toSet();

    if (availableTypes.isEmpty) {
      // Recycle all threat cards (§6.4.2.2)
      _log('All threat cards used — recycling.');
      for (final deck in _threatDecks.values) {
        deck.recycleAll();
      }
    }

    final typeName = td.lookupThreatType(
      roll: roll.value,
      drm: drm,
      customRanges: _threatRanges,
      availableTypes: _threatDecks.entries
          .where((e) => e.value.totalInPlay > 0)
          .map((e) => e.key)
          .toSet(),
    );

    if (typeName == null) {
      _log('No matching threat type.');
      return null;
    }

    _log('Threat type: $typeName');

    final deck = _threatDecks[typeName];
    final card = deck?.draw();

    if (card == null) {
      _log('No cards available for threat type $typeName.');
      return null;
    }

    _currentThreat = card;
    _log('Threat drawn: ${card.cardName}');
    _notifyState();
    return card;
  }

  /// B2 — Decision: Engage (continue to B3).
  void decideEngage() {
    _ensurePhase(GamePhase.b2TargetAcq);

    if (_currentTarget == null) {
      _log('No target to engage.');
      return;
    }

    _log('DECISION: Engage target ${_currentTarget!.cardName}.');
    _phase = GamePhase.b3Positioning;
    _currentCombatCard = null;
    _altitudeChangedThisPhase = false;
    _log('Moving to B3 — Positioning.');
    _notifyState();
  }

  /// B2 — Decision: Retreat (discard cards, return to B1).
  void decideRetreat() {
    _ensurePhase(GamePhase.b2TargetAcq);

    _log('DECISION: Retreat. Discarding target and threat cards.');

    if (_currentTarget != null) {
      final targetType = _currentTarget!.subCategory;
      _targetDecks[targetType]?.discard(_currentTarget!);
      _currentTarget = null;
    }

    if (_currentThreat != null) {
      final threatType = _currentThreat!.subCategory;
      _threatDecks[threatType]?.discard(_currentThreat!);
      _currentThreat = null;
    }

    _phase = GamePhase.b1Search;
    _log('Returning to B1 — Search.');
    _notifyState();
  }

  /// B3 — Advance from Positioning to B4 Attack.
  void advanceFromB3() {
    _ensurePhase(GamePhase.b3Positioning);
    _phase = GamePhase.b4Attack;
    _selectedAttackMode = null;
    _selectedWeapon = null;
    _lastAttackResult = null;
    _log('Moving to B4 — Drone Attack.');
    _notifyState();
  }

  /// B4 — Select attack mode and weapon.
  ///
  /// Returns true if selection is valid.
  bool selectAttack({
    required AttackMode mode,
    Weapon? weapon,
  }) {
    _ensurePhase(GamePhase.b4Attack);

    // Check combat card attack mode restriction
    if (_attackModeRestriction == 'CLOSE_IN_ONLY' &&
        mode != AttackMode.closeIn) {
      _log('Attack restricted to Close-In by combat card.');
      return false;
    }

    // Altitude restrictions per attack mode:
    // Stand-Off: MEDIUM or HIGH only
    // Close-In: VLOW or LOW only
    // FO/Laze: any altitude
    if (mode == AttackMode.standOff &&
        _droneState.altitude != Altitude.medium &&
        _droneState.altitude != Altitude.high) {
      _log('Stand-Off mode requires MEDIUM or HIGH altitude.');
      return false;
    }

    if (mode == AttackMode.closeIn &&
        _droneState.altitude != Altitude.vlow &&
        _droneState.altitude != Altitude.low) {
      _log('Close-In mode requires VLOW or LOW altitude.');
      return false;
    }

    if (mode == AttackMode.foLaze) {
      weapon = null; // Enforce no weapon for FO/Laze
    } else {
      if (weapon == null) {
        _log('Weapon required for ${mode.label}.');
        return false;
      }

      // Check weapon altitude restrictions
      if (!weapon.canFireAtAltitude(_droneState.altitude)) {
        _log('${weapon.name} cannot fire at ${_droneState.altitude.name} altitude.');
        return false;
      }

      // Check weapon vs attack mode compatibility (fire_range field)
      if (!weapon.canFireInMode(mode)) {
        _log('${weapon.name} cannot be used in ${mode.label} mode (fire_range: ${weapon.fireRange}).');
        return false;
      }

      // Check ammo availability
      final slot = _droneState.loadout
          .where((s) => s.weapon.id == weapon!.id && s.hasAmmo)
          .firstOrNull;
      if (slot == null) {
        _log('No ammunition for ${weapon.name}.');
        return false;
      }

      // Check weapon effectiveness against target type.
      // A weapon with DRM 0 for this target category cannot engage it.
      // This gates AIR targets — no current weapon has drm_air > 0.
      if (_currentTarget != null &&
          !weapon.canEngageTargetType(_currentTarget!.targetType)) {
        _log('${weapon.name} cannot engage ${_currentTarget!.targetType.dbValue} targets (DRM = 0).');
        return false;
      }
    }

    _selectedAttackMode = mode;
    _selectedWeapon = weapon;
    _log('Attack selected: ${mode.label}${weapon != null ? ' with ${weapon.name}' : ''}.');
    _notifyState();
    return true;
  }

  /// B4 — Execute the attack.
  ///
  /// Returns the CRT result.
  CrtResult executeAttack() {
    _ensurePhase(GamePhase.b4Attack);

    if (_selectedAttackMode == null) {
      throw StateError('Must select attack mode first.');
    }
    if (_selectedAttackMode != AttackMode.foLaze && _selectedWeapon == null) {
      throw StateError('Must select weapon for non-FO/Laze attacks.');
    }
    if (_currentTarget == null) {
      throw StateError('No target to attack.');
    }

    // Roll D6
    final roll = _dice.rollD6();

    // Calculate DRM: weapon DRM + sensor penalty + comms penalty + scenario modifier
    final weaponDrm = _selectedWeapon?.getDrm(_currentTarget!.targetType) ?? 0;
    final sensorPenalty = _droneState.sensorAttackPenalty;
    final commsPenalty = _droneState.commsCheckPenalty;
    final totalDrm = roll + weaponDrm + sensorPenalty + commsPenalty + _modAttackRoll;

    _log('B4: Attack Roll $roll + weapon DRM $weaponDrm + sensor $sensorPenalty + comms $commsPenalty${_modAttackRoll != 0 ? " + mod $_modAttackRoll" : ""} = DRM $totalDrm');

    // CRT lookup
    final result = CombatResolution.resolveAttack(
      mode: _selectedAttackMode!,
      altitude: _droneState.altitude,
      rawDrm: totalDrm,
      sensorDamage: _droneState.sensorsDamage,
    );

    // Use weapon ammo
    if (_selectedWeapon != null) {
      final slot = _droneState.loadout
          .firstWhere((s) => s.weapon.id == _selectedWeapon!.id && s.hasAmmo);
      slot.use();
    }

    // Apply fuel cost (+ scenario modifier)
    final attackFuelCost = result.fuelCost + _modFuelCost;
    _droneState.spendFuel(attackFuelCost);

    // Process hit/miss
    if (result.isHit) {
      _log('B4: *** HIT! *** ${_currentTarget!.cardName} destroyed! (+${_currentTarget!.vp} VP)');
      _destroyedTargets.add(_currentTarget!);
      _weaponsUsedPerKill.add(_selectedWeapon?.name ?? 'FO/Laze');
      // Move to destroyed pile in appropriate deck
      final targetType = _currentTarget!.subCategory;
      _targetDecks[targetType]?.destroy(_currentTarget!);
      _lastAttackResult = 'HIT — ${_currentTarget!.cardName} destroyed!';

      // Evaluate objectives after every kill
      _evaluateObjectives();
    } else {
      _log('B4: MISS. Target survives. Fuel cost: ${attackFuelCost}F.');
      // Discard target card
      final targetType = _currentTarget!.subCategory;
      _targetDecks[targetType]?.discard(_currentTarget!);
      _lastAttackResult = 'MISS — ${_currentTarget!.cardName} survives.';
    }

    _log('Fuel remaining: ${_droneState.fuel}F');

    // Check for SAM reaction shot (§6.4.3.1)
    if (!result.isHit &&
        _currentTarget!.targetType == TargetType.sam) {
      _processSamReactionShot();
    }

    // Move to B5
    _phase = GamePhase.b5Evasion;
    _lastEvasionResult = null;
    _log('Moving to B5 — Evasive Action.');
    _notifyState();
    return result;
  }

  /// B5 — Execute evasion against the current threat.
  ///
  /// Returns the CRT result.
  CrtResult executeEvasion() {
    _ensurePhase(GamePhase.b5Evasion);

    if (_currentThreat == null) {
      _log('B5: No threat — safe passage.');
      _lastEvasionResult = 'No threat to evade.';
      _notifyState();
      return CrtResult.none;
    }

    final roll = _dice.rollD6();

    // DRM: roll + threat card column shift + scenario evasion modifier
    int columnShift = 0;
    if (_currentThreat!.columnShiftBy != null) {
      final dir = _currentThreat!.columnShiftDirection?.toUpperCase();
      if (dir == 'RIGHT') {
        columnShift = _currentThreat!.columnShiftBy!;
      } else if (dir == 'LEFT') {
        columnShift = -_currentThreat!.columnShiftBy!;
      }
    }

    final evasionRoll = roll + _modEvasion;
    _log('B5: Evasion Roll $roll${_modEvasion != 0 ? " + mod $_modEvasion" : ""}, VIS ${_droneState.vis}, threat shift $columnShift');

    final result = CombatResolution.resolveCounterfire(
      mode: _selectedAttackMode ?? AttackMode.standOff,
      altitude: _droneState.altitude,
      rawDrm: evasionRoll,
      vis: _droneState.vis,
      threatColumnShift: columnShift,
    );

    // Apply fuel cost
    _droneState.spendFuel(result.fuelCost);

    // Apply damage
    if (result.damage > 0) {
      final report = DamageSystem.applyDamage(_droneState, result.damage);
      _log('B5: Counterfire! $report');
      _lastEvasionResult = 'Counterfire: ${report.toString()}';

      if (report.isDestroyed) {
        _endGame('Drone destroyed by counterfire!');
        return result;
      }
    } else {
      _log('B5: Evasion successful — no damage.');
      _lastEvasionResult = 'Evasion successful — no damage.';
    }

    _log('Fuel remaining: ${_droneState.fuel}F');

    // Discard threat card
    if (_currentThreat != null) {
      final threatType = _currentThreat!.subCategory;
      _threatDecks[threatType]?.discard(_currentThreat!);
    }

    // Clear current cards
    _currentTarget = null;
    _currentThreat = null;
    _selectedAttackMode = null;
    _selectedWeapon = null;

    // Check fuel
    if (_droneState.fuel <= 0) {
      _endGame('Out of fuel — forced RTB.');
      return result;
    }

    _notifyState();
    return result;
  }

  /// B5 — Decision: Continue mission (return to B0).
  void decideContinue() {
    _ensurePhase(GamePhase.b5Evasion);

    if (_droneState.fuel <= 0) {
      _endGame('Out of fuel — forced RTB.');
      return;
    }

    if (!_droneState.hasAmmo && !_droneState.canFoLaze) {
      _log('WARNING: No weapons or FO/Laze capability remaining.');
    }

    _cycleNumber++;
    _phase = GamePhase.b0InTransit;
    _attackModeRestriction = null; // Clear combat card restrictions
    _droneState.commsCheckPenalty = 0;
    _log('=== Cycle $_cycleNumber begins ===');
    _log('Returning to B0 — In Transit.');
    _notifyState();
  }

  /// B5 — Decision: Return to base (end game).
  void decideRTB() {
    _ensurePhase(GamePhase.b5Evasion);
    _endGame('Player chose RTB — mission complete.');
  }

  // ---------------------------------------------------------------------------
  // SAM Reaction Shot (§6.4.3.1)
  // ---------------------------------------------------------------------------

  void _processSamReactionShot() {
    _log('SAM Reaction Shot: SAM target survived — checking reaction fire.');

    final roll = _dice.rollD6();
    final drm = roll + _droneState.vis;

    if (drm < 6) {
      _log('SAM Reaction: Roll $roll + VIS ${_droneState.vis} = $drm < 6. SAM does not fire.');
      return;
    }

    _log('SAM Reaction: Roll $roll + VIS ${_droneState.vis} = $drm ≥ 6. SAM fires!');

    final samResult = CombatResolution.resolveSamCounterfire(
      mode: _selectedAttackMode ?? AttackMode.standOff,
      altitude: _droneState.altitude,
      rawDrm: roll,
      vis: _droneState.vis,
    );

    _droneState.spendFuel(samResult.fuelCost);

    if (samResult.damage > 0) {
      final report = DamageSystem.applyDamage(_droneState, samResult.damage);
      _log('SAM Reaction Hit! $report');
      if (report.isDestroyed) {
        _endGame('Drone destroyed by SAM reaction shot!');
      }
    } else {
      _log('SAM Reaction: No damage.');
    }
  }

  // ---------------------------------------------------------------------------
  // Objective Evaluation (replaces old _checkObjective)
  // ---------------------------------------------------------------------------

  /// Whether all target decks are empty (for ALL_TARGETS objective).
  bool get _allDecksEmpty => _targetDecks.values.every(
      (deck) => deck.drawPileSize == 0 && deck.discardPileSize == 0);

  /// Re-evaluate both objectives against current kill list.
  void _evaluateObjectives() {
    // Primary
    if (_primaryCondition.isActive) {
      final prevMet = _primaryObjectiveStatus?.isMet ?? false;
      _primaryObjectiveStatus = ObjectiveEvaluator.evaluate(
        condition: _primaryCondition,
        destroyedTargets: _destroyedTargets,
        weaponsUsed: _weaponsUsedPerKill,
        allDecksEmpty: _allDecksEmpty,
      );

      if (_primaryObjectiveStatus!.isMet && !prevMet) {
        _log('*** PRIMARY OBJECTIVE COMPLETE! *** ${_primaryCondition.description ?? _primaryCondition.cardNameOrCategory}');

        // QUICK_KILL scoring: prompt player to RTB or continue
        if (_scoringMode == ScoringMode.quickKill) {
          _objectiveCompletionPromptNeeded = true;
          _log('QUICK KILL mode — objective met. RTB or continue?');
        }
      }
    }

    // Secondary
    if (_secondaryCondition.isActive) {
      final prevMet = _secondaryObjectiveStatus?.isMet ?? false;
      _secondaryObjectiveStatus = ObjectiveEvaluator.evaluate(
        condition: _secondaryCondition,
        destroyedTargets: _destroyedTargets,
        weaponsUsed: _weaponsUsedPerKill,
        allDecksEmpty: _allDecksEmpty,
      );

      if (_secondaryObjectiveStatus!.isMet && !prevMet) {
        _log('*** SECONDARY OBJECTIVE COMPLETE! *** ${_secondaryCondition.description ?? _secondaryCondition.cardNameOrCategory}');
      }
    }
  }

  /// Called by UI when player dismisses the objective completion prompt.
  /// If QUICK_KILL and player chose RTB, this ends the game.
  void respondToObjectivePrompt({required bool chooseRtb}) {
    _objectiveCompletionPromptNeeded = false;
    if (chooseRtb) {
      _endGame('Primary objective complete — mission success (RTB).');
    } else {
      _log('Player chose to continue despite objective completion.');
    }
    _notifyState();
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  void _log(String message) {
    _gameLog.add('[C$_cycleNumber/${_phase.label}] $message');
  }

  void _notifyState() {
    onStateChanged?.call(state);
  }

  void _ensurePhase(GamePhase expected) {
    if (_phase != expected) {
      throw StateError(
          'Invalid phase: expected ${expected.label}, got ${_phase.label}');
    }
  }

  void _ensurePhases(List<GamePhase> expected) {
    if (!expected.contains(_phase)) {
      throw StateError(
          'Invalid phase: expected one of ${expected.map((e) => e.label).join(", ")}, got ${_phase.label}');
    }
  }

  void _endGame(String reason) {
    _isGameOver = true;
    _gameOverReason = reason;
    _phase = GamePhase.gameOver;
    _log('GAME OVER: $reason');
    _log('Final Score: ${state.totalVP} VP from ${_destroyedTargets.length} kills.');
    _notifyState();
  }
}
