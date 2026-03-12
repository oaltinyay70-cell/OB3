import 'dart:convert';
import '../services/database_service.dart';

/// Data class holding the full designer state for a scenario,
/// including its junction table data (selected drones, cards).
class DesignerScenarioData {
  // -- Step 1: Basic Info --
  String title;
  String shortDescription;
  String overviewText;
  String missionBriefing;
  String primaryObjective;
  String? primaryObjectiveCardName;
  int? primaryObjectiveVpThreshold;
  String? primaryObjectiveTargetType;
  int? primaryObjectiveTargetCount;
  String secondaryObjective;
  String? secondaryObjectiveCardName;
  int? secondaryObjectiveVpThreshold;
  String? secondaryObjectiveTargetType;
  int? secondaryObjectiveTargetCount;
  double secondaryObjectiveVpBonus;
  String difficultyRating;
  int estimatedPlayTimeMinutes;
  List<String> tags;
  String authorName;
  String designerNotes;
  String? thumbnailImagePath;

  // -- Step 2: Drones --
  Set<int> selectedDroneIds;

  // -- Steps 3-5: Cards (card id → quantity) --
  Map<int, int> targetCards;      // target_cards.id → qty
  Map<String, int> threatCards;   // threat_cards.card_number → qty
  Map<int, int> combatCards;      // combat_cards.id → qty

  // -- Step 6: Modifiers --
  int modifierFuelCost;
  int modifierAttackRoll;
  int modifierEvasion;
  int modifierAltitudeCost;
  int modifierTargetAcquisition;
  int modifierThreatDetermination;

  // -- Step 3 (new): Loadout restrictions --
  // droneId → Set of excluded optionIndexes (1, 2, 3)
  Map<int, Set<int>> excludedLoadouts;

  // -- Step 6 (new): Weapon restrictions --
  // weapon id → quantity (empty map = all weapons allowed)
  Map<int, int> weaponQuantities;

  // -- Metadata --
  int? scenarioId;  // null for new scenarios
  String state;
  int versionNumber;

  DesignerScenarioData({
    this.title = '',
    this.shortDescription = '',
    this.overviewText = '',
    this.missionBriefing = '',
    this.primaryObjective = '',
    this.primaryObjectiveCardName,
    this.primaryObjectiveVpThreshold,
    this.primaryObjectiveTargetType,
    this.primaryObjectiveTargetCount,
    this.secondaryObjective = '',
    this.secondaryObjectiveCardName,
    this.secondaryObjectiveVpThreshold,
    this.secondaryObjectiveTargetType,
    this.secondaryObjectiveTargetCount,
    this.secondaryObjectiveVpBonus = 0.0,
    this.difficultyRating = 'Medium',
    this.estimatedPlayTimeMinutes = 30,
    this.tags = const [],
    this.authorName = 'Oscar',
    this.designerNotes = '',
    this.thumbnailImagePath,
    Set<int>? selectedDroneIds,
    Map<int, int>? targetCards,
    Map<String, int>? threatCards,
    Map<int, int>? combatCards,
    Map<int, Set<int>>? excludedLoadouts,
    Map<int, int>? weaponQuantities,
    this.modifierFuelCost = 0,
    this.modifierAttackRoll = 0,
    this.modifierEvasion = 0,
    this.modifierAltitudeCost = 0,
    this.modifierTargetAcquisition = 0,
    this.modifierThreatDetermination = 0,
    this.scenarioId,
    this.state = 'Draft',
    this.versionNumber = 1,
  })  : selectedDroneIds = selectedDroneIds ?? {},
        targetCards = targetCards ?? {},
        threatCards = threatCards ?? {},
        combatCards = combatCards ?? {},
        excludedLoadouts = excludedLoadouts ?? {},
        weaponQuantities = weaponQuantities ?? {};

  int get totalTargetCards => targetCards.values.fold(0, (a, b) => a + b);
  int get totalThreatCards => threatCards.values.fold(0, (a, b) => a + b);
  int get totalCombatCards => combatCards.values.fold(0, (a, b) => a + b);
}

/// Validation error with field name and message.
class ValidationError {
  final String field;
  final String message;
  const ValidationError(this.field, this.message);
  @override
  String toString() => '$field: $message';
}

/// Summary row for the scenario list display.
class ScenarioListItem {
  final int id;
  final String name;
  final String? shortDescription;
  final String state;
  final String? difficultyRating;
  final int versionNumber;
  final String? modifiedDate;
  final int droneCount;
  final int targetCardCount;
  final int threatCardCount;
  final int combatCardCount;

