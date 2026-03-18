import 'dart:io';
import 'scenario_designer_service.dart';
import 'database_service.dart';

/// Result of importing a scenario file.
/// Contains the parsed data and a list of warnings for invalid references.
class ImportResult {
  final DesignerScenarioData data;
  final List<String> warnings;
  const ImportResult({required this.data, this.warnings = const []});
  bool get hasWarnings => warnings.isNotEmpty;
}

/// Import/export service for scenario data using human-editable text files.
class ScenarioImportExport {

  /// Result of an import operation: the parsed data plus any warnings.
  static ImportResult? lastImportResult;

  /// Generate a blank template file that can be filled in externally.
  static String exportTemplate() {
    return '''# ═══════════════════════════════════════════════════════════════════════
# DRONE COMMANDER — SCENARIO TEMPLATE
# ═══════════════════════════════════════════════════════════════════════
#
# HOW TO USE THIS TEMPLATE
# ────────────────────────
# 1. Fill in the fields below (each field is KEY: VALUE format)
# 2. Save this file (keep the .txt extension)
# 3. In the Designer Tool > SCENARIOS tab > ⋮ menu > "Import from File"
# 4. Select this file — the wizard opens pre-populated with your data
# 5. Review, adjust, and save/publish from within the wizard
#
# RULES
# ─────
# • Lines starting with # are comments — they are ignored on import.
# • Fields marked [REQUIRED] must be filled in or validation will fail.
# • Leave optional fields blank or at their default to skip them.
# • Multi-line fields use "|" after the colon, then indent with 2 spaces:
#       OVERVIEW: |
#         First paragraph text here.
#         Second paragraph continues here.
#
# WHAT HAPPENS ON ERRORS
# ──────────────────────
# • If a REQUIRED text field is left blank: the wizard opens but
#   validation will show an error on the Review step. You can still
#   edit it inside the wizard before saving.
# • If a number field contains non-numeric text (e.g. "abc" instead
#   of "30"): it defaults to 0 (modifiers) or 30 (play time).
# • If DIFFICULTY contains an unrecognized value: it is stored as-is
#   but the UI dropdown will show it. Valid: Easy, Medium, Hard, Expert.
# • If a drone ID doesn't exist in the database: it is silently
#   skipped. Check the wizard's drone selection step carefully.
# • If a card ID:quantity pair is malformed (missing colon, bad ID):
#   that entry is skipped silently. Other valid entries still import.
# • Text fields have NO hard length limit in the database (SQLite TEXT
#   columns are unbounded), but the UI may truncate display:
#     - TITLE: recommended max 60 chars (list view truncates longer)
#     - SHORT_DESCRIPTION: recommended max 120 chars (single line)
#     - OVERVIEW/BRIEFING: any length (scrollable in wizard)
#     - PRIMARY/SECONDARY_OBJECTIVE: recommended max 200 chars
#     - TAGS: each tag recommended max 20 chars
#
# ═══════════════════════════════════════════════════════════════════════

# ── BASIC INFO ──────────────────────────────────────────────────────────
#
# TITLE            [REQUIRED] [TEXT, max ~60 chars recommended]
#                  The scenario name shown in mission select and designer list.
#
# SHORT_DESCRIPTION [REQUIRED] [TEXT, max ~120 chars recommended]
#                  One-line summary. Shown below the title in mission select.
#
# DIFFICULTY       [TEXT] One of: Easy, Medium, Hard, Expert
#                  Shown as a badge. Defaults to "Medium" if omitted.
#
# PLAY_TIME_MINUTES [INTEGER, default: 30]
#                  Estimated play time. Must be a whole number.
#                  Non-numeric text defaults to 30.
#
# AUTHOR           [TEXT] Designer name. Metadata only, not shown to players.
#
# TAGS             [TEXT, comma-separated] e.g. "Desert, Night Ops, Urban"
#                  Used for filtering in the designer. Each tag max ~20 chars.

TITLE: 
SHORT_DESCRIPTION: 
DIFFICULTY: Medium
PLAY_TIME_MINUTES: 30
AUTHOR: 
TAGS: 

# ── MISSION NARRATIVE ───────────────────────────────────────────────────
#
# OVERVIEW         [REQUIRED] [TEXT, multi-line with "| " syntax]
#                  Describes the scenario setting and context.
#                  Shown to the player in the mission briefing screen.
#
# MISSION_BRIEFING [REQUIRED] [TEXT, multi-line]
#                  Tactical briefing text shown before mission start.
#
# PRIMARY_OBJECTIVE   [REQUIRED] [TEXT, max ~200 chars recommended]
#                  Main win condition displayed to the player.
#
# SECONDARY_OBJECTIVE [TEXT, max ~200 chars, optional]
#                  Bonus goal. Shown alongside the primary objective.

OVERVIEW: |
  

MISSION_BRIEFING: |
  

PRIMARY_OBJECTIVE: 
SECONDARY_OBJECTIVE: 

# ── DESIGNER NOTES ──────────────────────────────────────────────────────
# Internal only — NOT shown to players. No length limit.

DESIGNER_NOTES: |
  

# ── AVAILABLE DRONES ────────────────────────────────────────────────────
#
# [COMMA-SEPARATED INTEGERS or "ALL"]
#
# Use "ALL" to include every drone in the database.
# Or list specific drone IDs: 1, 3, 5
#
# To find drone IDs, run in the Designer Tool SQL tab:
#   SELECT id, name FROM drones
#
# Non-existent IDs are silently ignored.
# At least 1 valid drone must be selected or validation warns.

DRONES: ALL

# ── LOADOUT RESTRICTIONS ───────────────────────────────────────────────
#
# EXCLUDED_LOADOUTS [COMMA-SEPARATED, format: drone_id:option_index]
#
# By default all drone loadout presets are available.
# To restrict a specific preset for a specific drone, add it here.
# option_index is 1, 2, or 3 (matching the drone's loadout options).
#
# Example: 1:3, 2:2  (exclude option 3 from drone 1, option 2 from drone 2)
# Leave blank for no restrictions.

EXCLUDED_LOADOUTS: 

# ── CARD POOLS ──────────────────────────────────────────────────────────
#
# Format: card_identifier:quantity, card_identifier:quantity, ...
# Example: 1:3, 2:2, 5:1  (card ID 1 x3 copies, card ID 2 x2 copies)
#
# • If quantity is omitted or non-numeric, defaults to 1.
# • Non-existent card IDs are silently skipped.
# • Malformed pairs (missing colon) are skipped silently.
# • Validation requires at least 5 total for target and threat pools.
#
# TARGET_CARDS     [card_id:qty] — card_id is INTEGER
#   Query: SELECT id, card_name, sub_category FROM target_cards
#
# THREAT_CARDS     [card_number:qty] — card_number is TEXT (e.g. "T01")
#   WARNING: Threat cards use card_number (text string), NOT numeric id!
#   Query: SELECT card_number, card_name FROM threat_cards
#
# COMBAT_CARDS     [card_id:qty] — card_id is INTEGER
#   Query: SELECT id, card_name FROM combat_cards

TARGET_CARDS: 
THREAT_CARDS: 
COMBAT_CARDS: 

# ── CUSTOM MODIFIERS ────────────────────────────────────────────────────
#
# All modifiers are INTEGERS. Default is 0 (no change).
# Positive = advantage for player (easier).
# Negative = disadvantage (harder).
# Non-numeric values default to 0. No hard min/max but +/-5 is typical.
#
# MODIFIER_FUEL_COST             Adjusts fuel consumption per move
# MODIFIER_ATTACK_ROLL           Added to attack dice rolls
# MODIFIER_EVASION               Added to evasion checks
# MODIFIER_ALTITUDE_COST         Adjusts fuel cost of altitude changes
# MODIFIER_TARGET_ACQUISITION    Added to Target Acquisition DRM
#                                (directly affects combat resolution)
# MODIFIER_THREAT_DETERMINATION  Added to Threat Determination DRM
#                                (directly affects combat resolution)

MODIFIER_FUEL_COST: 0
MODIFIER_ATTACK_ROLL: 0
MODIFIER_EVASION: 0
MODIFIER_ALTITUDE_COST: 0
MODIFIER_TARGET_ACQUISITION: 0
MODIFIER_THREAT_DETERMINATION: 0
''';
  }

