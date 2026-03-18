import 'dart:math';
import '../data/repositories/card_repository.dart';
import '../data/repositories/drone_repository.dart';
import '../data/repositories/scenario_repository.dart';
import '../data/repositories/weapon_repository.dart';
import '../models/combat_card.dart';
import '../models/drone.dart';
import '../models/game_enums.dart';
import '../models/scenario.dart';
import '../models/target_card.dart';
import '../models/threat_card.dart';
import '../models/weapon.dart';
import 'deck_manager.dart';
import 'drone_state.dart';

/// Configuration produced by the ScenarioLoader, ready for the GameEngine.
class GameSetup {
  const GameSetup({
    required this.drone,
    required this.droneState,
    required this.combatDeck,
    required this.targetDecks,
    required this.threatDecks,
    required this.weaponMap,
    required this.targetRanges,
    required this.threatRanges,
    required this.scoringMode,
    this.scenario,
    this.availableLoadouts,
    this.primaryObjectiveCardName,
  });

  final Drone drone;
  final DroneState droneState;
  final DeckManager<CombatCard> combatDeck;

  /// Target card decks keyed by target type (e.g., 'TRUCK', 'AFV').
  final Map<String, DeckManager<TargetCard>> targetDecks;

  /// Threat card decks keyed by threat type (e.g., 'AAA', 'SAM').
  final Map<String, DeckManager<ThreatCard>> threatDecks;

  /// All weapons by uppercase name for loadout resolution.
  final Map<String, Weapon> weaponMap;

  /// Target probability ranges for the current zone.
  final List<ProbabilityRange> targetRanges;

  /// Threat probability ranges for the current zone.
  final List<ProbabilityRange> threatRanges;

  /// Scoring mode (Maximum Kill or Quick Kill).
  final ScoringMode scoringMode;

  /// Full scenario config (null for Quick Game).
  final Scenario? scenario;

  /// Available loadout configs from scenario.
  final List<ScenarioLoadout>? availableLoadouts;

  /// Primary objective target card name (for objective checking).
  final String? primaryObjectiveCardName;
}

/// Builds a complete [GameSetup] from a scenario or quick game configuration.
class ScenarioLoader {
  const ScenarioLoader({
    required this.droneRepo,
    required this.weaponRepo,
    required this.cardRepo,
    required this.scenarioRepo,
  });

  final DroneRepository droneRepo;
  final WeaponRepository weaponRepo;
  final CardRepository cardRepo;
  final ScenarioRepository scenarioRepo;

  /// Load a scenario game by scenario ID and zone number.
  Future<GameSetup> loadScenario({
    required int scenarioId,
    required int zoneNumber,
    required int selectedLoadoutNumber,
    Random? random,
  }) async {
    final scenario = await scenarioRepo.getById(scenarioId);
    if (scenario == null) {
      throw ArgumentError('Scenario $scenarioId not found');
    }

    // Load drone
    final droneId = scenario.droneId ?? 1;
    final drone = await droneRepo.getById(droneId);
    if (drone == null) {
      throw StateError('Drone $droneId not found for scenario $scenarioId');
    }

    // Load weapons
    final weaponMap = await weaponRepo.getAllAsMap();

    // Build loadout from selected scenario loadout
    final loadoutEntries = scenario.loadouts
        .where((l) => l.loadoutNumber == selectedLoadoutNumber)
        .toList();
    final loadout = _buildLoadout(loadoutEntries, weaponMap);

    // Build drone state
    final droneState = _buildDroneState(drone, loadout);

    // Build combat deck from counts
    final allCombatCards = await cardRepo.getAllCombatCards();
    final combatDeck =
        DeckManager<CombatCard>(cards: allCombatCards, random: random);

    // Build target decks from scenario deck entries
    final allTargetCards = await cardRepo.getAllTargetCards();
    final targetDecks = _buildTargetDecks(
      scenario.targetDeckEntries
          .where((e) => e.zoneNumber == zoneNumber)
          .toList(),
      allTargetCards,
      random,
    );

    // Build threat decks from scenario deck entries
    final allThreatCards = await cardRepo.getAllThreatCards();
    final threatDecks = _buildThreatDecks(
      scenario.threatDeckEntries
          .where((e) => e.zoneNumber == zoneNumber)
          .toList(),
      allThreatCards,
      random,
    );

    // Get ranges for this zone
    final targetRanges = scenario.targetRangesForZone(zoneNumber);
    final threatRanges = scenario.threatRangesForZone(zoneNumber);

    return GameSetup(
      drone: drone,
      droneState: droneState,
      combatDeck: combatDeck,
      targetDecks: targetDecks,
      threatDecks: threatDecks,
      weaponMap: weaponMap,
      targetRanges: targetRanges,
      threatRanges: threatRanges,
      scoringMode: scenario.scoringMode,
      scenario: scenario,
      availableLoadouts: scenario.loadouts,
      primaryObjectiveCardName: scenario.primaryObjectiveCardName,
    );
  }