  const ScenarioListItem({
    required this.id,
    required this.name,
    this.shortDescription,
    required this.state,
    this.difficultyRating,
    required this.versionNumber,
    this.modifiedDate,
    this.droneCount = 0,
    this.targetCardCount = 0,
    this.threatCardCount = 0,
    this.combatCardCount = 0,
  });
}

/// CRUD service for the Scenario Designer tool.
/// Uses raw sqflite queries via [DatabaseService].
class ScenarioDesignerService {

  // ─── Schema init ──────────────────────────────────────────────────────────

  /// Create/migrate designer tables. Safe to call multiple times.
  static Future<void> initSchema() async {
    // Ensure the scenarios table exists (fresh install)
    await DatabaseService.rawExecute('''
      CREATE TABLE IF NOT EXISTS scenarios (
        id               INTEGER PRIMARY KEY AUTOINCREMENT,
        name             TEXT NOT NULL,
        description      TEXT,
        location         TEXT,
        scoring_mode     TEXT,
        special_rules    TEXT,
        intro_text       TEXT,
        overview         TEXT,
        narrative        TEXT,
        threat_rules     TEXT,
        target_rules     TEXT,
        combat_rules     TEXT,
        starting_fuel    INTEGER,
        starting_damage_sens  INTEGER,
        starting_damage_comms INTEGER,
        primary_objective     TEXT,
        secondary_objective   TEXT,
        mission_briefing_text TEXT,
        loadout_rules         TEXT,
        short_description     TEXT,
        difficulty_rating     TEXT DEFAULT 'Medium',
        estimated_play_time_minutes INTEGER DEFAULT 30,
        tags                  TEXT,
        author_name           TEXT DEFAULT 'Oscar',
        version_number        INTEGER DEFAULT 1,
        thumbnail_image_path  TEXT,
        designer_notes        TEXT,
        state                 TEXT DEFAULT 'Draft',
        modified_date         TIMESTAMP,
        modifier_fuel_cost    INTEGER DEFAULT 0,
        modifier_attack_roll  INTEGER DEFAULT 0,
        modifier_evasion      INTEGER DEFAULT 0,
        modifier_altitude_cost INTEGER DEFAULT 0,
        modifier_target_acquisition   INTEGER DEFAULT 0,
        modifier_threat_determination INTEGER DEFAULT 0
      )
    ''');

    // Migrate: add any columns that may be missing on older installs
    final alterColumns = <String>[
      'short_description TEXT',
      "difficulty_rating TEXT DEFAULT 'Medium'",
      'estimated_play_time_minutes INTEGER DEFAULT 30',
      'tags TEXT',
      "author_name TEXT DEFAULT 'Oscar'",
      'version_number INTEGER DEFAULT 1',
      'thumbnail_image_path TEXT',
      'designer_notes TEXT',
      "state TEXT DEFAULT 'Draft'",
      'modified_date TIMESTAMP',
      'modifier_fuel_cost INTEGER DEFAULT 0',
      'modifier_attack_roll INTEGER DEFAULT 0',
      'modifier_evasion INTEGER DEFAULT 0',
      'modifier_altitude_cost INTEGER DEFAULT 0',
      'modifier_target_acquisition INTEGER DEFAULT 0',
      'modifier_threat_determination INTEGER DEFAULT 0',
      'primary_objective_vp_threshold INTEGER',
      'secondary_objective_card_name TEXT',
      'secondary_objective_vp_threshold INTEGER',
      'secondary_objective_vp_bonus REAL DEFAULT 0.0',
      'primary_objective_card_name TEXT',
      'primary_objective_target_type TEXT',
      'primary_objective_target_count INTEGER',
      'secondary_objective_target_type TEXT',
      'secondary_objective_target_count INTEGER',
    ];

    for (final col in alterColumns) {
      final colName = col.split(' ').first;
      try {
        // Check if column already exists
        final rows = await DatabaseService.rawQuery(
          "PRAGMA table_info(scenarios)",
        );
        final exists = rows.any((r) => r['name'] == colName);
        if (!exists) {
          await DatabaseService.rawExecute(
            'ALTER TABLE scenarios ADD COLUMN $col',
          );
        }
      } catch (_) {
        // Column may already exist, ignore
      }
    }

    // Junction tables
    await DatabaseService.rawExecute('''
      CREATE TABLE IF NOT EXISTS scenario_designer_drones (
        scenario_id INTEGER NOT NULL,
        drone_id    INTEGER NOT NULL,
        FOREIGN KEY (scenario_id) REFERENCES scenarios(id) ON DELETE CASCADE,
        FOREIGN KEY (drone_id)    REFERENCES drones(id),
        PRIMARY KEY (scenario_id, drone_id)
      )
    ''');
    await DatabaseService.rawExecute('''
      CREATE TABLE IF NOT EXISTS scenario_designer_target_cards (
        scenario_id    INTEGER NOT NULL,
        target_card_id INTEGER NOT NULL,
        quantity       INTEGER NOT NULL DEFAULT 1 CHECK(quantity > 0),
        FOREIGN KEY (scenario_id)    REFERENCES scenarios(id) ON DELETE CASCADE,
        FOREIGN KEY (target_card_id) REFERENCES target_cards(id),
        PRIMARY KEY (scenario_id, target_card_id)
      )
    ''');
    await DatabaseService.rawExecute('''
      CREATE TABLE IF NOT EXISTS scenario_designer_threat_cards (
        scenario_id    INTEGER NOT NULL,
        threat_card_id TEXT    NOT NULL,
        quantity       INTEGER NOT NULL DEFAULT 1 CHECK(quantity > 0),
        FOREIGN KEY (scenario_id)    REFERENCES scenarios(id) ON DELETE CASCADE,
        FOREIGN KEY (threat_card_id) REFERENCES threat_cards(card_number),
        PRIMARY KEY (scenario_id, threat_card_id)
      )
    ''');
    await DatabaseService.rawExecute('''
      CREATE TABLE IF NOT EXISTS scenario_designer_combat_cards (
        scenario_id    INTEGER NOT NULL,
        combat_card_id INTEGER NOT NULL,
        quantity       INTEGER NOT NULL DEFAULT 1 CHECK(quantity > 0),
        FOREIGN KEY (scenario_id)    REFERENCES scenarios(id) ON DELETE CASCADE,
        FOREIGN KEY (combat_card_id) REFERENCES combat_cards(id),
        PRIMARY KEY (scenario_id, combat_card_id)
      )
    ''');
    await DatabaseService.rawExecute('''
      CREATE TABLE IF NOT EXISTS scenario_designer_excluded_loadouts (
        id            INTEGER PRIMARY KEY AUTOINCREMENT,
        scenario_id   INTEGER NOT NULL,
        drone_id      INTEGER NOT NULL,
        option_index  INTEGER NOT NULL,
        FOREIGN KEY (scenario_id) REFERENCES scenarios(id) ON DELETE CASCADE,
        FOREIGN KEY (drone_id)    REFERENCES drones(id)
      )
    ''');

    // Indexes (safe with IF NOT EXISTS)
    await DatabaseService.rawExecute(
      'CREATE INDEX IF NOT EXISTS idx_scenarios_state ON scenarios(state)',
    );
    await DatabaseService.rawExecute(
      'CREATE INDEX IF NOT EXISTS idx_scenarios_modified ON scenarios(modified_date DESC)',
    );

    // ── Sprint 1 tables ────────────────────────────────────────

    // Player Profiles
    await DatabaseService.rawExecute('''
      CREATE TABLE IF NOT EXISTS player_profiles (
        profile_id    INTEGER PRIMARY KEY AUTOINCREMENT,
        profile_name  TEXT NOT NULL UNIQUE,
        created_date  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        last_played_date TIMESTAMP,
        total_missions_completed INTEGER DEFAULT 0,
        total_vp_earned INTEGER DEFAULT 0
      )
    ''');

    // Scenario Progress (per-profile statistics)
    await DatabaseService.rawExecute('''
      CREATE TABLE IF NOT EXISTS scenario_progress (
        profile_id   INTEGER NOT NULL,
        scenario_id  INTEGER NOT NULL,
        times_played INTEGER DEFAULT 0,
        times_completed INTEGER DEFAULT 0,
        best_score_vp INTEGER DEFAULT 0,
        last_played_date TIMESTAMP,
        FOREIGN KEY (profile_id) REFERENCES player_profiles(profile_id) ON DELETE CASCADE,
        FOREIGN KEY (scenario_id) REFERENCES scenarios(id) ON DELETE CASCADE,
        PRIMARY KEY (profile_id, scenario_id)
      )
    ''');

    // Scenario Weapons (designer weapon restrictions)
    await DatabaseService.rawExecute('''
      CREATE TABLE IF NOT EXISTS scenario_weapons (
        scenario_id INTEGER NOT NULL,
        weapon_id   INTEGER NOT NULL,
        quantity    INTEGER NOT NULL DEFAULT 1,
        FOREIGN KEY (scenario_id) REFERENCES scenarios(id) ON DELETE CASCADE,
        FOREIGN KEY (weapon_id) REFERENCES weapons(id),
        PRIMARY KEY (scenario_id, weapon_id)
      )
    ''');
    // Migration: add quantity column if table existed before this column was added
    try {
      await DatabaseService.rawExecute(
        'ALTER TABLE scenario_weapons ADD COLUMN quantity INTEGER NOT NULL DEFAULT 1',
      );
    } catch (_) {
      // Column already exists — ignore
    }

    // Game State Saves (save/continue)
    await DatabaseService.rawExecute('''
      CREATE TABLE IF NOT EXISTS game_saves (
        save_id       INTEGER PRIMARY KEY AUTOINCREMENT,
        profile_id    INTEGER NOT NULL,
        scenario_id   INTEGER NOT NULL,
        drone_id      INTEGER NOT NULL,
        loadout_data  TEXT NOT NULL,
        game_state_data TEXT NOT NULL,
        saved_date    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (profile_id) REFERENCES player_profiles(profile_id) ON DELETE CASCADE,
        FOREIGN KEY (scenario_id) REFERENCES scenarios(id),
        FOREIGN KEY (drone_id) REFERENCES drones(id)
      )
    ''');

    // Sprint 1 indexes
    await DatabaseService.rawExecute(
      'CREATE INDEX IF NOT EXISTS idx_profile_name ON player_profiles(profile_name)',
    );
    await DatabaseService.rawExecute(
      'CREATE INDEX IF NOT EXISTS idx_scenario_progress_profile ON scenario_progress(profile_id)',
    );
    await DatabaseService.rawExecute(
      'CREATE INDEX IF NOT EXISTS idx_scenario_progress_scenario ON scenario_progress(scenario_id)',
    );
    await DatabaseService.rawExecute(
      'CREATE INDEX IF NOT EXISTS idx_scenario_weapons_scenario ON scenario_weapons(scenario_id)',
    );
    await DatabaseService.rawExecute(
      'CREATE INDEX IF NOT EXISTS idx_game_saves_profile ON game_saves(profile_id)',
    );
  }

