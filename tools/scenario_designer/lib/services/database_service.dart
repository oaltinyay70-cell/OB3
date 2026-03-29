import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import '../models/card_models.dart';
import '../models/scenario_models.dart';

/// Provides read/write access to the database using FFI on Desktop or FFI Web on Browser.
class DatabaseService {
  static Database? _db;
  static const String _assetDbPath = 'assets/data/ob3.db';
  
  /// True if the database is available on this platform.
  static bool get isAvailable => !kIsWeb;

  /// Initialize the FFI database factory (required for macOS/desktop).
  static void initFfi() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  /// Opens (or returns cached) database connection.
  /// Copies the asset DB to a writable location on first launch,
  /// or when the asset DB is newer (larger size = schema update).
  static Future<Database> get database async {
    if (_db != null) return _db!;

    if (kIsWeb) {
      final dbPath = 'ob3.db';
      final factory = databaseFactoryFfiWeb;
      
      bool shouldWrite = false;
      if (!await factory.databaseExists(dbPath)) {
        print('[DB] Web DB does not exist, scheduling write...');
        shouldWrite = true;
      } else {
        try {
          final tempDb = await factory.openDatabase(dbPath);
          final res = await tempDb.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name='drones'");
          if (res.isEmpty) {
             print('[DB] Web DB exists but missing drones table, scheduling write...');
             shouldWrite = true;
          }
          await tempDb.close();
        } catch (e) {
          print('[DB] Error checking Web DB tables: $e');
          shouldWrite = true;
        }
      }

      if (shouldWrite) {
        try {
          print('[DB] Loading asset from: $_assetDbPath');
          final data = await rootBundle.load(_assetDbPath);
          final bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
          print('[DB] Asset loaded successfully. Length: ${bytes.length}');
          await factory.writeDatabaseBytes(dbPath, bytes);
          print('[DB] Asset written to web local storage.');
        } catch (e) {
          print('[DB] CRITICAL ERROR loading/writing asset: $e');
        }
      }
      
      _db = await factory.openDatabase(dbPath, options: OpenDatabaseOptions(
        onOpen: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
          await _runMigrations(db);
        }
      ));
      return _db!;
    } else {
      // ── macOS Desktop: open the GAME DB directly ──
      // Walk from this file's location up to OB3 project root:
      //   tools/scenario_designer/lib/services/database_service.dart
      //   → ../../../../assets/db/ob3.db
      // But at runtime Platform.script isn't reliable for Flutter desktop,
      // so we use Platform.environment or a fixed relative path from cwd.
      final cwd = Directory.current.path;
      // Expect cwd = OB3/tools/scenario_designer (where flutter run is invoked)
      final candidatePaths = [
        join(cwd, '..', '..', 'assets', 'db', 'ob3.db'),  // from tools/scenario_designer
        join(cwd, 'assets', 'db', 'ob3.db'),                // from OB3 root
      ];

      String? dbPath;
      for (final p in candidatePaths) {
        final f = File(p);
        if (f.existsSync()) {
          dbPath = f.resolveSymbolicLinksSync();
          break;
        }
      }

      if (dbPath == null) {
        throw StateError(
          'Cannot find OB3/assets/db/ob3.db from cwd=$cwd. '
          'Run from OB3/tools/scenario_designer/ or OB3/ root.',
        );
      }

      print('[DB] Opening game DB directly: $dbPath');

      _db = await databaseFactory.openDatabase(
        dbPath,
        options: OpenDatabaseOptions(
          onOpen: (db) async {
            await db.execute('PRAGMA foreign_keys = ON');
            await _runMigrations(db);
          },
        ),
      );
      return _db!;
    }
  }

  /// Runs non-destructive schema migrations so older runtime DBs gain new tables.
  static Future<void> _runMigrations(Database db) async {
    // Ensure scenario_loadouts table exists (added in Sprint 10)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS scenario_loadouts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        scenario_id INTEGER NOT NULL,
        loadout_number INTEGER NOT NULL,
        weapon_name TEXT NOT NULL,
        quantity INTEGER NOT NULL DEFAULT 1,
        constraints TEXT,
        notes TEXT
      )
    ''');
    // Ensure scenario_designer_excluded_loadouts exists
    await db.execute('''
      CREATE TABLE IF NOT EXISTS scenario_designer_excluded_loadouts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        scenario_id INTEGER NOT NULL,
        drone_id INTEGER,
        option_index INTEGER NOT NULL
      )
    ''');
    // Ensure scenario_weapons exists
    await db.execute('''
      CREATE TABLE IF NOT EXISTS scenario_weapons (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        scenario_id INTEGER NOT NULL,
        weapon_id INTEGER NOT NULL
      )
    ''');
    // Ensure scenario_designer_drones exists
    await db.execute('''
      CREATE TABLE IF NOT EXISTS scenario_designer_drones (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        scenario_id INTEGER NOT NULL,
        drone_id INTEGER NOT NULL
      )
    ''');
    
    // Ensure new scenario fields exist
    try { await db.execute("ALTER TABLE scenarios ADD COLUMN mission_briefing_image_path TEXT"); } catch (_) {}
    try { await db.execute("ALTER TABLE scenarios ADD COLUMN threat_intel TEXT"); } catch (_) {}
    try { await db.execute("ALTER TABLE scenarios ADD COLUMN target_intel TEXT"); } catch (_) {}
    try { await db.execute("ALTER TABLE scenarios ADD COLUMN start_fuel_modifier INTEGER DEFAULT 0"); } catch (_) {}
    try { await db.execute("ALTER TABLE scenarios ADD COLUMN start_damage_modifier INTEGER DEFAULT 0"); } catch (_) {}
    
    // ── Inject missing combat cards safely so user doesn't lose browser scenarios ──
    try {
      await db.execute("ALTER TABLE combat_cards ADD COLUMN attribute_effect TEXT");
    } catch (_) {}

    final newCards = [
      ['NEW_CC_01', 'COMBAT', 'AGGRESSIVE STRIKE PROFILE', '"Maverick\'s flying. Duck."', 'Attack DRM: +2\nApply +2 to all attack rolls.'],
      ['NEW_CC_02', 'COMBAT', 'WHITEOUT', '"Winter is here. Targeting is not."', 'Attack DRM: -2\nApply -2 to all attack rolls.'],
      ['NEW_CC_03', 'COMBAT', 'TAILWIND', '"The Force is strong with this one."', 'Attack DRM: +1\nApply +1 to all attack rolls.'],
      ['NEW_CC_04', 'COMBAT', 'STATIC', '"Houston, we have a problem."', 'Attack DRM: -1\nApply -1 to all attack rolls.'],
      ['NEW_CC_05', 'COMBAT', 'LOST SIGNAL', '"E.T. can\'t phone home either."', 'Attack DRM: -2\nApply -2 to all attack rolls.'],
      ['NEW_CC_06', 'COMBAT', 'CLEAR SKIES', '"I see dead targets."', 'Attack DRM: +2\nApply +2 to all attack rolls.'],
      ['NEW_CC_07', 'COMBAT', 'GROUND HUGGING', '"Keep your friends close. Keep your altitude lower."', 'Attack DRM: +1\nApply +1 to all attack rolls at Very Low or Low altitude.'],
      ['NEW_CC_08', 'COMBAT', 'UPDRAFT', '"Physics has opinions."', 'Attack DRM: -1\nApply -1 to all attack rolls.'],
      ['NEW_CC_09', 'COMBAT', 'GHOST SIGNAL', '"These aren\'t the targets you\'re looking for."', 'Attack DRM: -1\nApply -1 to all attack rolls. FO/Laze mode unaffected.'],
      ['NEW_CC_10', 'COMBAT', 'BURST TRANSMISSION', '"One ping only, please."', 'Attack DRM: +1\nApply +1 to all attack rolls.'],
      ['NEW_CC_11', 'COMBAT', 'FOG OF WAR', '"I love the smell of confusion in the morning."', 'Attack DRM: -2\nApply -2 to all attack rolls.'],
      ['NEW_CC_12', 'COMBAT', 'THERMAL SPIKE', '"To infinity — starting with one altitude level."', 'Altitude Change: +1 to altitude level.'],
      ['NEW_CC_13', 'COMBAT', 'DIVE DIVE DIVE', '"Just keep swimming. Lower."', 'Altitude Change: -1 to altitude level.'],
      ['NEW_CC_14', 'COMBAT', 'DEAD DROP', '"What goes up, must go down. Immediately."', 'Altitude Change: -1 to altitude level.'],
      ['NEW_CC_15', 'COMBAT', 'STRATOSPHERIC', '"I\'m on top of the world, Ma."', 'Altitude Change: +2 to altitude levels.'],
      ['NEW_CC_16', 'COMBAT', 'NOSEDIVE', '"Hello darkness, my old friend."', 'Altitude Change: -2 to altitude levels.'],
      ['NEW_CC_17', 'COMBAT', 'DECK LEVEL', '"Why so serious? Fly lower."', 'Altitude Change: Forced to VERY LOW.'],
      ['NEW_CC_18', 'COMBAT', 'TOP GUN', '"You can be my wingman any time."', 'Altitude Change: Forced to HIGH.'],
      ['NEW_CC_19', 'COMBAT', 'NO EVENT', 'No effect.', 'Discard without action.'],
    ];

    for (final card in newCards) {
      final effectSummary = card[4].split('\n').first;
      final res = await db.query('combat_cards', where: 'card_number = ?', whereArgs: [card[0]]);
      if (res.isEmpty) {
        await db.rawInsert('''
          INSERT INTO combat_cards (card_number, card_type, card_name, instruction, instructions, attribute_effect)
          VALUES (?, ?, ?, ?, ?, ?)
        ''', [card[0], card[1], card[2], card[3], card[4], effectSummary]);
      } else {
        await db.rawUpdate('''
          UPDATE combat_cards SET card_type = ?, card_name = ?, instruction = ?, instructions = ?, attribute_effect = ?
          WHERE card_number = ?
        ''', [card[1], card[2], card[3], card[4], effectSummary, card[0]]);
      }
    }
  }

  /// Exports the current database as bytes for downloading.
  static Future<Uint8List?> getDatabaseBytes() async {
    try {
      if (kIsWeb) {
        // Close the live connection so we can read the bytes
        if (_db != null) {
          await _db!.close();
          _db = null;
        }
        // Try reading from IndexedDB first (includes user edits)
        try {
          final factory = databaseFactoryFfiWeb;
          final bytes = await factory.readDatabaseBytes('ob3.db');
          if (bytes.isNotEmpty) return bytes;
        } catch (e) {
          print('[DB] IndexedDB read failed, falling back to asset: $e');
        }
        // Fallback: read the bundled asset (no user edits)
        final data = await rootBundle.load(_assetDbPath);
        return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      } else {
        final dbDir = await getApplicationDocumentsDirectory();
        final dbPath = join(dbDir.path, 'ob3.db');
        final file = File(dbPath);
        if (file.existsSync()) {
          return file.readAsBytesSync();
        }
        return null;
      }
    } catch (e) {
      print('[DB] Export error: $e');
      return null;
    }
  }

  // ─── Combat Cards ─────────────────────────────────────────

  /// Returns all 18 combat cards.
  static Future<List<CombatCard>> getAllCombatCards() async {
    final db = await database;
    final rows = await db.query('combat_cards');
    return rows.map((r) => CombatCard.fromRow(r)).toList();
  }

  /// Returns a single combat card by card_number.
  static Future<CombatCard?> getCombatCard(String cardNumber) async {
    final db = await database;
    final rows = await db.query(
      'combat_cards',
      where: 'card_number = ?',
      whereArgs: [cardNumber],
    );
    if (rows.isEmpty) return null;
    return CombatCard.fromRow(rows.first);
  }

  /// Returns a single combat card by name.
  static Future<CombatCard?> findCombatCardByName(String name) async {
    final db = await database;
    final rows = await db.query(
      'combat_cards',
      where: 'card_name = ?',
      whereArgs: [name],
    );
    if (rows.isEmpty) return null;
    return CombatCard.fromRow(rows.first);
  }

  // ─── Target Cards ─────────────────────────────────────────

  /// Returns all 111 target cards.
  static Future<List<TargetCard>> getAllTargetCards() async {
    final db = await database;
    final rows = await db.query('target_cards');
    return rows.map((r) => TargetCard.fromRow(r)).toList();
  }

  /// Returns target cards filtered by sub_category.
  static Future<List<TargetCard>> getTargetCardsByCategory(String subCategory) async {
    final db = await database;
    final rows = await db.query(
      'target_cards',
      where: 'sub_category = ?',
      whereArgs: [subCategory],
    );
    return rows.map((r) => TargetCard.fromRow(r)).toList();
  }

  /// Returns target cards the drone can attack from its current altitude.
  /// NULL altitude_restriction means target is attackable from any altitude.
  static Future<List<TargetCard>> getValidTargets(String droneAltitude) async {
    final allTargets = await getAllTargetCards();
    return allTargets.where((t) => t.canBeAttackedFrom(droneAltitude)).toList();
  }

  /// Returns a single target card by card_number.
  static Future<TargetCard?> getTargetCard(String cardNumber) async {
    final db = await database;
    final rows = await db.query(
      'target_cards',
      where: 'card_number = ?',
      whereArgs: [cardNumber],
    );
    if (rows.isEmpty) return null;
    return TargetCard.fromRow(rows.first);
  }

  /// Returns a single target card by name.
  static Future<TargetCard?> findTargetCardByName(String name) async {
    final db = await database;
    final rows = await db.query(
      'target_cards',
      where: 'card_name = ?',
      whereArgs: [name],
    );
    if (rows.isEmpty) return null;
    return TargetCard.fromRow(rows.first);
  }

  // ─── Threat Cards ─────────────────────────────────────────

  /// Returns all 36 threat cards.
  static Future<List<ThreatCard>> getAllThreatCards() async {
    final db = await database;
    final rows = await db.query('threat_cards');
    return rows.map((r) => ThreatCard.fromRow(r)).toList();
  }

  /// Returns threat cards active at the drone's current altitude.
  /// NULL altitude_restriction + generic CAP cards always activate.
  static Future<List<ThreatCard>> getActiveThreats(String droneAltitude) async {
    final allThreats = await getAllThreatCards();
    return allThreats.where((t) => t.isActiveAt(droneAltitude)).toList();
  }

  /// Returns a single threat card by name.
  static Future<ThreatCard?> findThreatCardByName(String name) async {
    final db = await database;
    final rows = await db.query(
      'threat_cards',
      where: 'card_name = ?',
      whereArgs: [name],
    );
    if (rows.isEmpty) return null;
    return ThreatCard.fromRow(rows.first);
  }

  // ─── Drones ───────────────────────────────────────────────

  /// Returns all 28 drones.
  static Future<List<DroneData>> getAllDrones() async {
    final db = await database;
    final rows = await db.query('drones');
    return rows.map((r) => DroneData.fromRow(r)).toList();
  }

  /// Returns a single drone by ID.
  static Future<DroneData?> getDrone(int id) async {
    final db = await database;
    final rows = await db.query(
      'drones',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (rows.isEmpty) return null;
    return DroneData.fromRow(rows.first);
  }

  // ─── Weapons ──────────────────────────────────────────────

  /// Returns all 28 weapons.
  static Future<List<WeaponData>> getAllWeapons() async {
    final db = await database;
    final rows = await db.query('weapons');
    return rows.map((r) => WeaponData.fromRow(r)).toList();
  }

  /// Returns a single weapon by name (the join key from drone loadouts).
  static Future<WeaponData?> getWeapon(String name) async {
    final db = await database;
    final rows = await db.query(
      'weapons',
      where: 'name = ?',
      whereArgs: [name],
    );
    if (rows.isEmpty) return null;
    return WeaponData.fromRow(rows.first);
  }

  // ─── Generic card getter by card_number ───────────────────

  /// Returns any card (combat, target, or threat) by card_number.
  static Future<Map<String, dynamic>?> getCard(String cardNumber) async {
    final db = await database;
    
    // Try combat cards first
    var rows = await db.query('combat_cards', where: 'card_number = ?', whereArgs: [cardNumber]);
    if (rows.isNotEmpty) return {'type': 'combat', 'data': CombatCard.fromRow(rows.first)};

    // Try target cards
    rows = await db.query('target_cards', where: 'card_number = ?', whereArgs: [cardNumber]);
    if (rows.isNotEmpty) return {'type': 'target', 'data': TargetCard.fromRow(rows.first)};

    // Try threat cards
    rows = await db.query('threat_cards', where: 'card_number = ?', whereArgs: [cardNumber]);
    if (rows.isNotEmpty) return {'type': 'threat', 'data': ThreatCard.fromRow(rows.first)};

    return null;
  }

  // ─── Scenarios ────────────────────────────────────────────

  /// Returns all original (non-designer) scenarios.
  static Future<List<Scenario>> getAllScenarios() async {
    final db = await database;
    final rows = await db.query(
      'scenarios',
      where: 'state IS NULL',
    );
    return rows.map((r) => Scenario.fromRow(r)).toList();
  }

  /// Returns only Published designer-created scenarios.
  static Future<List<Scenario>> getPublishedDesignerScenarios() async {
    final db = await database;
    final rows = await db.query(
      'scenarios',
      where: "state = ?",
      whereArgs: ['Published'],
    );
    return rows.map((r) => Scenario.fromRow(r)).toList();
  }

  /// Returns a specific scenario.
  static Future<Scenario?> getScenario(int id) async {
    final db = await database;
    final rows = await db.query('scenarios', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return Scenario.fromRow(rows.first);
  }

  /// Returns all zones for a specific scenario.
  static Future<List<ScenarioZone>> getScenarioZones(int scenarioId) async {
    final db = await database;
    final rows = await db.query('scenario_zones', where: 'scenario_id = ?', whereArgs: [scenarioId]);
    return rows.map((r) => ScenarioZone.fromRow(r)).toList();
  }

  /// Returns threat ranges override for a zone in a scenario.
  static Future<List<ScenarioThreatRange>> getScenarioThreatRanges(int scenarioId, int zoneNumber) async {
    final db = await database;
    final rows = await db.query(
      'scenario_threat_ranges',
      where: 'scenario_id = ? AND zone_number = ?',
      whereArgs: [scenarioId, zoneNumber],
    );
    return rows.map((r) => ScenarioThreatRange.fromRow(r)).toList();
  }

  /// Returns target ranges override for a zone in a scenario.
  static Future<List<ScenarioTargetRange>> getScenarioTargetRanges(int scenarioId, int zoneNumber) async {
    final db = await database;
    final rows = await db.query(
      'scenario_target_ranges',
      where: 'scenario_id = ? AND zone_number = ?',
      whereArgs: [scenarioId, zoneNumber],
      orderBy: 'range_min ASC',
    );
    return rows.map((r) => ScenarioTargetRange.fromRow(r)).toList();
  }

  /// Returns the custom threat deck composition for a zone in a scenario.
  static Future<List<ScenarioThreatDeck>> getScenarioThreatDeck(int scenarioId, int zoneNumber) async {
    final db = await database;
    final rows = await db.query(
      'scenario_threat_deck',
      where: 'scenario_id = ? AND zone_number = ?',
      whereArgs: [scenarioId, zoneNumber],
    );
    return rows.map((r) => ScenarioThreatDeck.fromRow(r)).toList();
  }

  /// Returns the custom target deck composition for a zone in a scenario.
  static Future<List<ScenarioTargetDeck>> getScenarioTargetDeck(int scenarioId, int zoneNumber) async {
    final db = await database;
    final rows = await db.query(
      'scenario_target_deck',
      where: 'scenario_id = ? AND zone_number = ?',
      whereArgs: [scenarioId, zoneNumber],
    );
    return rows.map((r) => ScenarioTargetDeck.fromRow(r)).toList();
  }

  /// Returns the loadout restrictions for a scenario.
  static Future<List<ScenarioLoadout>> getScenarioLoadouts(int scenarioId) async {
    final db = await database;
    final rows = await db.query('scenario_loadouts', where: 'scenario_id = ?', whereArgs: [scenarioId]);
    return rows.map((r) => ScenarioLoadout.fromRow(r)).toList();
  }

  // ─── Sprint 10: Generic query/execute for campaign & designer tool ─────

  /// Generic read query (returns rows as maps).
  static Future<List<Map<String, dynamic>>> rawQuery(String sql, [List<Object?>? args]) async {
    final db = await database;
    return db.rawQuery(sql, args);
  }

  /// Writable database (for designer tool inserts/updates).
  static Future<Database> get writableDatabase async {
    // Both web and native return the single populated connection.
    return database;
  }

  /// Execute SQL that modifies data (INSERT/UPDATE/DELETE).
  static Future<void> rawExecute(String sql, [List<Object?>? args]) async {
    final db = await writableDatabase;
    await db.execute(sql, args);
  }

  /// Insert and return the new row ID.
  static Future<int> rawInsert(String sql, [List<Object?>? args]) async {
    final db = await writableDatabase;
    return db.rawInsert(sql, args);
  }

  /// Close database connection.
  static Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
