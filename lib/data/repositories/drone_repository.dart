
import '../database_service.dart';
import '../../models/drone.dart';

/// Repository for loading drone definitions from the database.
class DroneRepository {
  const DroneRepository(this._dbService);
  final DatabaseService _dbService;

  /// Load all drones from the database.
  Future<List<Drone>> getAll() async {
    final db = await _dbService.database;
    final maps = await db.query('drones', orderBy: 'id');
    return maps.map((m) => Drone.fromMap(m)).toList();
  }

  /// Load a single drone by ID.
  Future<Drone?> getById(int id) async {
    final db = await _dbService.database;
    final maps = await db.query('drones', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Drone.fromMap(maps.first);
  }

  /// Load drones filtered by class.
  Future<List<Drone>> getByClass(String droneClass) async {
    final db = await _dbService.database;
    final maps = await db.query(
      'drones',
      where: 'drone_class = ?',
      whereArgs: [droneClass],
      orderBy: 'id',
    );
    return maps.map((m) => Drone.fromMap(m)).toList();
  }
}