  // ─── List / Read ──────────────────────────────────────────────────────────

  /// Get all scenarios as summary items with junction counts.
  static Future<List<ScenarioListItem>> getAllScenarios({
    String? stateFilter,
    String sortBy = 'name',
    bool ascending = true,
  }) async {
    final where = stateFilter != null ? 'WHERE s.state = ?' : '';
    final args = stateFilter != null ? [stateFilter] : <Object>[];
    final dir = ascending ? 'ASC' : 'DESC';
    String orderField;
    switch (sortBy) {
      case 'date':
        orderField = 's.modified_date';
        break;
      case 'difficulty':
        orderField = "CASE s.difficulty_rating "
            "WHEN 'Easy' THEN 1 "
            "WHEN 'Medium' THEN 2 "
            "WHEN 'Hard' THEN 3 "
            "WHEN 'Expert' THEN 4 "
            "ELSE 5 END";
        break;
      default:
        orderField = 's.name';
    }

    final rows = await DatabaseService.rawQuery('''
      SELECT s.id, s.name, s.short_description, s.state,
             s.difficulty_rating, s.version_number, s.modified_date,
             COALESCE(d.cnt, 0) AS drone_count,
             COALESCE(tc.cnt, 0) AS target_count,
             COALESCE(thc.cnt, 0) AS threat_count,
             COALESCE(cc.cnt, 0) AS combat_count
      FROM scenarios s
      LEFT JOIN (SELECT scenario_id, COUNT(*) AS cnt FROM scenario_designer_drones GROUP BY scenario_id) d ON d.scenario_id = s.id
      LEFT JOIN (SELECT scenario_id, SUM(quantity) AS cnt FROM scenario_designer_target_cards GROUP BY scenario_id) tc ON tc.scenario_id = s.id
      LEFT JOIN (SELECT scenario_id, SUM(quantity) AS cnt FROM scenario_designer_threat_cards GROUP BY scenario_id) thc ON thc.scenario_id = s.id
      LEFT JOIN (SELECT scenario_id, SUM(quantity) AS cnt FROM scenario_designer_combat_cards GROUP BY scenario_id) cc ON cc.scenario_id = s.id
      $where
      ORDER BY $orderField $dir
    ''', args);

    return rows.map((r) => ScenarioListItem(
      id: r['id'] as int,
      name: r['name'] as String,
      shortDescription: r['short_description'] as String?,
      state: r['state'] as String? ?? 'Draft',
      difficultyRating: r['difficulty_rating'] as String?,
      versionNumber: r['version_number'] as int? ?? 1,
      modifiedDate: r['modified_date'] as String?,
      droneCount: r['drone_count'] as int? ?? 0,
      targetCardCount: r['target_count'] as int? ?? 0,
      threatCardCount: r['threat_count'] as int? ?? 0,
      combatCardCount: r['combat_count'] as int? ?? 0,
    )).toList();
  }

