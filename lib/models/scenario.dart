import 'package:equatable/equatable.dart';
import 'game_enums.dart';

/// A probability range mapping a dice roll range to a target/threat type.
class ProbabilityRange extends Equatable {
  const ProbabilityRange({
    required this.typeName,
    required this.rangeMin,
    required this.rangeMax,
    this.isNa = false,
  });

  final String typeName;
  final int rangeMin;
  final int rangeMax;
  final bool isNa;

  /// Check if a roll falls within this range.
  bool contains(int roll) => !isNa && roll >= rangeMin && roll <= rangeMax;

  @override
  List<Object?> get props => [typeName, rangeMin, rangeMax, isNa];
}

/// A zone within a scenario.
class ScenarioZone extends Equatable {
  const ScenarioZone({
    required this.zoneNumber,
    required this.hasStar,
    this.terrainDesc,
  });

  final int zoneNumber;
  final bool hasStar;
  final String? terrainDesc;

  factory ScenarioZone.fromMap(Map<String, dynamic> map) {
    return ScenarioZone(
      zoneNumber: map['zone_number'] as int,
      hasStar: (map['has_star'] as int? ?? 0) == 1,
      terrainDesc: map['terrain_desc'] as String?,
    );
  }

  @override
  List<Object?> get props => [zoneNumber];
}

/// A loadout definition from the scenario.
class ScenarioLoadout extends Equatable {
  const ScenarioLoadout({
    required this.loadoutNumber,
    required this.weaponName,
    required this.quantity,
    this.constraints,
    this.notes,
  });

  final int loadoutNumber;
  final String weaponName;
  final int quantity;
  final String? constraints;
  final String? notes;

  factory ScenarioLoadout.fromMap(Map<String, dynamic> map) {
    return ScenarioLoadout(
      loadoutNumber: map['loadout_number'] as int,
      weaponName: map['weapon_name'] as String,
      quantity: map['quantity'] as int,
      constraints: map['constraints'] as String?,
      notes: map['notes'] as String?,
    );
  }

  @override
  List<Object?> get props => [loadoutNumber, weaponName];
}

/// A target entry in the scenario deck composition.
class ScenarioTargetDeckEntry extends Equatable {
  const ScenarioTargetDeckEntry({
    required this.zoneNumber,
    required this.targetCardName,
    required this.targetType,
    required this.vp,
    required this.quantity,
    this.specialRules,
  });

  final int zoneNumber;
  final String targetCardName;
  final String targetType;
  final double vp;
  final int quantity;
  final String? specialRules;

  factory ScenarioTargetDeckEntry.fromMap(Map<String, dynamic> map) {
    return ScenarioTargetDeckEntry(
      zoneNumber: map['zone_number'] as int,
      targetCardName: map['target_card_name'] as String,
      targetType: map['target_type'] as String,
      vp: (map['vp'] as num?)?.toDouble() ?? 0.0,
      quantity: map['quantity'] as int? ?? 0,
      specialRules: map['special_rules'] as String?,
    );
  }

  @override
  List<Object?> get props => [zoneNumber, targetCardName];
}

/// A threat entry in the scenario deck composition.
class ScenarioThreatDeckEntry extends Equatable {
  const ScenarioThreatDeckEntry({
    required this.zoneNumber,
    required this.threatCardName,
    required this.threatType,
    required this.quantity,
    this.specialRules,
  });

  final int zoneNumber;
  final String threatCardName;
  final String threatType;
  final int quantity;
  final String? specialRules;

  factory ScenarioThreatDeckEntry.fromMap(Map<String, dynamic> map) {
    return ScenarioThreatDeckEntry(
      zoneNumber: map['zone_number'] as int,
      threatCardName: map['threat_card_name'] as String,
      threatType: map['threat_type'] as String,
      quantity: map['quantity'] as int? ?? 0,
      specialRules: map['special_rules'] as String?,
    );
  }

  @override
  List<Object?> get props => [zoneNumber, threatCardName];
}

