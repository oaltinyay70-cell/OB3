
import '../database_service.dart';
import '../../models/weapon.dart';

/// Repository for loading weapon definitions from the database.
class WeaponRepository {
  const WeaponRepository(this._dbService);
  final DatabaseService _dbService;

  /// Load all weapons from the database.
  Future<List<Weapon>> getAll() async {
    final db = await _dbService.database;
    final maps = await db.query('weapons', orderBy: 'id');
    return maps.map((m) => Weapon.fromMap(m)).toList();
  }

  /// Load a weapon by name (case-insensitive).
  Future<Weapon?> getByName(String name) async {
    final db = await _dbService.database;
    final maps = await db.query(
      'weapons',
      where: 'UPPER(name) = ?',
      whereArgs: [name.toUpperCase()],
    );
    if (maps.isEmpty) return null;
    return Weapon.fromMap(maps.first);
  }

  /// Load all weapons as a name→Weapon lookup map.
  Future<Map<String, Weapon>> getAllAsMap() async {
    final weapons = await getAll();
    return {for (final w in weapons) w.name.toUpperCase(): w};
  }
}
