class Scenario {
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
  final int? primaryObjectiveVpThreshold;
  final String? primaryObjectiveTargetType;
  final int? primaryObjectiveTargetCount;
  final String? secondaryObjective;
  final String? secondaryObjectiveCardName;
  final int? secondaryObjectiveVpThreshold;
  final String? secondaryObjectiveTargetType;
  final int? secondaryObjectiveTargetCount;
  final double secondaryObjectiveVpBonus;
  final String scoringMode;
  final int combatNoEventCount;
  final int combatEventCount;
  final String? reinforcementRule;
  final String? specialRules;

  // Sprint 11: Briefing presentation fields
  final String? location;
  final String? introText;
  final String? overview;
  final String? threatRules;
  final String? targetRules;
  final String? combatRules;
  final int? startingFuel;
  final int startingDamageSens;
  final int startingDamageComms;
  final String? missionBriefingText;
  final String? loadoutRules;

  // Designer Tool fields
  final String? shortDescription;
  final String? difficultyRating;
  final int? estimatedPlayTimeMinutes;
  final String? tags;                  // JSON array string
  final String? authorName;
  final double version;
  final String? thumbnailImagePath;
  final String? designerNotes;
  final String state;                  // Draft / Published / Inactive
  final String? modifiedDate;

  // Custom modifiers
  final int modifierFuelCost;
  final int modifierAttackRoll;
  final int modifierEvasion;
  final int modifierAltitudeCost;
  final int modifierTargetAcquisition;
  final int modifierThreatDetermination;

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
    this.primaryObjectiveVpThreshold,
    this.primaryObjectiveTargetType,
    this.primaryObjectiveTargetCount,
    this.secondaryObjectiveCardName,
    this.secondaryObjectiveVpThreshold,
    this.secondaryObjectiveTargetType,
    this.secondaryObjectiveTargetCount,
    this.secondaryObjectiveVpBonus = 0.0,
    this.scoringMode = 'MAXIMUM_KILL',
    this.combatNoEventCount = 42,
    this.combatEventCount = 8,
    this.reinforcementRule,
    this.specialRules,
    this.location,
    this.introText,
    this.overview,
    this.threatRules,
    this.targetRules,
    this.combatRules,
    this.startingFuel,
    this.startingDamageSens = 0,
    this.startingDamageComms = 0,
    this.secondaryObjective,
    this.missionBriefingText,
    this.loadoutRules,
    // Designer fields
    this.shortDescription,
    this.difficultyRating,
    this.estimatedPlayTimeMinutes,
    this.tags,
    this.authorName,
    this.version = 1.0,
    this.thumbnailImagePath,
    this.designerNotes,
    this.state = 'Draft',
    this.modifiedDate,
    this.modifierFuelCost = 0,
    this.modifierAttackRoll = 0,
    this.modifierEvasion = 0,
    this.modifierAltitudeCost = 0,
    this.modifierTargetAcquisition = 0,
    this.modifierThreatDetermination = 0,
  });

  factory Scenario.fromRow(Map<String, dynamic> row) => Scenario(
    id: row['id'] as int,
    name: row['name'] as String,
    campaignName: row['campaign_name'] as String?,
    description: row['description'] as String?,
    narrative: row['narrative'] as String?,
    droneId: row['drone_id'] as int?,
    primaryObjective: row['primary_objective'] as String?,
    primaryObjectiveZone: row['primary_objective_zone'] as int?,
    primaryObjectiveCardName: row['primary_objective_card_name'] as String?,
    primaryObjectiveWeaponReq: row['primary_objective_weapon_req'] as String?,
    primaryObjectiveVpThreshold: row['primary_objective_vp_threshold'] as int?,
    primaryObjectiveTargetType: row['primary_objective_target_type'] as String?,
    primaryObjectiveTargetCount: row['primary_objective_target_count'] as int?,
    secondaryObjectiveCardName: row['secondary_objective_card_name'] as String?,
    secondaryObjectiveVpThreshold: row['secondary_objective_vp_threshold'] as int?,
    secondaryObjectiveTargetType: row['secondary_objective_target_type'] as String?,
    secondaryObjectiveTargetCount: row['secondary_objective_target_count'] as int?,
    secondaryObjectiveVpBonus: (row['secondary_objective_vp_bonus'] as num?)?.toDouble() ?? 0.0,
    scoringMode: row['scoring_mode'] as String? ?? 'MAXIMUM_KILL',
    combatNoEventCount: row['combat_no_event_count'] as int? ?? 42,
    combatEventCount: row['combat_event_count'] as int? ?? 8,
    reinforcementRule: row['reinforcement_rule'] as String?,
    specialRules: row['special_rules'] as String?,
    location: row['location'] as String?,
    introText: row['intro_text'] as String?,
    overview: row['overview'] as String?,
    threatRules: row['threat_rules'] as String?,
    targetRules: row['target_rules'] as String?,
    combatRules: row['combat_rules'] as String?,
    startingFuel: row['starting_fuel'] as int?,
    startingDamageSens: row['starting_damage_sens'] as int? ?? 0,
    startingDamageComms: row['starting_damage_comms'] as int? ?? 0,
    secondaryObjective: row['secondary_objective'] as String?,
    missionBriefingText: row['mission_briefing_text'] as String?,
    loadoutRules: row['loadout_rules'] as String?,
    // Designer fields
    shortDescription: row['short_description'] as String?,
    difficultyRating: row['difficulty_rating'] as String?,
    estimatedPlayTimeMinutes: row['estimated_play_time_minutes'] as int?,
    tags: row['tags'] as String?,
    authorName: row['author_name'] as String?,
    version: (row['version_number'] as num?)?.toDouble() ?? 1.0,
    thumbnailImagePath: row['thumbnail_image_path'] as String?,
    designerNotes: row['designer_notes'] as String?,
    state: row['state'] as String? ?? 'Draft',
    modifiedDate: row['modified_date'] as String?,
    modifierFuelCost: row['modifier_fuel_cost'] as int? ?? 0,
    modifierAttackRoll: row['modifier_attack_roll'] as int? ?? 0,
    modifierEvasion: row['modifier_evasion'] as int? ?? 0,
    modifierAltitudeCost: row['modifier_altitude_cost'] as int? ?? 0,
    modifierTargetAcquisition: row['modifier_target_acquisition'] as int? ?? 0,
    modifierThreatDetermination: row['modifier_threat_determination'] as int? ?? 0,
  );
}