  /// Load a quick game with a chosen drone and loadout option.
  Future<GameSetup> loadQuickGame({
    required int droneId,
    required int loadoutOptionIndex,
    Random? random,
  }) async {
    final drone = await droneRepo.getById(droneId);
    if (drone == null) throw ArgumentError('Drone $droneId not found');

    final weaponMap = await weaponRepo.getAllAsMap();

    // Build loadout from drone's own loadout options
    final option = drone.loadoutOptions[loadoutOptionIndex];
    final loadout = <LoadoutSlot>[];
    final w1 = weaponMap[option.weapon1Name.toUpperCase()];
    if (w1 != null) {
      loadout.add(LoadoutSlot(weapon: w1, quantity: option.weapon1Qty));
    }
    if (option.weapon2Name != null && option.weapon2Qty != null) {
      final w2 = weaponMap[option.weapon2Name!.toUpperCase()];
      if (w2 != null) {
        loadout.add(LoadoutSlot(weapon: w2, quantity: option.weapon2Qty!));
      }
    }

    final droneState = _buildDroneState(drone, loadout);

    // Build full decks from all available cards
    final combatDeck = DeckManager<CombatCard>(
      cards: await cardRepo.getAllCombatCards(),
      random: random,
    );

    final allTargetCards = await cardRepo.getAllTargetCards();
    final targetDecks = _groupCardsByType<TargetCard>(
      allTargetCards,
      (card) => card.subCategory,
      random,
    );

    final allThreatCards = await cardRepo.getAllThreatCards();
    final threatDecks = _groupCardsByType<ThreatCard>(
      allThreatCards,
      (card) => card.subCategory,
      random,
    );

    return GameSetup(
      drone: drone,
      droneState: droneState,
      combatDeck: combatDeck,
      targetDecks: targetDecks,
      threatDecks: threatDecks,
      weaponMap: weaponMap,
      targetRanges: const [], // use defaults
      threatRanges: const [], // use defaults
      scoringMode: ScoringMode.maximumKill,
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  DroneState _buildDroneState(Drone drone, List<LoadoutSlot> loadout) {
    return DroneState(
      fuel: drone.defaultFuel,
      maxFuel: drone.defaultFuel,
      maxIntegrity: drone.maxStructuralIntegrity,
      altitude: Altitude.medium, // PRD §3.2: all drones start at MEDIUM
      allowedAltitudes: drone.allowedAltitudes,
      loadout: loadout,
      hasAesa: drone.hasAesa,
      hasSatcom: drone.hasSatcom,
      hasCommsRedundancy: drone.hasCommsRedundancy,
      hasAutonomousAi: drone.hasAutonomousAi,
      hasBuiltinFoLaze: drone.hasBuiltinFoLaze,
    );
  }

  List<LoadoutSlot> _buildLoadout(
    List<ScenarioLoadout> entries,
    Map<String, Weapon> weaponMap,
  ) {
    final loadout = <LoadoutSlot>[];
    for (final entry in entries) {
      final weapon = weaponMap[entry.weaponName.toUpperCase()];
      if (weapon != null) {
        loadout.add(LoadoutSlot(weapon: weapon, quantity: entry.quantity));
      }
    }
    return loadout;
  }

  Map<String, DeckManager<TargetCard>> _buildTargetDecks(
    List<ScenarioTargetDeckEntry> entries,
    List<TargetCard> allCards,
    Random? random,
  ) {
    final decks = <String, List<TargetCard>>{};
    for (final entry in entries) {
      final matching = allCards
          .where((c) =>
              c.cardName.toUpperCase() == entry.targetCardName.toUpperCase())
          .toList();
      if (matching.isNotEmpty) {
        final type = entry.targetType;
        decks.putIfAbsent(type, () => []);
        for (int i = 0; i < entry.quantity; i++) {
          decks[type]!.add(matching[i % matching.length]);
        }
      }
    }
    return decks.map((type, cards) =>
        MapEntry(type, DeckManager<TargetCard>(cards: cards, random: random)));
  }

  Map<String, DeckManager<ThreatCard>> _buildThreatDecks(
    List<ScenarioThreatDeckEntry> entries,
    List<ThreatCard> allCards,
    Random? random,
  ) {
    final decks = <String, List<ThreatCard>>{};
    for (final entry in entries) {
      final matching = allCards
          .where((c) =>
              c.cardName.toUpperCase() == entry.threatCardName.toUpperCase())
          .toList();
      if (matching.isNotEmpty) {
        final type = entry.threatType;
        decks.putIfAbsent(type, () => []);
        for (int i = 0; i < entry.quantity; i++) {
          decks[type]!.add(matching[i % matching.length]);
        }
      }
    }
    return decks.map((type, cards) =>
        MapEntry(type, DeckManager<ThreatCard>(cards: cards, random: random)));
  }

  Map<String, DeckManager<T>> _groupCardsByType<T>(
    List<T> cards,
    String Function(T) typeExtractor,
    Random? random,
  ) {
    final groups = <String, List<T>>{};
    for (final card in cards) {
      groups.putIfAbsent(typeExtractor(card), () => []).add(card);
    }
    return groups.map((type, cards) =>
        MapEntry(type, DeckManager<T>(cards: cards, random: random)));
  }
}