  /// Export an existing scenario to a comprehensive text file.
  /// All fields are included (filled or empty) with # remarks explaining each.
  static Future<String> exportScenario(int scenarioId) async {
    final data = await ScenarioDesignerService.loadForEdit(scenarioId);

    final targetStr = data.targetCards.entries
        .map((e) => '${e.key}:${e.value}')
        .join(', ');
    final threatStr = data.threatCards.entries
        .map((e) => '${e.key}:${e.value}')
        .join(', ');
    final combatStr = data.combatCards.entries
        .map((e) => '${e.key}:${e.value}')
        .join(', ');
    final droneStr = data.selectedDroneIds.isEmpty
        ? 'ALL'
        : data.selectedDroneIds.join(', ');
    final primaryKillStr = data.primaryKillConditions
        .map((c) => '${c.category}:${c.cardName}:${c.quantity}')
        .join(', ');
    final secondaryKillStr = data.secondaryKillConditions
        .map((c) => '${c.category}:${c.cardName}:${c.quantity}')
        .join(', ');
    final exclStr = _formatExcludedLoadouts(data.excludedLoadouts);

    return '''# ═══════════════════════════════════════════════════════════════════════
# OB3 DRONE COMMANDER — SCENARIO FILE (v1)
# ═══════════════════════════════════════════════════════════════════════
#
# HOW TO USE THIS FILE
# ────────────────────
# 1. Each line is KEY: VALUE format.
# 2. Lines starting with # are comments — ignored on import.
# 3. Multi-line text fields use "|" after the colon, then indent with
#    2 spaces on following lines:
#        OVERVIEW: |
#          First paragraph here.
#          Second paragraph here.
# 4. To import: In the Designer Tool > SCENARIOS > ⋮ menu > "Import
#    from File", select this .txt file.
# 5. The wizard opens pre-populated. Review, adjust, and Save/Publish.
#
# FIELD STATUS
# ────────────
# • [REQUIRED] fields must be filled or validation will fail.
# • [OPTIONAL] fields can be left blank.
# • [AUTO] fields are managed by the editor — you can override them.
# • Number fields default to 0 if invalid.
# • Boolean fields accept: true / false (case-insensitive).
#
# ═══════════════════════════════════════════════════════════════════════


# ── SECTION 1: BASIC INFORMATION ──────────────────────────────────────

# TITLE [REQUIRED] [TEXT, max ~60 chars recommended]
# The scenario name shown in mission select and designer list.
# Example:
#   TITLE: Operation Desert Storm
TITLE: ${data.title}

# VERSION [AUTO] [DECIMAL, e.g. 1.00]
# Starts at 1.00 for new scenarios. Incremented by 0.01 on each save.
# Example:
#   VERSION: 1.05
VERSION: ${data.version.toStringAsFixed(2)}

# STATUS [AUTO] [TEXT: Draft | Published | Inactive]
# Only "Published" scenarios appear in the game.
# Example:
#   STATUS: Published
STATUS: ${data.state}

# SHORT_DESCRIPTION [REQUIRED] [TEXT, max ~120 chars recommended]
# One-line summary shown below the title in mission select.
# Example:
#   SHORT_DESCRIPTION: Neutralize enemy armor column advancing through the valley
SHORT_DESCRIPTION: ${data.shortDescription}

# DIFFICULTY [OPTIONAL] [TEXT: Easy | Medium | Hard | Expert]
# Shown as a difficulty badge. Defaults to "Medium" if blank.
# Example:
#   DIFFICULTY: Hard
DIFFICULTY: ${data.difficultyRating}

# PLAY_TIME_MINUTES [OPTIONAL] [INTEGER, default: 30]
# Estimated play time in minutes. Shown in mission select.
# Example:
#   PLAY_TIME_MINUTES: 45
PLAY_TIME_MINUTES: ${data.estimatedPlayTimeMinutes}

# AUTHOR [OPTIONAL] [TEXT]
# Designer/author name. For credits.
# Example:
#   AUTHOR: Oscar
AUTHOR: ${data.authorName}

# TAGS [OPTIONAL] [TEXT, comma-separated]
# Used for filtering in the scenario browser.
# Example:
#   TAGS: Desert, Night Ops, Armored Targets
TAGS: ${data.tags.join(', ')}


# ── SECTION 2: MISSION NARRATIVE ─────────────────────────────────────

# OVERVIEW [REQUIRED] [TEXT, multi-line with "| " syntax]
# Describes the scenario setting and context.
# Displayed on the briefing screen before the mission starts.
# Example:
#   OVERVIEW: |
#     An enemy armored column has been spotted advancing through
#     the Azrak Valley. Intelligence reports indicate T-72 tanks
#     supported by mobile SAM units.
OVERVIEW: |
  ${data.overviewText.replaceAll('\n', '\n  ')}

# MISSION_BRIEFING_IMAGE [OPTIONAL] [TEXT — base64 data URI or URL]
# An image displayed above the mission briefing text.
# The editor stores uploaded images as base64 data URIs (data:image/jpeg;base64,...).
# You can also use a full URL (https://example.com/image.jpg).
# Leave blank for no image.
# Example:
#   MISSION_BRIEFING_IMAGE: https://example.com/desert_map.jpg
MISSION_BRIEFING_IMAGE: ${data.missionBriefingImagePath ?? ''}

# MISSION_BRIEFING [REQUIRED] [TEXT, multi-line with "| " syntax]
# Tactical briefing text shown to the player before the mission.
# Example:
#   MISSION_BRIEFING: |
#     Commander, your mission is to intercept and destroy the
#     enemy armor column before it reaches the bridge at grid
#     reference Alpha-7. Expect heavy anti-air resistance.
#     Rules of engagement: weapons free on all hostile targets.
MISSION_BRIEFING: |
  ${data.missionBriefing.replaceAll('\n', '\n  ')}

# DESIGNER_NOTES [OPTIONAL] [TEXT, multi-line with "| " syntax]
# Internal notes — NOT shown to players. For designer reference only.
# Example:
#   DESIGNER_NOTES: |
#     Balanced for intermediate players. Reduce threats if too hard.
#     v1.03: Added extra fuel modifier after playtesting.
DESIGNER_NOTES: |
  ${data.designerNotes.replaceAll('\n', '\n  ')}


# ── SECTION 3: PRIMARY OBJECTIVE ─────────────────────────────────────

# PRIMARY_OBJECTIVE [REQUIRED] [TEXT, max ~200 chars recommended]
# The main win condition displayed to the player.
# Example:
#   PRIMARY_OBJECTIVE: Destroy all enemy armored vehicles in the valley
PRIMARY_OBJECTIVE: ${data.primaryObjective}

# PRIMARY_VP_ENABLED [OPTIONAL] [BOOLEAN: true | false]
# If true, the player must reach the VP threshold to complete primary.
# Example:
#   PRIMARY_VP_ENABLED: true
PRIMARY_VP_ENABLED: ${data.primaryVpEnabled}

# PRIMARY_VP_THRESHOLD [OPTIONAL] [INTEGER]
# Minimum Victory Points required (only checked if VP_ENABLED = true).
# Example:
#   PRIMARY_VP_THRESHOLD: 15
PRIMARY_VP_THRESHOLD: ${data.primaryObjectiveVpThreshold ?? ''}

# PRIMARY_KILL_COUNT_ENABLED [OPTIONAL] [BOOLEAN: true | false]
# If true, player must destroy at least this many targets total.
# Example:
#   PRIMARY_KILL_COUNT_ENABLED: true
PRIMARY_KILL_COUNT_ENABLED: ${data.primaryKillCountEnabled}

# PRIMARY_KILL_COUNT [OPTIONAL] [INTEGER]
# Minimum total kills required (only checked if KILL_COUNT_ENABLED = true).
# Example:
#   PRIMARY_KILL_COUNT: 5
PRIMARY_KILL_COUNT: ${data.primaryObjectiveTargetCount ?? ''}

# PRIMARY_KILL_TARGETS_ENABLED [OPTIONAL] [BOOLEAN: true | false]
# If true, specific target cards must be destroyed.
# Example:
#   PRIMARY_KILL_TARGETS_ENABLED: true
PRIMARY_KILL_TARGETS_ENABLED: ${data.primaryKillTargetsEnabled}

# PRIMARY_KILL_TARGETS [OPTIONAL] [TEXT, comma-separated]
# Format: category:card_name:quantity
# Multiple targets separated by commas.
# Example:
#   PRIMARY_KILL_TARGETS: Vehicle:T-72 Tank:2, Structure:Radar Array:1
PRIMARY_KILL_TARGETS: $primaryKillStr


# ── SECTION 4: SECONDARY OBJECTIVE ───────────────────────────────────

# SECONDARY_OBJECTIVE [OPTIONAL] [TEXT, max ~200 chars recommended]
# Bonus goal displayed alongside the primary objective.
# Leave blank if no secondary objective.
# Example:
#   SECONDARY_OBJECTIVE: Destroy the enemy command post for bonus VP
SECONDARY_OBJECTIVE: ${data.secondaryObjective}

# SECONDARY_VP_ENABLED [OPTIONAL] [BOOLEAN: true | false]
# Example:
#   SECONDARY_VP_ENABLED: true
SECONDARY_VP_ENABLED: ${data.secondaryVpEnabled}

# SECONDARY_VP_THRESHOLD [OPTIONAL] [INTEGER]
# Example:
#   SECONDARY_VP_THRESHOLD: 10
SECONDARY_VP_THRESHOLD: ${data.secondaryObjectiveVpThreshold ?? ''}

# SECONDARY_VP_BONUS [OPTIONAL] [DECIMAL, default: 0.0]
# Bonus VP awarded if the secondary objective is completed.
# Example:
#   SECONDARY_VP_BONUS: 5.0
SECONDARY_VP_BONUS: ${data.secondaryObjectiveVpBonus > 0 ? data.secondaryObjectiveVpBonus.toStringAsFixed(1) : '0.0'}

# SECONDARY_KILL_COUNT_ENABLED [OPTIONAL] [BOOLEAN: true | false]
# Example:
#   SECONDARY_KILL_COUNT_ENABLED: false
SECONDARY_KILL_COUNT_ENABLED: ${data.secondaryKillCountEnabled}

# SECONDARY_KILL_COUNT [OPTIONAL] [INTEGER]
# Example:
#   SECONDARY_KILL_COUNT: 3
SECONDARY_KILL_COUNT: ${data.secondaryObjectiveTargetCount ?? ''}

# SECONDARY_KILL_TARGETS_ENABLED [OPTIONAL] [BOOLEAN: true | false]
# Example:
#   SECONDARY_KILL_TARGETS_ENABLED: true
SECONDARY_KILL_TARGETS_ENABLED: ${data.secondaryKillTargetsEnabled}

# SECONDARY_KILL_TARGETS [OPTIONAL] [TEXT, comma-separated]
# Same format as PRIMARY_KILL_TARGETS.
# Example:
#   SECONDARY_KILL_TARGETS: Structure:Command Post:1
SECONDARY_KILL_TARGETS: $secondaryKillStr


# ── SECTION 5: AVAILABLE DRONES ──────────────────────────────────────

# DRONES [OPTIONAL] [TEXT: "ALL" or comma-separated integers]
# Use "ALL" to include every drone in the database.
# Or list specific drone IDs separated by commas.
# Non-existent IDs are silently ignored.
# To find drone IDs: SELECT id, name FROM drones
# Example (all drones):
#   DRONES: ALL
# Example (specific drones):
#   DRONES: 1, 3, 5
DRONES: $droneStr


# ── SECTION 6: LOADOUT RESTRICTIONS ──────────────────────────────────

# EXCLUDED_LOADOUTS [OPTIONAL] [TEXT, comma-separated]
# Format: drone_id:option_index
# option_index is 1, 2, or 3 (matching the drone's loadout presets).
# Leave blank for no restrictions.
# Example (block loadout 3 from drone 1, loadout 2 from drone 2):
#   EXCLUDED_LOADOUTS: 1:3, 2:2
EXCLUDED_LOADOUTS: $exclStr


# ── SECTION 7: CARD DECK COMPOSITION ─────────────────────────────────

# TARGET_CARDS [OPTIONAL] [TEXT, comma-separated]
# Format: card_id:quantity
# card_id is INTEGER referencing target_cards.id
# To find IDs: SELECT id, card_name, sub_category FROM target_cards
# Example (3 copies of card 12, 2 copies of card 7):
#   TARGET_CARDS: 12:3, 7:2, 15:1, 3:2, 9:1
TARGET_CARDS: $targetStr

# THREAT_CARDS [OPTIONAL] [TEXT, comma-separated]
# Format: card_number:quantity
# ⚠ IMPORTANT: Threat cards use card_number (TEXT like "T01"), NOT numeric id!
# To find them: SELECT card_number, card_name FROM threat_cards
# Example (2 copies of T01, 3 copies of T05):
#   THREAT_CARDS: T01:2, T05:3, T12:1, T03:2, T08:1
THREAT_CARDS: $threatStr

# COMBAT_CARDS [OPTIONAL] [TEXT, comma-separated]
# Format: card_id:quantity
# card_id is INTEGER referencing combat_cards.id
# To find IDs: SELECT id, card_name FROM combat_cards
# Example (4 copies of card 1, 2 copies of card 5):
#   COMBAT_CARDS: 1:4, 5:2, 3:3, 8:1, 12:2
COMBAT_CARDS: $combatStr


# ── SECTION 8: GAMEPLAY MODIFIERS ────────────────────────────────────
#
# All modifiers are INTEGERS. Default is 0 (no change).
# Positive = advantage for the player (easier scenario).
# Negative = disadvantage (harder scenario).
# Typical range: -5 to +5.

# Adjusts fuel consumption per move.
# Example (reduce fuel cost by 1 = easier):
#   MODIFIER_FUEL_COST: -1
MODIFIER_FUEL_COST: ${data.modifierFuelCost}

# Added to attack dice rolls.
# Example (boost attacks by 2 = easier):
#   MODIFIER_ATTACK_ROLL: 2
MODIFIER_ATTACK_ROLL: ${data.modifierAttackRoll}

# Added to evasion checks.
# Example (reduce evasion by 1 = harder):
#   MODIFIER_EVASION: -1
MODIFIER_EVASION: ${data.modifierEvasion}

# Adjusts fuel cost of altitude changes.
# Example (no change):
#   MODIFIER_ALTITUDE_COST: 0
MODIFIER_ALTITUDE_COST: ${data.modifierAltitudeCost}

# Added to Target Acquisition DRM (Die Roll Modifier in combat).
# Example (boost acquisition by 1 = easier):
#   MODIFIER_TARGET_ACQUISITION: 1
MODIFIER_TARGET_ACQUISITION: ${data.modifierTargetAcquisition}

# Added to Threat Determination DRM (Die Roll Modifier in combat).
# Example (increase threat by 2 = harder):
#   MODIFIER_THREAT_DETERMINATION: 2
MODIFIER_THREAT_DETERMINATION: ${data.modifierThreatDetermination}

# ═══════════════════════════════════════════════════════════════════════
# END OF SCENARIO FILE
# ═══════════════════════════════════════════════════════════════════════
''';
  }

