import 'dart:convert';
import '../services/database_service.dart';

/// A single kill objective: "destroy N of card X"
class KillCondition {
  String cardNumber;   // e.g. "TCTA001"
  String cardName;     // e.g. "T-72"
  String category;     // e.g. "TANK"
  int quantity;        // how many to kill

  KillCondition({
    required this.cardNumber,
    required this.cardName,
    required this.category,
    this.quantity = 1,
  });

  Map<String, dynamic> toJson() => {
    'card_number': cardNumber,
    'card_name': cardName,
    'category': category,
    'quantity': quantity,
  };

  factory KillCondition.fromJson(Map<String, dynamic> json) => KillCondition(
    cardNumber: json['card_number'] as String,
    cardName: json['card_name'] as String,
    category: json['category'] as String,
    quantity: json['quantity'] as int? ?? 1,
  );
}

/// Data class holding the full designer state for a scenario,
/// including its junction table data (selected drones, cards).
class DesignerScenarioData {
  // -- Step 1: Basic Info --
  String title;
  double version;  // Starts at 1.00, +0.01 per save
  String shortDescription;
  String overviewText;
  String missionBriefing;
  String primaryObjective;
  String? primaryObjectiveCardName;      // Legacy single-card field
  int? primaryObjectiveVpThreshold;
  String? primaryObjectiveTargetType;
  int? primaryObjectiveTargetCount;
  List<KillCondition> primaryKillConditions;   // NEW: multi-card kills
  bool primaryVpEnabled;            // checkbox: Min VP condition active
  bool primaryKillCountEnabled;     // checkbox: Min Kill Count condition active
  bool primaryKillTargetsEnabled;   // checkbox: Kill Targets condition active
  String secondaryObjective;
  String? secondaryObjectiveCardName;    // Legacy single-card field
  int? secondaryObjectiveVpThreshold;
  String? secondaryObjectiveTargetType;
  int? secondaryObjectiveTargetCount;
  double secondaryObjectiveVpBonus;
  List<KillCondition> secondaryKillConditions; // NEW: multi-card kills
  bool secondaryVpEnabled;
  bool secondaryKillCountEnabled;
  bool secondaryKillTargetsEnabled;
  String difficultyRating;
  int estimatedPlayTimeMinutes;
  List<String> tags;
  String authorName;
  String designerNotes;
  String? thumbnailImagePath;
  String? missionBriefingImagePath;  // Visual displayed above mission briefing

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
  // versionNumber removed — using `version` (double) instead

  DesignerScenarioData({
    this.title = '',
    this.version = 1.00,
    this.shortDescription = '',
    this.overviewText = '',
    this.missionBriefing = '',
    this.primaryObjective = '',
    this.primaryObjectiveCardName,
    this.primaryObjectiveVpThreshold,
    this.primaryObjectiveTargetType,
    this.primaryObjectiveTargetCount,
    List<KillCondition>? primaryKillConditions,
    this.primaryVpEnabled = false,
    this.primaryKillCountEnabled = false,
    this.primaryKillTargetsEnabled = false,
    this.secondaryObjective = '',
    this.secondaryObjectiveCardName,
    this.secondaryObjectiveVpThreshold,
    this.secondaryObjectiveTargetType,
    this.secondaryObjectiveTargetCount,
    this.secondaryObjectiveVpBonus = 0.0,
    List<KillCondition>? secondaryKillConditions,
    this.secondaryVpEnabled = false,
    this.secondaryKillCountEnabled = false,
    this.secondaryKillTargetsEnabled = false,
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
    // versionNumber removed — using `version` (double)
  })  : selectedDroneIds = selectedDroneIds ?? {},
        targetCards = targetCards ?? {},
        threatCards = threatCards ?? {},
        combatCards = combatCards ?? {},
        excludedLoadouts = excludedLoadouts ?? {},
        weaponQuantities = weaponQuantities ?? {},
        primaryKillConditions = primaryKillConditions ?? [],
        secondaryKillConditions = secondaryKillConditions ?? [];

  int get totalTargetCards => targetCards.values.fold(0, (a, b) => a + b);
  int get totalThreatCards => threatCards.values.fold(0, (a, b) => a + b);
  int get totalCombatCards => combatCards.values.fold(0, (a, b) => a + b);

  /// Serialize kill conditions to JSON for DB storage
  String? get primaryKillConditionsJson =>
      primaryKillConditions.isEmpty ? null : jsonEncode(primaryKillConditions.map((e) => e.toJson()).toList());
  String? get secondaryKillConditionsJson =>
      secondaryKillConditions.isEmpty ? null : jsonEncode(secondaryKillConditions.map((e) => e.toJson()).toList());