  /// Load full scenario data for editing.
  static Future<DesignerScenarioData> loadForEdit(int scenarioId) async {
    final rows = await DatabaseService.rawQuery(
      'SELECT * FROM scenarios WHERE id = ?', [scenarioId],
    );
    if (rows.isEmpty) throw Exception('Scenario $scenarioId not found');
    final s = rows.first;

    // Load junctions
    final droneRows = await DatabaseService.rawQuery(
      'SELECT drone_id FROM scenario_designer_drones WHERE scenario_id = ?',
      [scenarioId],
    );
    final targetRows = await DatabaseService.rawQuery(
      'SELECT target_card_id, quantity FROM scenario_designer_target_cards WHERE scenario_id = ?',
      [scenarioId],
    );
    final threatRows = await DatabaseService.rawQuery(
      'SELECT threat_card_id, quantity FROM scenario_designer_threat_cards WHERE scenario_id = ?',
      [scenarioId],
    );
    final combatRows = await DatabaseService.rawQuery(
      'SELECT combat_card_id, quantity FROM scenario_designer_combat_cards WHERE scenario_id = ?',
      [scenarioId],
    );
    final excludedRows = await DatabaseService.rawQuery(
      'SELECT drone_id, option_index FROM scenario_designer_excluded_loadouts WHERE scenario_id = ?',
      [scenarioId],
    );
    final weaponRows = await DatabaseService.rawQuery(
      'SELECT weapon_id, quantity FROM scenario_weapons WHERE scenario_id = ?',
      [scenarioId],
    );

    List<String> parsedTags = [];
    if (s['tags'] != null) {
      try { parsedTags = List<String>.from(jsonDecode(s['tags'] as String)); } catch (_) {}
    }

    // Build excluded loadouts map
    final excMap = <int, Set<int>>{};
    for (final r in excludedRows) {
      final droneId = r['drone_id'] as int;
      final optIdx = r['option_index'] as int;
      excMap.putIfAbsent(droneId, () => <int>{}).add(optIdx);
    }

    return DesignerScenarioData(
      scenarioId: scenarioId,
      title: s['name'] as String? ?? '',
      shortDescription: s['short_description'] as String? ?? '',
      overviewText: s['overview'] as String? ?? '',
      missionBriefing: s['mission_briefing_text'] as String? ?? '',
      primaryObjective: s['primary_objective'] as String? ?? '',
      primaryObjectiveCardName: s['primary_objective_card_name'] as String?,
      primaryObjectiveVpThreshold: s['primary_objective_vp_threshold'] as int?,
      primaryObjectiveTargetType: s['primary_objective_target_type'] as String?,
      primaryObjectiveTargetCount: s['primary_objective_target_count'] as int?,
      secondaryObjective: s['secondary_objective'] as String? ?? '',
      secondaryObjectiveCardName: s['secondary_objective_card_name'] as String?,
      secondaryObjectiveVpThreshold: s['secondary_objective_vp_threshold'] as int?,
      secondaryObjectiveTargetType: s['secondary_objective_target_type'] as String?,
      secondaryObjectiveTargetCount: s['secondary_objective_target_count'] as int?,
      secondaryObjectiveVpBonus: (s['secondary_objective_vp_bonus'] as num?)?.toDouble() ?? 0.0,
      difficultyRating: s['difficulty_rating'] as String? ?? 'Medium',
      estimatedPlayTimeMinutes: s['estimated_play_time_minutes'] as int? ?? 30,
      tags: parsedTags,
      authorName: s['author_name'] as String? ?? 'Oscar',
      designerNotes: s['designer_notes'] as String? ?? '',
      thumbnailImagePath: s['thumbnail_image_path'] as String?,
      state: s['state'] as String? ?? 'Draft',
      versionNumber: s['version_number'] as int? ?? 1,
      selectedDroneIds: droneRows.map((r) => r['drone_id'] as int).toSet(),
      targetCards: { for (final r in targetRows) r['target_card_id'] as int: r['quantity'] as int },
      threatCards: { for (final r in threatRows) r['threat_card_id'] as String: r['quantity'] as int },
      combatCards: { for (final r in combatRows) r['combat_card_id'] as int: r['quantity'] as int },
      excludedLoadouts: excMap,
      weaponQuantities: { for (final r in weaponRows) r['weapon_id'] as int: r['quantity'] as int? ?? 1 },
      modifierFuelCost: s['modifier_fuel_cost'] as int? ?? 0,
      modifierAttackRoll: s['modifier_attack_roll'] as int? ?? 0,
      modifierEvasion: s['modifier_evasion'] as int? ?? 0,
      modifierAltitudeCost: s['modifier_altitude_cost'] as int? ?? 0,
      modifierTargetAcquisition: s['modifier_target_acquisition'] as int? ?? 0,
      modifierThreatDetermination: s['modifier_threat_determination'] as int? ?? 0,
    );
  }