  /// Parse a scenario text file, validate all IDs against the DB, and
  /// return an [ImportResult] containing the data and any warnings.
  static Future<ImportResult> importScenario(String fileContent) async {
    final data = DesignerScenarioData();
    final warnings = <String>[];
    final fields = _parseFields(fileContent);

    // Basic info
    data.title = fields['TITLE'] ?? '';
    data.shortDescription = fields['SHORT_DESCRIPTION'] ?? '';
    data.difficultyRating = fields['DIFFICULTY'] ?? 'Medium';
    data.estimatedPlayTimeMinutes = int.tryParse(fields['PLAY_TIME_MINUTES'] ?? '30') ?? 30;
    data.authorName = fields['AUTHOR'] ?? 'Oscar';
    if (fields['TAGS'] != null && fields['TAGS']!.isNotEmpty) {
      data.tags = fields['TAGS']!.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList();
    }

    // Text fields
    data.overviewText = fields['OVERVIEW'] ?? '';
    data.missionBriefing = fields['MISSION_BRIEFING'] ?? '';
    data.primaryObjective = fields['PRIMARY_OBJECTIVE'] ?? '';
    data.secondaryObjective = fields['SECONDARY_OBJECTIVE'] ?? '';
    data.designerNotes = fields['DESIGNER_NOTES'] ?? '';
    data.version = 1.0;  // Import always starts at v1.00

    // Primary objective conditions
    data.primaryVpEnabled = (fields['PRIMARY_VP_ENABLED'] ?? '').toLowerCase() == 'true';
    data.primaryObjectiveVpThreshold = int.tryParse(fields['PRIMARY_VP_THRESHOLD'] ?? '');
    data.primaryKillCountEnabled = (fields['PRIMARY_KILL_COUNT_ENABLED'] ?? '').toLowerCase() == 'true';
    data.primaryObjectiveTargetCount = int.tryParse(fields['PRIMARY_KILL_COUNT'] ?? '');
    data.primaryKillTargetsEnabled = (fields['PRIMARY_KILL_TARGETS_ENABLED'] ?? '').toLowerCase() == 'true';
    data.primaryKillConditions = _parseKillTargetsText(fields['PRIMARY_KILL_TARGETS'] ?? '');

    // Secondary objective conditions
    data.secondaryVpEnabled = (fields['SECONDARY_VP_ENABLED'] ?? '').toLowerCase() == 'true';
    data.secondaryObjectiveVpThreshold = int.tryParse(fields['SECONDARY_VP_THRESHOLD'] ?? '');
    data.secondaryObjectiveVpBonus = double.tryParse(fields['SECONDARY_VP_BONUS'] ?? '0') ?? 0.0;
    data.secondaryKillCountEnabled = (fields['SECONDARY_KILL_COUNT_ENABLED'] ?? '').toLowerCase() == 'true';
    data.secondaryObjectiveTargetCount = int.tryParse(fields['SECONDARY_KILL_COUNT'] ?? '');
    data.secondaryKillTargetsEnabled = (fields['SECONDARY_KILL_TARGETS_ENABLED'] ?? '').toLowerCase() == 'true';
    data.secondaryKillConditions = _parseKillTargetsText(fields['SECONDARY_KILL_TARGETS'] ?? '');

    // ── Drones (validate each ID) ──
    final dronesRaw = fields['DRONES'] ?? 'ALL';
    final allDbDrones = await DatabaseService.rawQuery('SELECT id FROM drones');
    final validDroneIds = allDbDrones.map((r) => r['id'] as int).toSet();

    if (dronesRaw.trim().toUpperCase() == 'ALL') {
      data.selectedDroneIds = validDroneIds;
    } else {
      for (final token in dronesRaw.split(',')) {
        final trimmed = token.trim();
        if (trimmed.isEmpty) continue;
        final id = int.tryParse(trimmed);
        if (id == null) {
          warnings.add('DRONES: "$trimmed" is not a valid integer — skipped');
        } else if (!validDroneIds.contains(id)) {
          warnings.add('DRONES: drone ID $id does not exist in the database');
        } else {
          data.selectedDroneIds.add(id);
        }
      }
    }

    // ── Target Cards (validate IDs) ──
    final allTargetIds = (await DatabaseService.rawQuery('SELECT id FROM target_cards'))
        .map((r) => r['id'] as int).toSet();
    final targetRaw = fields['TARGET_CARDS'] ?? '';
    if (targetRaw.trim().isNotEmpty) {
      for (final pair in targetRaw.split(',')) {
        final parts = pair.trim().split(':');
        if (parts.length != 2) {
          warnings.add('TARGET_CARDS: malformed entry "${pair.trim()}" — expected id:qty');
          continue;
        }
        final id = int.tryParse(parts[0].trim());
        final qty = int.tryParse(parts[1].trim());
        if (id == null) {
          warnings.add('TARGET_CARDS: "${parts[0].trim()}" is not a valid integer ID');
        } else if (!allTargetIds.contains(id)) {
          warnings.add('TARGET_CARDS: card ID $id does not exist in the database');
        } else {
          data.targetCards[id] = qty ?? 1;
        }
      }
    }

    // ── Threat Cards (validate card_numbers) ──
    final allThreatNumbers = (await DatabaseService.rawQuery('SELECT card_number FROM threat_cards'))
        .map((r) => r['card_number'] as String).toSet();
    final threatRaw = fields['THREAT_CARDS'] ?? '';
    if (threatRaw.trim().isNotEmpty) {
      for (final pair in threatRaw.split(',')) {
        final parts = pair.trim().split(':');
        if (parts.length != 2) {
          warnings.add('THREAT_CARDS: malformed entry "${pair.trim()}" — expected card_number:qty');
          continue;
        }
        final cardNum = parts[0].trim();
        final qty = int.tryParse(parts[1].trim());
        if (!allThreatNumbers.contains(cardNum)) {
          warnings.add('THREAT_CARDS: card "$cardNum" does not exist in the database');
        } else {
          data.threatCards[cardNum] = qty ?? 1;
        }
      }
    }

    // ── Combat Cards (validate IDs) ──
    final allCombatIds = (await DatabaseService.rawQuery('SELECT id FROM combat_cards'))
        .map((r) => r['id'] as int).toSet();
    final combatRaw = fields['COMBAT_CARDS'] ?? '';
    if (combatRaw.trim().isNotEmpty) {
      for (final pair in combatRaw.split(',')) {
        final parts = pair.trim().split(':');
        if (parts.length != 2) {
          warnings.add('COMBAT_CARDS: malformed entry "${pair.trim()}" — expected id:qty');
          continue;
        }
        final id = int.tryParse(parts[0].trim());
        final qty = int.tryParse(parts[1].trim());
        if (id == null) {
          warnings.add('COMBAT_CARDS: "${parts[0].trim()}" is not a valid integer ID');
        } else if (!allCombatIds.contains(id)) {
          warnings.add('COMBAT_CARDS: card ID $id does not exist in the database');
        } else {
          data.combatCards[id] = qty ?? 1;
        }
      }
    }

    // Modifiers
    data.modifierFuelCost = int.tryParse(fields['MODIFIER_FUEL_COST'] ?? '0') ?? 0;
    data.modifierAttackRoll = int.tryParse(fields['MODIFIER_ATTACK_ROLL'] ?? '0') ?? 0;
    data.modifierEvasion = int.tryParse(fields['MODIFIER_EVASION'] ?? '0') ?? 0;
    data.modifierAltitudeCost = int.tryParse(fields['MODIFIER_ALTITUDE_COST'] ?? '0') ?? 0;
    data.modifierTargetAcquisition = int.tryParse(fields['MODIFIER_TARGET_ACQUISITION'] ?? '0') ?? 0;
    data.modifierThreatDetermination = int.tryParse(fields['MODIFIER_THREAT_DETERMINATION'] ?? '0') ?? 0;

    // ── Excluded Loadouts (validate) ──
    final exclRaw = fields['EXCLUDED_LOADOUTS'] ?? '';
    if (exclRaw.trim().isNotEmpty) {
      for (final pair in exclRaw.split(',')) {
        final parts = pair.trim().split(':');
        if (parts.length != 2) {
          warnings.add('EXCLUDED_LOADOUTS: malformed entry "${pair.trim()}" — expected drone_id:option_index');
          continue;
        }
        final droneId = int.tryParse(parts[0].trim());
        final optIdx = int.tryParse(parts[1].trim());
        if (droneId == null || optIdx == null) {
          warnings.add('EXCLUDED_LOADOUTS: non-numeric values in "${pair.trim()}"');
        } else if (!validDroneIds.contains(droneId)) {
          warnings.add('EXCLUDED_LOADOUTS: drone ID $droneId does not exist');
        } else if (optIdx < 1 || optIdx > 3) {
          warnings.add('EXCLUDED_LOADOUTS: option_index must be 1, 2, or 3 (got $optIdx)');
        } else {
          data.excludedLoadouts.putIfAbsent(droneId, () => <int>{}).add(optIdx);
        }
      }
    }

    final result = ImportResult(data: data, warnings: warnings);
    lastImportResult = result;
    return result;
  }

