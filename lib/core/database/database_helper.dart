import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

/// Singleton helper that manages the game's SQLite database.
///
/// On first launch, the pre-bundled `drone_commander_cards.db` asset is
/// copied from the Flutter asset bundle into the app's documents directory.
/// Subsequent launches reuse the existing copy.
class DatabaseHelper {
  static const String _dbName = 'drone_commander_cards.db';
  static const String _assetPath = 'assets/db/$_dbName';

  static DatabaseHelper? _instance;
  static Database? _database;

  DatabaseHelper._internal();

  factory DatabaseHelper() {
    _instance ??= DatabaseHelper._internal();
    return _instance!;
  }

  /// Returns the open [Database], initialising it on first access.
  Future<Database> get database async {
    if (_database != null && _database!.isOpen) {
      return _database!;
    }
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final Directory documentsDir = await getApplicationDocumentsDirectory();
    final String dbPath = join(documentsDir.path, _dbName);

    // Copy the bundled database if it doesn't exist yet.
    if (!File(dbPath).existsSync()) {
      final ByteData data = await rootBundle.load(_assetPath);
      final List<int> bytes =
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      await File(dbPath).writeAsBytes(bytes, flush: true);
    }

    return openDatabase(dbPath, readOnly: true);
  }

  /// Closes the database connection. Call during app teardown if needed.
  Future<void> close() async {
    final db = _database;
    if (db != null && db.isOpen) {
      await db.close();
      _database = null;
    }
  }
}
