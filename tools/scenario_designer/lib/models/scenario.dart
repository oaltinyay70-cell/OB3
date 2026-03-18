class Scenario {
  final String id;
  final String name;
  final String description;
  final String difficulty;
  final List<String> objectives;
  final Map<String, dynamic> victoryConditions;
  final List<String> availableDroneIds;
  final List<String> availableLoadoutIds;
  final Map<String, dynamic> deckConfiguration;
  final String? specialRules;
  final int targetAcquisitionModifier;
  final int threatDeterminationModifier;
  final int lowAltitudeModifier;
  final int mediumAltitudeModifier;
  final int highAltitudeModifier;
  final int lowAltitudeThreatModifier;
  final int mediumAltitudeThreatModifier;
  final int highAltitudeThreatModifier;

  // Sprint 11: Briefing presentation fields
  final String? location;
  final String? introText;
  final String? overview;
  final String? narrative;
  final String? threatRules;
  final String? targetRules;
  final String? combatRules;
  final int? startingFuel;
  final int startingDamageSens;
  final int startingDamageComms;
  final String? primaryObjective;
  final String? primaryObjectiveCardName;
  final int? primaryObjectiveVpThreshold;
  final String? primaryObjectiveTargetType;
  final int? primaryObjectiveTargetCount;
  final String? secondaryObjective;
  final String? secondaryObjectiveCardName;
  final int? secondaryObjectiveVpThreshold;
  final String? secondaryObjectiveTargetType;
  final int? secondaryObjectiveTargetCount;
  final double secondaryObjectiveVpBonus;
  final String? missionBriefingText;
  final String? loadoutRules;
  final String? scoringMode;

  // Sprint 1: Designer modifiers (from scenario_designer)
  final int modifierFuelCost;
  final int modifierAttackRoll;
  final int modifierEvasion;
  final int modifierAltitudeCost;
  final int modifierTargetAcquisition;
  final int modifierThreatDetermination;

  // Sprint: Lock drone for campaigns
  final String? lockedDroneId;

  const Scenario({
    required this.id,
    required this.name,
    required this.description,
    required this.difficulty,
    this.objectives = const [],
    required this.victoryConditions,
    this.availableDroneIds = const [],
    this.availableLoadoutIds = const [],
    required this.deckConfiguration,
    this.specialRules,
    this.targetAcquisitionModifier = 0,
    this.threatDeterminationModifier = 0,
    this.lowAltitudeModifier = 0,
    this.mediumAltitudeModifier = 0,
    this.highAltitudeModifier = 0,
    this.lowAltitudeThreatModifier = 0,
    this.mediumAltitudeThreatModifier = 0,
    this.highAltitudeThreatModifier = 0,
    this.location,
    this.introText,
    this.overview,
    this.narrative,
    this.threatRules,
    this.targetRules,
    this.combatRules,
    this.startingFuel,
    this.startingDamageSens = 0,
    this.startingDamageComms = 0,
    this.primaryObjective,
    this.primaryObjectiveCardName,
    this.primaryObjectiveVpThreshold,
    this.primaryObjectiveTargetType,
    this.primaryObjectiveTargetCount,
    this.secondaryObjective,
    this.secondaryObjectiveCardName,
    this.secondaryObjectiveVpThreshold,
    this.secondaryObjectiveTargetType,
    this.secondaryObjectiveTargetCount,
    this.secondaryObjectiveVpBonus = 0.0,
    this.missionBriefingText,
    this.loadoutRules,
    this.scoringMode,
    this.modifierFuelCost = 0,
    this.modifierAttackRoll = 0,
    this.modifierEvasion = 0,
    this.modifierAltitudeCost = 0,
    this.modifierTargetAcquisition = 0,
    this.modifierThreatDetermination = 0,
    this.lockedDroneId,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'difficulty': difficulty,
    'objectives': objectives,
    'victoryConditions': victoryConditions,
    'availableDroneIds': availableDroneIds,
    'availableLoadoutIds': availableLoadoutIds,
    'deckConfiguration': deckConfiguration,
    'specialRules': specialRules,
    'targetAcquisitionModifier': targetAcquisitionModifier,
    'threatDeterminationModifier': threatDeterminationModifier,
    'lowAltitudeModifier': lowAltitudeModifier,
    'mediumAltitudeModifier': mediumAltitudeModifier,
    'highAltitudeModifier': highAltitudeModifier,
    'lowAltitudeThreatModifier': lowAltitudeThreatModifier,
    'mediumAltitudeThreatModifier': mediumAltitudeThreatModifier,
    'highAltitudeThreatModifier': highAltitudeThreatModifier,
    'location': location,
    'introText': introText,
    'overview': overview,
    'narrative': narrative,
    'threatRules': threatRules,
    'targetRules': targetRules,
    'combatRules': combatRules,
    'startingFuel': startingFuel,
    'startingDamageSens': startingDamageSens,
    'startingDamageComms': startingDamageComms,
    'primaryObjective': primaryObjective,
    'primaryObjectiveCardName': primaryObjectiveCardName,
    'primaryObjectiveVpThreshold': primaryObjectiveVpThreshold,
    'primaryObjectiveTargetType': primaryObjectiveTargetType,
    'primaryObjectiveTargetCount': primaryObjectiveTargetCount,
    'secondaryObjective': secondaryObjective,
    'secondaryObjectiveCardName': secondaryObjectiveCardName,
    'secondaryObjectiveVpThreshold': secondaryObjectiveVpThreshold,
    'secondaryObjectiveTargetType': secondaryObjectiveTargetType,
    'secondaryObjectiveTargetCount': secondaryObjectiveTargetCount,
    'secondaryObjectiveVpBonus': secondaryObjectiveVpBonus,
    'missionBriefingText': missionBriefingText,
    'loadoutRules': loadoutRules,
    'scoringMode': scoringMode,
    'modifierFuelCost': modifierFuelCost,
    'modifierAttackRoll': modifierAttackRoll,
    'modifierEvasion': modifierEvasion,
    'modifierAltitudeCost': modifierAltitudeCost,
    'modifierTargetAcquisition': modifierTargetAcquisition,
    'modifierThreatDetermination': modifierThreatDetermination,
    'lockedDroneId': lockedDroneId,
  };

  factory Scenario.fromJson(Map<String, dynamic> json) => Scenario(
    id: json['id'] as String,
    name: json['name'] as String,
    description: json['description'] as String,
    difficulty: json['difficulty'] as String,
    objectives: (json['objectives'] as List).cast<String>(),
    victoryConditions: json['victoryConditions'] is Map<String, dynamic>
        ? json['victoryConditions'] as Map<String, dynamic>
        : Map<String, dynamic>.from(json['victoryConditions'] as Map),
    availableDroneIds: ((json['availableDroneIds'] ?? json['availableDrones'] ?? []) as List).cast<String>(),
    availableLoadoutIds: ((json['availableLoadoutIds'] ?? json['availableLoadouts'] ?? []) as List).cast<String>(),
    deckConfiguration: json['deckConfiguration'] == null
        ? <String, dynamic>{}
        : json['deckConfiguration'] is Map<String, dynamic>
            ? json['deckConfiguration'] as Map<String, dynamic>
            : Map<String, dynamic>.from(json['deckConfiguration'] as Map),
    specialRules: json['specialRules'] as String?,
    targetAcquisitionModifier: json['targetAcquisitionModifier'] as int? ?? 0,
    threatDeterminationModifier: json['threatDeterminationModifier'] as int? ?? 0,
    lowAltitudeModifier: json['lowAltitudeModifier'] as int? ?? 0,
    mediumAltitudeModifier: json['mediumAltitudeModifier'] as int? ?? 0,
    highAltitudeModifier: json['highAltitudeModifier'] as int? ?? 0,
    lowAltitudeThreatModifier: json['lowAltitudeThreatModifier'] as int? ?? 0,
    mediumAltitudeThreatModifier: json['mediumAltitudeThreatModifier'] as int? ?? 0,
    highAltitudeThreatModifier: json['highAltitudeThreatModifier'] as int? ?? 0,
    location: json['location'] as String?,
    introText: json['introText'] as String?,
    overview: json['overview'] as String?,
    narrative: json['narrative'] as String?,
    threatRules: json['threatRules'] as String?,
    targetRules: json['targetRules'] as String?,
    combatRules: json['combatRules'] as String?,
    startingFuel: json['startingFuel'] as int?,
    startingDamageSens: json['startingDamageSens'] as int? ?? 0,
    startingDamageComms: json['startingDamageComms'] as int? ?? 0,
    primaryObjective: json['primaryObjective'] as String?,
    primaryObjectiveCardName: json['primaryObjectiveCardName'] as String?,
    primaryObjectiveVpThreshold: json['primaryObjectiveVpThreshold'] as int?,
    primaryObjectiveTargetType: json['primaryObjectiveTargetType'] as String?,
    primaryObjectiveTargetCount: json['primaryObjectiveTargetCount'] as int?,
    secondaryObjective: json['secondaryObjective'] as String?,
    secondaryObjectiveCardName: json['secondaryObjectiveCardName'] as String?,
    secondaryObjectiveVpThreshold: json['secondaryObjectiveVpThreshold'] as int?,
    secondaryObjectiveTargetType: json['secondaryObjectiveTargetType'] as String?,
    secondaryObjectiveTargetCount: json['secondaryObjectiveTargetCount'] as int?,
    secondaryObjectiveVpBonus: (json['secondaryObjectiveVpBonus'] as num?)?.toDouble() ?? 0.0,
    missionBriefingText: json['missionBriefingText'] as String?,
    loadoutRules: json['loadoutRules'] as String?,
    scoringMode: json['scoringMode'] as String?,
    modifierFuelCost: json['modifierFuelCost'] as int? ?? 0,
    modifierAttackRoll: json['modifierAttackRoll'] as int? ?? 0,
    modifierEvasion: json['modifierEvasion'] as int? ?? 0,
    modifierAltitudeCost: json['modifierAltitudeCost'] as int? ?? 0,
    modifierTargetAcquisition: json['modifierTargetAcquisition'] as int? ?? 0,
    modifierThreatDetermination: json['modifierThreatDetermination'] as int? ?? 0,
    lockedDroneId: json['lockedDroneId'] as String?,
  );
}