  /// Parse key: value fields from the text file.
  /// Handles multi-line values indicated by "| " continuation.
  static Map<String, String> _parseFields(String content) {
    final fields = <String, String>{};
    String? currentKey;
    final buffer = StringBuffer();
    bool inMultiLine = false;

    for (final line in content.split('\n')) {
      // Skip comments
      if (line.trimLeft().startsWith('#')) continue;

      if (inMultiLine) {
        if (line.startsWith('  ') || line.trim().isEmpty) {
          // Continuation line
          if (buffer.isNotEmpty) buffer.write(' ');
          buffer.write(line.trim());
          continue;
        } else {
          // End of multiline
          if (currentKey != null) {
            fields[currentKey] = buffer.toString().trim();
          }
          inMultiLine = false;
          buffer.clear();
          currentKey = null;
        }
      }

      final colonIdx = line.indexOf(':');
      if (colonIdx == -1) continue;

      final key = line.substring(0, colonIdx).trim();
      final value = line.substring(colonIdx + 1).trim();

      if (value == '|') {
        // Multi-line block
        currentKey = key;
        inMultiLine = true;
        buffer.clear();
      } else {
        fields[key] = value;
      }
    }

    // Flush last multiline
    if (inMultiLine && currentKey != null) {
      fields[currentKey] = buffer.toString().trim();
    }

    return fields;
  }