  // ─── Validation ───────────────────────────────────────────────────────────

  /// Validate scenario data. Returns empty list if valid.
  static List<ValidationError> validate(DesignerScenarioData data) {
    final errors = <ValidationError>[];

    if (data.title.trim().isEmpty) {
      errors.add(const ValidationError('title', 'Title is required'));
    } else if (data.title.length > 100) {
      errors.add(const ValidationError('title', 'Title must be ≤ 100 characters'));
    }
    if (data.shortDescription.trim().isEmpty) {
      errors.add(const ValidationError('shortDescription', 'Short description is required'));
    } else if (data.shortDescription.length > 200) {
      errors.add(const ValidationError('shortDescription', 'Short description must be ≤ 200 characters'));
    }
    if (data.overviewText.trim().isEmpty) {
      errors.add(const ValidationError('overview', 'Overview text is required'));
    } else if (data.overviewText.length > 1000) {
      errors.add(const ValidationError('overview', 'Overview must be ≤ 1000 characters'));
    }
    if (data.missionBriefing.trim().isEmpty) {
      errors.add(const ValidationError('missionBriefing', 'Mission briefing is required'));
    } else if (data.missionBriefing.length > 1000) {
      errors.add(const ValidationError('missionBriefing', 'Mission briefing must be ≤ 1000 characters'));
    }
    if (data.primaryObjective.trim().isEmpty) {
      errors.add(const ValidationError('primaryObjective', 'Primary objective is required'));
    } else if (data.primaryObjective.length > 500) {
      errors.add(const ValidationError('primaryObjective', 'Primary objective must be ≤ 500 characters'));
    }
    if (data.secondaryObjective.length > 500) {
      errors.add(const ValidationError('secondaryObjective', 'Secondary objective must be ≤ 500 characters'));
    }
    if (data.designerNotes.length > 2000) {
      errors.add(const ValidationError('designerNotes', 'Designer notes must be ≤ 2000 characters'));
    }

    // Drones
    if (data.selectedDroneIds.isEmpty) {
      errors.add(const ValidationError('drones', 'Must select at least 1 drone'));
    }

    // Cards
    if (data.totalTargetCards < 5) {
      errors.add(const ValidationError('targetCards', 'Must have at least 5 target cards'));
    }
    if (data.totalTargetCards > 100) {
      errors.add(const ValidationError('targetCards', 'Maximum 100 target cards allowed'));
    }
    if (data.totalThreatCards < 5) {
      errors.add(const ValidationError('threatCards', 'Must have at least 5 threat cards'));
    }
    if (data.totalThreatCards > 100) {
      errors.add(const ValidationError('threatCards', 'Maximum 100 threat cards allowed'));
    }
    if (data.totalCombatCards < 5) {
      errors.add(const ValidationError('combatCards', 'Must have at least 5 combat cards'));
    }
    if (data.totalCombatCards > 100) {
      errors.add(const ValidationError('combatCards', 'Maximum 100 combat cards allowed'));
    }

    return errors;
  }