class ScenarioZone {
  final int id;
  final int scenarioId;
  final int zoneNumber;
  final bool hasStar;
  final String? terrainDesc;

  const ScenarioZone({
    required this.id,
    required this.scenarioId,
    required this.zoneNumber,
    required this.hasStar,
    this.terrainDesc,
  });

  factory ScenarioZone.fromRow(Map<String, dynamic> row) => ScenarioZone(
    id: row['id'] as int,
    scenarioId: row['scenario_id'] as int,
    zoneNumber: row['zone_number'] as int,
    hasStar: (row['has_star'] as int? ?? 0) == 1,
    terrainDesc: row['terrain_desc'] as String?,
  );
}

class ScenarioThreatRange {
  final int id;
  final int scenarioId;
  final int zoneNumber;
  final String threatType;
  final int? rangeMin;
  final int? rangeMax;
  final bool isNa;

  const ScenarioThreatRange({
    required this.id,
    required this.scenarioId,
    required this.zoneNumber,
    required this.threatType,
    this.rangeMin,
    this.rangeMax,
    required this.isNa,
  });

  factory ScenarioThreatRange.fromRow(Map<String, dynamic> row) => ScenarioThreatRange(
    id: row['id'] as int,
    scenarioId: row['scenario_id'] as int,
    zoneNumber: row['zone_number'] as int,
    threatType: row['threat_type'] as String,
    rangeMin: row['range_min'] as int?,
    rangeMax: row['range_max'] as int?,
    isNa: (row['is_na'] as int? ?? 0) == 1,
  );
}

class ScenarioTargetRange {
  final int id;
  final int scenarioId;
  final int zoneNumber;
  final String targetType;
  final int? rangeMin;
  final int? rangeMax;
  final bool isNa;

  const ScenarioTargetRange({
    required this.id,
    required this.scenarioId,
    required this.zoneNumber,
    required this.targetType,
    this.rangeMin,
    this.rangeMax,
    required this.isNa,
  });

  factory ScenarioTargetRange.fromRow(Map<String, dynamic> row) => ScenarioTargetRange(
    id: row['id'] as int,
    scenarioId: row['scenario_id'] as int,
    zoneNumber: row['zone_number'] as int,
    targetType: row['target_type'] as String,
    rangeMin: row['range_min'] as int?,
    rangeMax: row['range_max'] as int?,
    isNa: (row['is_na'] as int? ?? 0) == 1,
  );
}

class ScenarioThreatDeck {
  final int id;
  final int scenarioId;
  final int zoneNumber;
  final String threatCardName;
  final String threatType;
  final int quantity;
  final String? specialRules;

  const ScenarioThreatDeck({
    required this.id,
    required this.scenarioId,
    required this.zoneNumber,
    required this.threatCardName,
    required this.threatType,
    required this.quantity,
    this.specialRules,
  });

  factory ScenarioThreatDeck.fromRow(Map<String, dynamic> row) => ScenarioThreatDeck(
    id: row['id'] as int,
    scenarioId: row['scenario_id'] as int,
    zoneNumber: row['zone_number'] as int,
    threatCardName: row['threat_card_name'] as String,
    threatType: row['threat_type'] as String,
    quantity: row['quantity'] as int? ?? 0,
    specialRules: row['special_rules'] as String?,
  );
}

class ScenarioTargetDeck {
  final int id;
  final int scenarioId;
  final int zoneNumber;
  final String targetCardName;
  final String targetType;
  final double vp;
  final int quantity;
  final String? specialRules;

  const ScenarioTargetDeck({
    required this.id,
    required this.scenarioId,
    required this.zoneNumber,
    required this.targetCardName,
    required this.targetType,
    required this.vp,
    required this.quantity,
    this.specialRules,
  });

  factory ScenarioTargetDeck.fromRow(Map<String, dynamic> row) => ScenarioTargetDeck(
    id: row['id'] as int,
    scenarioId: row['scenario_id'] as int,
    zoneNumber: row['zone_number'] as int,
    targetCardName: row['target_card_name'] as String,
    targetType: row['target_type'] as String,
    vp: (row['vp'] as num?)?.toDouble() ?? 0.0,
    quantity: row['quantity'] as int? ?? 0,
    specialRules: row['special_rules'] as String?,
  );
}

class ScenarioLoadout {
  final int id;
  final int scenarioId;
  final int loadoutNumber;
  final String weaponName;
  final int quantity;
  final String? constraints;
  final String? notes;

  const ScenarioLoadout({
    required this.id,
    required this.scenarioId,
    required this.loadoutNumber,
    required this.weaponName,
    required this.quantity,
    this.constraints,
    this.notes,
  });

  factory ScenarioLoadout.fromRow(Map<String, dynamic> row) => ScenarioLoadout(
    id: row['id'] as int,
    scenarioId: row['scenario_id'] as int,
    loadoutNumber: row['loadout_number'] as int,
    weaponName: row['weapon_name'] as String,
    quantity: row['quantity'] as int? ?? 0,
    constraints: row['constraints'] as String?,
    notes: row['notes'] as String?,
  );
}