  /// Format excluded loadouts map to string: "1:3, 2:2"
  static String _formatExcludedLoadouts(Map<int, Set<int>> excluded) {
    final parts = <String>[];
    for (final entry in excluded.entries) {
      for (final optIdx in entry.value) {
        parts.add('${entry.key}:$optIdx');
      }
    }
    return parts.join(', ');
  }

  /// Save template to a file and return the path.
  static Future<String> saveTemplateToFile() async {
    final dir = Directory('/tmp/dc_scenario_templates');
    if (!await dir.exists()) await dir.create(recursive: true);
    final file = File('${dir.path}/scenario_template.txt');
    await file.writeAsString(exportTemplate());
    return file.path;
  }

  /// Save scenario export to a file and return the path.
  static Future<String> saveExportToFile(int scenarioId, String title) async {
    final dir = Directory('/tmp/dc_scenario_templates');
    if (!await dir.exists()) await dir.create(recursive: true);
    final safeName = title.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_').toLowerCase();
    final file = File('${dir.path}/${safeName}.ob3scenario');
    await file.writeAsString(await exportScenario(scenarioId));
    return file.path;
  }

  /// Parse kill targets text: "category:name:qty, category:name:qty"
  static List<KillCondition> _parseKillTargetsText(String text) {
    if (text.trim().isEmpty) return [];
    return text.split(',').where((s) => s.trim().contains(':')).map((s) {
      final parts = s.trim().split(':');
      return KillCondition(
        cardNumber: '',  // Will be resolved when editing
        cardName: parts.length > 1 ? parts[1].trim() : parts[0].trim(),
        category: parts[0].trim(),
        quantity: parts.length > 2 ? (int.tryParse(parts[2].trim()) ?? 1) : 1,
      );
    }).toList();
  }
}