/// Full scenario definition loaded from the database.
///
/// Includes both core fields (original schema) and designer-added fields
/// (from ALTER TABLE — see PRD §12.1b).
class Scenario extends Equatable {
  const Scenario({
    required this.id,
    required this.name,
    this.campaignName,
    this.description,
    this.narrative,
    this.droneId,
    this.primaryObjective,
    this.primaryObjectiveZone,
    this.primaryObjectiveCardName,
    this.primaryObjectiveWeaponReq,
    this.primaryObjectiveQty,
    this.primaryObjectiveTargetType,
    this.primaryObjectiveTargetCount,
    // Secondary objective (mirrors primary structure)
    this.secondaryObjective,
    this.secondaryObjectiveCardName,
    this.secondaryObjectiveWeaponReq,
    this.secondaryObjectiveZone,
    this.secondaryObjectiveQty,
    this.secondaryObjectiveTargetType,
    this.secondaryObjectiveTargetCount,
    required this.scoringMode,
    required this.combatNoEventCount,
    required this.combatEventCount,
    this.reinforcementRule,
    this.specialRules,
    // Designer metadata (PRD §12.1b)
    this.shortDescription,
    this.overview,
    this.missionBriefingText,
    this.introText,
    this.location,
    this.versionNumber,
    this.state,
    this.difficultyRating,
    this.estimatedPlayTimeMinutes,
    this.authorName,
    this.tags,
    this.thumbnailImagePath,
    this.missionBriefingImagePath,
    // Briefing display fields
    this.threatRules,
    this.targetRules,
    this.combatRules,
    this.loadoutRules,
    this.startingFuel,
    this.startingDamageSens,
    this.startingDamageComms,
    // Designer synced fields
    this.threatIntel,
    this.targetIntel,
    this.startFuelModifier,
    this.startDamageModifier,
    // Gameplay modifiers
    this.modifierFuelCost,
    this.modifierAttackRoll,
    this.modifierEvasion,
    this.modifierAltitudeCost,
    this.modifierTargetAcquisition,
    this.modifierThreatDetermination,
    // Children
    required this.zones,
    required this.loadouts,
    required this.targetDeckEntries,
    required this.threatDeckEntries,
    required this.targetRanges,
    required this.threatRanges,
    this.allowedDroneIds = const [],
    this.allowedDroneNames = const [],
  });

  // --- Core game fields (original schema) ---
  final int id;
  final String name;
  final String? campaignName;
  final String? description;
  final String? narrative;
  final int? droneId;
  final String? primaryObjective;
  final int? primaryObjectiveZone;
  final String? primaryObjectiveCardName;
  final String? primaryObjectiveWeaponReq;
  final int? primaryObjectiveQty;
  final String? primaryObjectiveTargetType;
  final int? primaryObjectiveTargetCount;
  // Secondary objective
  final String? secondaryObjective;
  final String? secondaryObjectiveCardName;
  final String? secondaryObjectiveWeaponReq;
  final int? secondaryObjectiveZone;
  final int? secondaryObjectiveQty;
  final String? secondaryObjectiveTargetType;
  final int? secondaryObjectiveTargetCount;
  final ScoringMode scoringMode;
  final int combatNoEventCount;
  final int combatEventCount;
  final String? reinforcementRule;
  final String? specialRules;

  // --- Designer metadata (PRD §12.1b) ---
  final String? shortDescription;
  final String? overview;
  final String? missionBriefingText;
  final String? introText;
  final String? location;
  final double? versionNumber;
  final String? state; // Draft / Published / Inactive
  final String? difficultyRating; // Easy / Medium / Hard / Extreme
  final int? estimatedPlayTimeMinutes;
  final String? authorName;
  final String? tags; // JSON string
  final String? thumbnailImagePath;
  final String? missionBriefingImagePath;

  // --- Briefing display fields ---
  final String? threatRules;
  final String? targetRules;
  final String? combatRules;
  final String? loadoutRules;
  final int? startingFuel;
  final int? startingDamageSens;
  final int? startingDamageComms;
  // Designer synced fields
  final String? threatIntel;
  final String? targetIntel;
  final int? startFuelModifier;
  final int? startDamageModifier;

  // --- Gameplay modifiers ---
  final int? modifierFuelCost;
  final int? modifierAttackRoll;
  final int? modifierEvasion;
  final int? modifierAltitudeCost;
  final int? modifierTargetAcquisition;
  final int? modifierThreatDetermination;

  // --- Children ---
  final List<ScenarioZone> zones;
  final List<ScenarioLoadout> loadouts;
  final List<ScenarioTargetDeckEntry> targetDeckEntries;
  final List<ScenarioThreatDeckEntry> threatDeckEntries;

  /// Custom target probability ranges per zone. Key = zone number.
  final Map<int, List<ProbabilityRange>> targetRanges;

  /// Custom threat probability ranges per zone. Key = zone number.
  final Map<int, List<ProbabilityRange>> threatRanges;

  /// Drone IDs allowed for this scenario. Empty = all drones allowed.
  final List<int> allowedDroneIds;
  final List<String> allowedDroneNames;

  /// Whether any gameplay modifiers are active (non-zero).
  bool get hasActiveModifiers =>
      (modifierFuelCost ?? 0) != 0 ||
      (modifierAttackRoll ?? 0) != 0 ||
      (modifierEvasion ?? 0) != 0 ||
      (modifierAltitudeCost ?? 0) != 0 ||
      (modifierTargetAcquisition ?? 0) != 0 ||
      (modifierThreatDetermination ?? 0) != 0;

  /// Get target ranges for a specific zone, falling back to default.
  List<ProbabilityRange> targetRangesForZone(int zone) =>
      targetRanges[zone] ?? [];

  /// Get threat ranges for a specific zone, falling back to default.
  List<ProbabilityRange> threatRangesForZone(int zone) =>
      threatRanges[zone] ?? [];

  @override
  List<Object?> get props => [id, name];
}
