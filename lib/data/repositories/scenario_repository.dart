
import '../database_service.dart';
import '../../models/game_enums.dart';
import '../../models/scenario.dart';

/// Repository for loading full scenario configurations from the database.
class ScenarioRepository {
  const ScenarioRepository(this._dbService);
  final DatabaseService _dbService;

  /// Load all available scenarios (metadata for the browser/list screen).
  Future<List<Map<String, dynamic>>> listScenarios() async {
    final db = await _dbService.database;
    return db.query(
      'scenarios',
      columns: [
        'id',
        'name',
        'campaign_name',
        'description',
        'short_description',
        'difficulty_rating',
        'estimated_play_time_minutes',
        'state',
        'thumbnail_image_path',
      ],
    );
  }

  /// Load a complete scenario by ID including all child tables.
  Future<Scenario?> getById(int id) async {
    final db = await _dbService.database;

    // 1. Load scenario metadata
    final scenarioMaps = await db.query(
      'scenarios',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (scenarioMaps.isEmpty) return null;
    final s = scenarioMaps.first;

    // 2. Load zones
    final zoneMaps = await db.query(
      'scenario_zones',
      where: 'scenario_id = ?',
      whereArgs: [id],
      orderBy: 'zone_number',
    );
    final zones = zoneMaps.map((m) => ScenarioZone.fromMap(m)).toList();

    // 3. Load loadouts
    final loadoutMaps = await db.query(
      'scenario_loadouts',
      where: 'scenario_id = ?',
      whereArgs: [id],
      orderBy: 'loadout_number',
    );
    final loadouts =
        loadoutMaps.map((m) => ScenarioLoadout.fromMap(m)).toList();

    // 4. Load target deck entries
    final targetDeckMaps = await db.query(
      'scenario_target_deck',
      where: 'scenario_id = ?',
      whereArgs: [id],
      orderBy: 'zone_number',
    );
    final targetDeckEntries =
        targetDeckMaps.map((m) => ScenarioTargetDeckEntry.fromMap(m)).toList();

    // 5. Load threat deck entries
    final threatDeckMaps = await db.query(
      'scenario_threat_deck',
      where: 'scenario_id = ?',
      whereArgs: [id],
      orderBy: 'zone_number',
    );
    final threatDeckEntries =
        threatDeckMaps.map((m) => ScenarioThreatDeckEntry.fromMap(m)).toList();

    // 6. Load target probability ranges grouped by zone
    final targetRangeMaps = await db.query(
      'scenario_target_ranges',
      where: 'scenario_id = ?',
      whereArgs: [id],
      orderBy: 'zone_number, range_min',
    );
    final targetRanges = _groupRanges(targetRangeMaps, 'target_type');

    // 7. Load threat probability ranges grouped by zone
    final threatRangeMaps = await db.query(
      'scenario_threat_ranges',
      where: 'scenario_id = ?',
      whereArgs: [id],
      orderBy: 'zone_number, range_min',
    );
    final threatRanges = _groupRanges(threatRangeMaps, 'threat_type');

    // 8. Load allowed drone IDs for this scenario.
    //    Check both tables: legacy `scenario_allowed_drones` and
    //    designer tool `scenario_designer_drones`.
    var allowedDroneMaps = await db.query(
      'scenario_allowed_drones',
      columns: ['drone_id'],
      where: 'scenario_id = ?',
      whereArgs: [id],
    );
    // Fallback to designer drones table if legacy table is empty
    if (allowedDroneMaps.isEmpty) {
      allowedDroneMaps = await db.query(
        'scenario_designer_drones',
        columns: ['drone_id'],
        where: 'scenario_id = ?',
        whereArgs: [id],
      );
    }
    final allowedDroneIds =
        allowedDroneMaps.map((m) => m['drone_id'] as int).toList();

    // Resolve drone IDs to names for briefing display
    final allowedDroneNames = <String>[];
    for (final droneId in allowedDroneIds) {
      final rows = await db.query('drones', columns: ['name'], where: 'id = ?', whereArgs: [droneId]);
      if (rows.isNotEmpty) {
        allowedDroneNames.add(rows.first['name'] as String);
      }
    }

    return Scenario(
      // Core game fields
      id: s['id'] as int,
      name: s['name'] as String,
      campaignName: s['campaign_name'] as String?,
      description: s['description'] as String?,
      narrative: s['narrative'] as String?,
      droneId: s['drone_id'] as int?,
      primaryObjective: s['primary_objective'] as String?,
      primaryObjectiveZone: s['primary_objective_zone'] as int?,
      primaryObjectiveCardName: s['primary_objective_card_name'] as String?,
      primaryObjectiveWeaponReq: s['primary_objective_weapon_req'] as String?,
      primaryObjectiveQty: s['primary_objective_qty'] as int? ?? 1,
      primaryObjectiveTargetType: s['primary_objective_target_type'] as String?,
      primaryObjectiveTargetCount: s['primary_objective_target_count'] as int?,
      // Secondary objective
      secondaryObjective: s['secondary_objective'] as String?,
      secondaryObjectiveCardName: s['secondary_objective_card_name'] as String?,
      secondaryObjectiveWeaponReq: s['secondary_objective_weapon_req'] as String?,
      secondaryObjectiveZone: s['secondary_objective_zone'] as int?,
      secondaryObjectiveQty: s['secondary_objective_qty'] as int? ?? 1,
      secondaryObjectiveTargetType: s['secondary_objective_target_type'] as String?,
      secondaryObjectiveTargetCount: s['secondary_objective_target_count'] as int?,
      scoringMode: ScoringMode.fromDb(s['scoring_mode'] as String?),
      combatNoEventCount: s['combat_no_event_count'] as int? ?? 42,
      combatEventCount: s['combat_event_count'] as int? ?? 8,
      reinforcementRule: s['reinforcement_rule'] as String?,
      specialRules: s['special_rules'] as String?,
      // Designer metadata (PRD §12.1b)
      shortDescription: s['short_description'] as String?,
      overview: s['overview'] as String?,
      missionBriefingText: s['mission_briefing_text'] as String?,
      introText: s['intro_text'] as String?,
      location: s['location'] as String?,
      versionNumber: (s['version_number'] as num?)?.toDouble(),
      state: s['state'] as String?,
      difficultyRating: s['difficulty_rating'] as String?,
      estimatedPlayTimeMinutes: s['estimated_play_time_minutes'] as int?,
      authorName: s['author_name'] as String?,
      tags: s['tags'] as String?,
      thumbnailImagePath: s['thumbnail_image_path'] as String?,
      missionBriefingImagePath: s['mission_briefing_image_path'] as String?,
      // Briefing display fields
      threatRules: s['threat_rules'] as String?,
      targetRules: s['target_rules'] as String?,
      combatRules: s['combat_rules'] as String?,
      loadoutRules: s['loadout_rules'] as String?,
      startingFuel: s['starting_fuel'] as int?,
      startingDamageSens: s['starting_damage_sens'] as int?,
      startingDamageComms: s['starting_damage_comms'] as int?,
      // Gameplay modifiers
      modifierFuelCost: s['modifier_fuel_cost'] as int?,
      modifierAttackRoll: s['modifier_attack_roll'] as int?,
      modifierEvasion: s['modifier_evasion'] as int?,
      modifierAltitudeCost: s['modifier_altitude_cost'] as int?,
      modifierTargetAcquisition: s['modifier_target_acquisition'] as int?,
      modifierThreatDetermination: s['modifier_threat_determination'] as int?,
      // Children
      zones: zones,
      loadouts: loadouts,
      targetDeckEntries: targetDeckEntries,
      threatDeckEntries: threatDeckEntries,
      targetRanges: targetRanges,
      threatRanges: threatRanges,
      allowedDroneIds: allowedDroneIds,
      allowedDroneNames: allowedDroneNames,
    );
  }

  /// Group probability range rows by zone number.
  Map<int, List<ProbabilityRange>> _groupRanges(
    List<Map<String, dynamic>> maps,
    String typeField,
  ) {
    final result = <int, List<ProbabilityRange>>{};
    for (final m in maps) {
      final zone = m['zone_number'] as int;
      final range = ProbabilityRange(
        typeName: m[typeField] as String,
        rangeMin: m['range_min'] as int? ?? 0,
        rangeMax: m['range_max'] as int? ?? 0,
        isNa: (m['is_na'] as int? ?? 0) == 1,
      );
      result.putIfAbsent(zone, () => []).add(range);
    }
    return result;
  }
}

