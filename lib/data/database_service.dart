import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

/// Singleton service managing the SQLite database connection.
///
/// On first launch, copies the asset database to the app's documents directory.
/// On version bumps, replaces the existing copy with the updated asset.
class DatabaseService {
  DatabaseService._();
  static final DatabaseService instance = DatabaseService._();

  static const String _dbFileName = 'ob3.db';
  static const String _assetPath = 'assets/db/$_dbFileName';

  /// Increment this when shipping a new ob3.db in assets.
  /// v11 — restored correct max_structural_integrity values (80–425) for all 28 drones.
  static const int _dbVersion = 11;

  Database? _database;

  /// Get the database instance. Initializes if needed.
  Future<Database> get database async {
    if (_database != null && _database!.isOpen) {
      return _database!;
    }
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final documentsDir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(documentsDir.path, _dbFileName);
    final versionPath = p.join(documentsDir.path, '${_dbFileName}.version');

    final dbFile = File(dbPath);
    final versionFile = File(versionPath);

    // Copy from assets if file doesn't exist or version is outdated.
    bool needsCopy = !await dbFile.exists();
    if (!needsCopy && await versionFile.exists()) {
      final storedVersion = int.tryParse(await versionFile.readAsString()) ?? 0;
      needsCopy = storedVersion < _dbVersion;
    } else if (!needsCopy && !await versionFile.exists()) {
      // Existing DB but no version file → legacy install, force update.
      needsCopy = true;
    }

    if (needsCopy) {
      final data = await rootBundle.load(_assetPath);
      final bytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );
      await dbFile.writeAsBytes(bytes, flush: true);
      await versionFile.writeAsString('$_dbVersion');
    }

    return await openDatabase(dbPath);
  }

  /// Close the database connection.
  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}
