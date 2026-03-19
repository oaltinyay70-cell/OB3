
import '../database_service.dart';
import '../../models/combat_card.dart';
import '../../models/target_card.dart';
import '../../models/threat_card.dart';

/// Repository for loading card data from the database.
class CardRepository {
  const CardRepository(this._dbService);
  final DatabaseService _dbService;

  // ---------------------------------------------------------------------------
  // Combat Cards
  // ---------------------------------------------------------------------------

  /// Load all 31 merged combat cards (card_type = 'COMBAT', CC001–CC031).
  Future<List<CombatCard>> getAllCombatCards() async {
    final db = await _dbService.database;
    final maps = await db.query(
      'combat_cards',
      where: "card_type = 'COMBAT'",
      orderBy: 'card_number',
    );
    return maps.map((m) => CombatCard.fromMap(m)).toList();
  }

  /// Load a single combat card by its number (e.g. "CC013").
  Future<CombatCard?> getCombatCardByNumber(String number) async {
    final db = await _dbService.database;
    final maps = await db.query(
      'combat_cards',
      where: 'card_number = ?',
      whereArgs: [number],
      limit: 1,
    );
    return maps.isEmpty ? null : CombatCard.fromMap(maps.first);
  }

  // ---------------------------------------------------------------------------
  // Target Cards
  // ---------------------------------------------------------------------------

  /// Load all 111 target cards.
  Future<List<TargetCard>> getAllTargetCards() async {
    final db = await _dbService.database;
    final maps = await db.query('target_cards', orderBy: 'card_number');
    return maps.map((m) => TargetCard.fromMap(m)).toList();
  }

  /// Load target cards filtered by sub_category.
  Future<List<TargetCard>> getTargetCardsByType(String subCategory) async {
    final db = await _dbService.database;
    final maps = await db.query(
      'target_cards',
      where: 'UPPER(sub_category) = ?',
      whereArgs: [subCategory.toUpperCase()],
      orderBy: 'card_number',
    );
    return maps.map((m) => TargetCard.fromMap(m)).toList();
  }

  // ---------------------------------------------------------------------------
  // Threat Cards
  // ---------------------------------------------------------------------------

  /// Load all 36 threat cards.
  Future<List<ThreatCard>> getAllThreatCards() async {
    final db = await _dbService.database;
    final maps = await db.query('threat_cards', orderBy: 'card_number');
    return maps.map((m) => ThreatCard.fromMap(m)).toList();
  }

  /// Load threat cards filtered by sub_category.
  Future<List<ThreatCard>> getThreatCardsByType(String subCategory) async {
    final db = await _dbService.database;
    final maps = await db.query(
      'threat_cards',
      where: 'UPPER(sub_category) = ?',
      whereArgs: [subCategory.toUpperCase()],
      orderBy: 'card_number',
    );
    return maps.map((m) => ThreatCard.fromMap(m)).toList();
  }
}