  // ─── Save / Update ────────────────────────────────────────────────────────

  /// Save scenario (insert or update) and all junction tables.
  /// Returns the scenario ID.
  static Future<int> saveScenario(DesignerScenarioData data, {bool publish = false}) async {
    final state = publish ? 'Published' : data.state;

    // Validate if publishing
    if (publish) {
      final errors = validate(data);
      if (errors.isNotEmpty) {
        throw Exception('Validation failed: ${errors.map((e) => e.message).join(', ')}');
      }
    }

    final now = DateTime.now().toIso8601String();
    final tagsJson = jsonEncode(data.tags);

    int scenarioId;

    if (data.scenarioId != null) {
      // ── UPDATE existing ──
      scenarioId = data.scenarioId!;
      await DatabaseService.rawExecute('''
        UPDATE scenarios SET
          name = ?, short_description = ?, overview = ?,
          mission_briefing_text = ?, primary_objective = ?,
          secondary_objective = ?, difficulty_rating = ?,
          estimated_play_time_minutes = ?, tags = ?,
          author_name = ?, thumbnail_image_path = ?,
          designer_notes = ?, state = ?,
          version_number = version_number + 1,
          modified_date = ?,
          modifier_fuel_cost = ?, modifier_attack_roll = ?,
          modifier_evasion = ?, modifier_altitude_cost = ?,
          modifier_target_acquisition = ?, modifier_threat_determination = ?,
          primary_objective_card_name = ?, primary_objective_vp_threshold = ?,
          secondary_objective_card_name = ?, secondary_objective_vp_threshold = ?,
          secondary_objective_vp_bonus = ?,
          primary_objective_target_type = ?, primary_objective_target_count = ?,
          secondary_objective_target_type = ?, secondary_objective_target_count = ?
        WHERE id = ?
      ''', [
        data.title.trim(), data.shortDescription.trim(), data.overviewText.trim(),
        data.missionBriefing.trim(), data.primaryObjective.trim(),
        data.secondaryObjective.trim().isEmpty ? null : data.secondaryObjective.trim(),
        data.difficultyRating, data.estimatedPlayTimeMinutes, tagsJson,
        data.authorName.trim(), data.thumbnailImagePath,
        data.designerNotes.trim().isEmpty ? null : data.designerNotes.trim(),
        state, now,
        data.modifierFuelCost, data.modifierAttackRoll,
        data.modifierEvasion, data.modifierAltitudeCost,
        data.modifierTargetAcquisition, data.modifierThreatDetermination,
        data.primaryObjectiveCardName?.trim().isNotEmpty == true ? data.primaryObjectiveCardName!.trim() : null,
        data.primaryObjectiveVpThreshold,
        data.secondaryObjectiveCardName?.trim().isNotEmpty == true ? data.secondaryObjectiveCardName!.trim() : null,
        data.secondaryObjectiveVpThreshold,
        data.secondaryObjectiveVpBonus > 0 ? data.secondaryObjectiveVpBonus : null,
        data.primaryObjectiveTargetType?.trim().isNotEmpty == true ? data.primaryObjectiveTargetType!.trim() : null,
        data.primaryObjectiveTargetCount,
        data.secondaryObjectiveTargetType?.trim().isNotEmpty == true ? data.secondaryObjectiveTargetType!.trim() : null,
        data.secondaryObjectiveTargetCount,
        scenarioId,
      ]);
    } else {
      // ── INSERT new ──
      scenarioId = await DatabaseService.rawInsert('''
        INSERT INTO scenarios (
          name, short_description, overview,
          mission_briefing_text, primary_objective,
          secondary_objective, difficulty_rating,
          estimated_play_time_minutes, tags,
          author_name, thumbnail_image_path,
          designer_notes, state, version_number,
          modified_date, scoring_mode,
          modifier_fuel_cost, modifier_attack_roll,
          modifier_evasion, modifier_altitude_cost,
          modifier_target_acquisition, modifier_threat_determination,
          primary_objective_card_name, primary_objective_vp_threshold,
          secondary_objective_card_name, secondary_objective_vp_threshold,
          secondary_objective_vp_bonus,
          primary_objective_target_type, primary_objective_target_count,
          secondary_objective_target_type, secondary_objective_target_count
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 1, ?, 'MAXIMUM_KILL', ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''', [
        data.title.trim(), data.shortDescription.trim(), data.overviewText.trim(),
        data.missionBriefing.trim(), data.primaryObjective.trim(),
        data.secondaryObjective.trim().isEmpty ? null : data.secondaryObjective.trim(),
        data.difficultyRating, data.estimatedPlayTimeMinutes, tagsJson,
        data.authorName.trim(), data.thumbnailImagePath,
        data.designerNotes.trim().isEmpty ? null : data.designerNotes.trim(),
        state, now,
        data.modifierFuelCost, data.modifierAttackRoll,
        data.modifierEvasion, data.modifierAltitudeCost,
        data.modifierTargetAcquisition, data.modifierThreatDetermination,
        data.primaryObjectiveCardName?.trim().isNotEmpty == true ? data.primaryObjectiveCardName!.trim() : null,
        data.primaryObjectiveVpThreshold,
        data.secondaryObjectiveCardName?.trim().isNotEmpty == true ? data.secondaryObjectiveCardName!.trim() : null,
        data.secondaryObjectiveVpThreshold,
        data.secondaryObjectiveVpBonus > 0 ? data.secondaryObjectiveVpBonus : null,
        data.primaryObjectiveTargetType?.trim().isNotEmpty == true ? data.primaryObjectiveTargetType!.trim() : null,
        data.primaryObjectiveTargetCount,
        data.secondaryObjectiveTargetType?.trim().isNotEmpty == true ? data.secondaryObjectiveTargetType!.trim() : null,
        data.secondaryObjectiveTargetCount,
      ]);
    }

    // ── Replace junction tables ──
    await _replaceJunctions(scenarioId, data);

    return scenarioId;
  }