  /// Load kill conditions from JSON
  static List<KillCondition> parseKillConditions(String? json) {
    if (json == null || json.isEmpty) return [];
    try {
      final list = jsonDecode(json) as List;
      return list.map((e) => KillCondition.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // .ob3scenario TEXT EXPORT / IMPORT
  // ═══════════════════════════════════════════════════════════════════════════

  /// Serialize to .ob3scenario text format (human-readable, re-importable).
  String toOb3Scenario() {
    final sb = StringBuffer();
    sb.writeln('# OB3 Scenario Export Format v1');
    sb.writeln('# Each line is KEY=VALUE. Lines starting with # are comments.');
    sb.writeln('# This file can be imported back into the Scenario Editor.');
    sb.writeln('');

    sb.writeln('# --- Metadata ---');
    sb.writeln('SCENARIO_NAME=$title                     # Scenario title (max 100 chars)');
    sb.writeln('VERSION=${version.toStringAsFixed(2)}                        # Scenario version (auto-incremented)');
    sb.writeln('STATUS=$state                            # DRAFT | PUBLISHED | INACTIVE');
    sb.writeln('DESCRIPTION=$shortDescription            # Short description (max 200 chars)');
    sb.writeln('NARRATIVE=${missionBriefing.replaceAll('\n', '\\n')}  # Mission briefing text (\\n for newlines)');
    sb.writeln('OVERVIEW=${overviewText.replaceAll('\n', '\\n')}       # Overview text (\\n for newlines)');
    sb.writeln('DIFFICULTY=$difficultyRating              # Easy | Medium | Hard | Extreme');
    sb.writeln('PLAY_TIME_MINUTES=$estimatedPlayTimeMinutes  # Estimated play time');
    sb.writeln('AUTHOR=$authorName                       # Author name');
    sb.writeln('DESIGNER_NOTES=${designerNotes.replaceAll('\n', '\\n')}  # Designer notes');
    sb.writeln('');

    sb.writeln('# --- Drone & Rules ---');
    sb.writeln('SELECTED_DRONES=${selectedDroneIds.join(',')}  # Comma-separated drone IDs (empty = all)');
    sb.writeln('SCORING_MODE=QUICK_KILL                  # MAXIMUM_KILL | QUICK_KILL');
    sb.writeln('');

    sb.writeln('# --- Primary Objective ---');
    sb.writeln('PRIMARY_OBJECTIVE=${primaryObjective.replaceAll('\n', '\\n')}  # Objective description');
    sb.writeln('PRIMARY_VP_ENABLED=$primaryVpEnabled     # Is Min VP condition active?');
    sb.writeln('PRIMARY_VP_THRESHOLD=${primaryObjectiveVpThreshold ?? ''}  # Min VP to win (if enabled)');
    sb.writeln('PRIMARY_KILL_COUNT_ENABLED=$primaryKillCountEnabled  # Is Min Kill Count active?');
    sb.writeln('PRIMARY_KILL_COUNT=${primaryObjectiveTargetCount ?? ''}  # Min total kills (if enabled)');
    sb.writeln('PRIMARY_KILL_TARGETS_ENABLED=$primaryKillTargetsEnabled  # Is specific kill list active?');
    sb.writeln('PRIMARY_KILL_TARGETS=${_serializeKillConditions(primaryKillConditions)}  # category:name:qty, ...');
    sb.writeln('');

    sb.writeln('# --- Secondary Objective ---');
    sb.writeln('SECONDARY_OBJECTIVE=${secondaryObjective.replaceAll('\n', '\\n')}  # Secondary description');
    sb.writeln('SECONDARY_VP_ENABLED=$secondaryVpEnabled');
    sb.writeln('SECONDARY_VP_THRESHOLD=${secondaryObjectiveVpThreshold ?? ''}');
    sb.writeln('SECONDARY_VP_BONUS=${secondaryObjectiveVpBonus > 0 ? secondaryObjectiveVpBonus.toStringAsFixed(1) : '0.0'}  # Bonus VP for completing secondary');
    sb.writeln('SECONDARY_KILL_COUNT_ENABLED=$secondaryKillCountEnabled');
    sb.writeln('SECONDARY_KILL_COUNT=${secondaryObjectiveTargetCount ?? ''}');
    sb.writeln('SECONDARY_KILL_TARGETS_ENABLED=$secondaryKillTargetsEnabled');
    sb.writeln('SECONDARY_KILL_TARGETS=${_serializeKillConditions(secondaryKillConditions)}');
    sb.writeln('');

    sb.writeln('# --- Card Decks (card_id:quantity pairs) ---');
    sb.writeln('TARGET_CARDS=${_serializeMap(targetCards)}  # target card id:qty pairs');
    sb.writeln('THREAT_CARDS=${_serializeStringMap(threatCards)}  # threat card_number:qty pairs');
    sb.writeln('COMBAT_CARDS=${_serializeMap(combatCards)}  # combat card id:qty pairs');
    sb.writeln('');

    sb.writeln('# --- Modifiers ---');
    sb.writeln('MOD_FUEL_COST=$modifierFuelCost           # Fuel cost modifier');
    sb.writeln('MOD_ATTACK_ROLL=$modifierAttackRoll       # Attack roll modifier');
    sb.writeln('MOD_EVASION=$modifierEvasion              # Evasion modifier');
    sb.writeln('MOD_ALTITUDE_COST=$modifierAltitudeCost   # Altitude change cost modifier');
    sb.writeln('MOD_TARGET_ACQ=$modifierTargetAcquisition # Target acquisition modifier');
    sb.writeln('MOD_THREAT_DET=$modifierThreatDetermination  # Threat determination modifier');
    sb.writeln('');

    sb.writeln('# --- Tags ---');
    sb.writeln('TAGS=${tags.join(',')}                    # Comma-separated tags');

    return sb.toString();
  }

  static String _serializeKillConditions(List<KillCondition> conditions) =>
      conditions.map((c) => '${c.category}:${c.cardName}:${c.quantity}').join(',');

  static String _serializeMap(Map<int, int> map) =>
      map.entries.map((e) => '${e.key}:${e.value}').join(',');

  static String _serializeStringMap(Map<String, int> map) =>
      map.entries.map((e) => '${e.key}:${e.value}').join(',');

  /// Parse a .ob3scenario text file back into DesignerScenarioData.
  static DesignerScenarioData fromOb3Scenario(String content) {
    final map = <String, String>{};
    for (final line in content.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
      final eqIdx = trimmed.indexOf('=');
      if (eqIdx < 0) continue;
      final key = trimmed.substring(0, eqIdx).trim();
      // Strip inline comment (everything after # that isn't inside the value)
      var val = trimmed.substring(eqIdx + 1);
      final commentIdx = val.lastIndexOf('  #');
      if (commentIdx > 0) val = val.substring(0, commentIdx);
      map[key] = val.trim();
    }

    String str(String key) => (map[key] ?? '').replaceAll('\\n', '\n');
    int? intOr(String key) => map[key] != null && map[key]!.isNotEmpty ? int.tryParse(map[key]!) : null;
    double dbl(String key) => double.tryParse(map[key] ?? '') ?? 0.0;
    bool boolOf(String key) => map[key]?.toLowerCase() == 'true';

    return DesignerScenarioData(
      title: str('SCENARIO_NAME'),
      version: 1.00,  // Import always starts at 1.00
      shortDescription: str('DESCRIPTION'),
      overviewText: str('OVERVIEW'),
      missionBriefing: str('NARRATIVE'),
      primaryObjective: str('PRIMARY_OBJECTIVE'),
      primaryVpEnabled: boolOf('PRIMARY_VP_ENABLED'),
      primaryObjectiveVpThreshold: intOr('PRIMARY_VP_THRESHOLD'),
      primaryKillCountEnabled: boolOf('PRIMARY_KILL_COUNT_ENABLED'),
      primaryObjectiveTargetCount: intOr('PRIMARY_KILL_COUNT'),
      primaryKillTargetsEnabled: boolOf('PRIMARY_KILL_TARGETS_ENABLED'),
      primaryKillConditions: _parseKillConditionsText(str('PRIMARY_KILL_TARGETS')),
      secondaryObjective: str('SECONDARY_OBJECTIVE'),
      secondaryVpEnabled: boolOf('SECONDARY_VP_ENABLED'),
      secondaryObjectiveVpThreshold: intOr('SECONDARY_VP_THRESHOLD'),
      secondaryObjectiveVpBonus: dbl('SECONDARY_VP_BONUS'),
      secondaryKillCountEnabled: boolOf('SECONDARY_KILL_COUNT_ENABLED'),
      secondaryObjectiveTargetCount: intOr('SECONDARY_KILL_COUNT'),
      secondaryKillTargetsEnabled: boolOf('SECONDARY_KILL_TARGETS_ENABLED'),
      secondaryKillConditions: _parseKillConditionsText(str('SECONDARY_KILL_TARGETS')),
      difficultyRating: str('DIFFICULTY').isNotEmpty ? str('DIFFICULTY') : 'Medium',
      estimatedPlayTimeMinutes: intOr('PLAY_TIME_MINUTES') ?? 30,
      authorName: str('AUTHOR').isNotEmpty ? str('AUTHOR') : 'Oscar',
      designerNotes: str('DESIGNER_NOTES'),
      selectedDroneIds: _parseIntSet(str('SELECTED_DRONES')),
      targetCards: _parseIntMap(str('TARGET_CARDS')),
      threatCards: _parseStringMap(str('THREAT_CARDS')),
      combatCards: _parseIntMap(str('COMBAT_CARDS')),
      modifierFuelCost: intOr('MOD_FUEL_COST') ?? 0,
      modifierAttackRoll: intOr('MOD_ATTACK_ROLL') ?? 0,
      modifierEvasion: intOr('MOD_EVASION') ?? 0,
      modifierAltitudeCost: intOr('MOD_ALTITUDE_COST') ?? 0,
      modifierTargetAcquisition: intOr('MOD_TARGET_ACQ') ?? 0,
      modifierThreatDetermination: intOr('MOD_THREAT_DET') ?? 0,
      tags: str('TAGS').isNotEmpty ? str('TAGS').split(',').map((s) => s.trim()).toList() : [],
      state: 'Draft',  // Import always starts as Draft
    );
  }

  static List<KillCondition> _parseKillConditionsText(String text) {
    if (text.isEmpty) return [];
    return text.split(',').where((s) => s.contains(':')).map((s) {
      final parts = s.split(':');
      return KillCondition(
        cardNumber: '',  // Will be resolved when editing
        cardName: parts.length > 1 ? parts[1] : parts[0],
        category: parts[0],
        quantity: parts.length > 2 ? (int.tryParse(parts[2]) ?? 1) : 1,
      );
    }).toList();
  }

  static Set<int> _parseIntSet(String text) {
    if (text.isEmpty) return {};
    return text.split(',').map((s) => int.tryParse(s.trim())).whereType<int>().toSet();
  }

  static Map<int, int> _parseIntMap(String text) {
    if (text.isEmpty) return {};
    final map = <int, int>{};
    for (final pair in text.split(',')) {
      final parts = pair.split(':');
      if (parts.length == 2) {
        final k = int.tryParse(parts[0].trim());
        final v = int.tryParse(parts[1].trim());
        if (k != null && v != null) map[k] = v;
      }
    }
    return map;
  }

  static Map<String, int> _parseStringMap(String text) {
    if (text.isEmpty) return {};
    final map = <String, int>{};
    for (final pair in text.split(',')) {
      final parts = pair.split(':');
      if (parts.length == 2) {
        final v = int.tryParse(parts[1].trim());
        if (v != null) map[parts[0].trim()] = v;
      }
    }
    return map;
  }
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
  final double version;
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
    required this.version,
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
      'overview TEXT',
      'mission_briefing_text TEXT',
      'primary_objective TEXT',
      'secondary_objective TEXT',
      'scoring_mode TEXT',
      'special_rules TEXT',
      'intro_text TEXT',
      'narrative TEXT',
      'threat_rules TEXT',
      'target_rules TEXT',
      'combat_rules TEXT',
      'starting_fuel INTEGER',
      'starting_damage_sens INTEGER',
      'starting_damage_comms INTEGER',
      'loadout_rules TEXT',
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
      'mission_briefing_image_path TEXT',
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
      version: (r['version_number'] as num?)?.toDouble() ?? 1.0,
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
      version: (s['version_number'] as num?)?.toDouble() ?? 1.0,
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
          version_number = ?,
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
        state, data.version, now,
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
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'MAXIMUM_KILL', ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''', [
        data.title.trim(), data.shortDescription.trim(), data.overviewText.trim(),
        data.missionBriefing.trim(), data.primaryObjective.trim(),
        data.secondaryObjective.trim().isEmpty ? null : data.secondaryObjective.trim(),
        data.difficultyRating, data.estimatedPlayTimeMinutes, tagsJson,
        data.authorName.trim(), data.thumbnailImagePath,
        data.designerNotes.trim().isEmpty ? null : data.designerNotes.trim(),
        state, data.version, now,
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
    data.version = 1.0;
    return saveScenario(data);
  }
}