  /// Delete all junction records and re-insert from data.
  static Future<void> _replaceJunctions(int scenarioId, DesignerScenarioData data) async {
    // Clear existing
    await DatabaseService.rawExecute('DELETE FROM scenario_designer_drones WHERE scenario_id = ?', [scenarioId]);
    await DatabaseService.rawExecute('DELETE FROM scenario_designer_target_cards WHERE scenario_id = ?', [scenarioId]);
    await DatabaseService.rawExecute('DELETE FROM scenario_designer_threat_cards WHERE scenario_id = ?', [scenarioId]);
    await DatabaseService.rawExecute('DELETE FROM scenario_designer_combat_cards WHERE scenario_id = ?', [scenarioId]);
    await DatabaseService.rawExecute('DELETE FROM scenario_designer_excluded_loadouts WHERE scenario_id = ?', [scenarioId]);
    await DatabaseService.rawExecute('DELETE FROM scenario_weapons WHERE scenario_id = ?', [scenarioId]);

    // Insert drones
    for (final droneId in data.selectedDroneIds) {
      await DatabaseService.rawInsert(
        'INSERT INTO scenario_designer_drones (scenario_id, drone_id) VALUES (?, ?)',
        [scenarioId, droneId],
      );
    }
    // Insert target cards
    for (final e in data.targetCards.entries) {
      await DatabaseService.rawInsert(
        'INSERT INTO scenario_designer_target_cards (scenario_id, target_card_id, quantity) VALUES (?, ?, ?)',
        [scenarioId, e.key, e.value],
      );
    }
    // Insert threat cards
    for (final e in data.threatCards.entries) {
      await DatabaseService.rawInsert(
        'INSERT INTO scenario_designer_threat_cards (scenario_id, threat_card_id, quantity) VALUES (?, ?, ?)',
        [scenarioId, e.key, e.value],
      );
    }
    // Insert combat cards
    for (final e in data.combatCards.entries) {
      await DatabaseService.rawInsert(
        'INSERT INTO scenario_designer_combat_cards (scenario_id, combat_card_id, quantity) VALUES (?, ?, ?)',
        [scenarioId, e.key, e.value],
      );
    }
    // Insert excluded loadouts
    for (final entry in data.excludedLoadouts.entries) {
      for (final optIdx in entry.value) {
        await DatabaseService.rawInsert(
          'INSERT INTO scenario_designer_excluded_loadouts (scenario_id, drone_id, option_index) VALUES (?, ?, ?)',
          [scenarioId, entry.key, optIdx],
        );
      }
    }
    // Insert weapon restrictions
    for (final entry in data.weaponQuantities.entries) {
      await DatabaseService.rawInsert(
        'INSERT INTO scenario_weapons (scenario_id, weapon_id, quantity) VALUES (?, ?, ?)',
        [scenarioId, entry.key, entry.value],
      );
    }
  }

  // ─── Delete / State ───────────────────────────────────────────────────────

  /// Permanently delete a scenario and all junction data.
  static Future<void> deleteScenario(int scenarioId) async {
    // Delete junctions first (in case CASCADE not honoured by sqflite)
    await DatabaseService.rawExecute('DELETE FROM scenario_designer_drones WHERE scenario_id = ?', [scenarioId]);
    await DatabaseService.rawExecute('DELETE FROM scenario_designer_target_cards WHERE scenario_id = ?', [scenarioId]);
    await DatabaseService.rawExecute('DELETE FROM scenario_designer_threat_cards WHERE scenario_id = ?', [scenarioId]);
    await DatabaseService.rawExecute('DELETE FROM scenario_designer_combat_cards WHERE scenario_id = ?', [scenarioId]);
    await DatabaseService.rawExecute('DELETE FROM scenario_designer_excluded_loadouts WHERE scenario_id = ?', [scenarioId]);
    await DatabaseService.rawExecute('DELETE FROM scenario_weapons WHERE scenario_id = ?', [scenarioId]);
    await DatabaseService.rawExecute('DELETE FROM scenarios WHERE id = ?', [scenarioId]);
  }

  /// Change scenario state (Draft / Published / Inactive).
  static Future<void> setScenarioState(int scenarioId, String newState) async {
    final now = DateTime.now().toIso8601String();
    await DatabaseService.rawExecute(
      'UPDATE scenarios SET state = ?, modified_date = ? WHERE id = ?',
      [newState, now, scenarioId],
    );
  }

  // ─── Clone ────────────────────────────────────────────────────────────────

  /// Clone a scenario: duplicate with "(Copy)" title and Draft state.
  /// Returns the new scenario ID.
  static Future<int> cloneScenario(int sourceId) async {
    final data = await loadForEdit(sourceId);
    data.scenarioId = null;  // Force INSERT
    data.title = '${data.title} (Copy)';
    data.state = 'Draft';
    data.versionNumber = 1;
    return saveScenario(data);
  }
}
