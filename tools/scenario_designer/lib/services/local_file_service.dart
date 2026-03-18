import 'dart:io';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;


class LocalFileService {
  static const String _boxName = 'game_data';
  late Box _box;

  Future<void> init() async {
    print('DEBUG: LocalFileService.init() started');
    print('DEBUG: Opening box $_boxName...');
    try {
      _box = await Hive.openBox(_boxName);
    } on FileSystemException catch (e) {
      // Stale lock file from a previous crash — delete and retry once.
      print('DEBUG: Hive lock error ($e), attempting to clear stale lock...');
      final dir = await getApplicationDocumentsDirectory();
      final lockFile = File(p.join(dir.path, '$_boxName.lock'));
      if (await lockFile.exists()) await lockFile.delete();
      _box = await Hive.openBox(_boxName);
    }
    print('DEBUG: LocalFileService.init() completed');
  }

  Future<void> saveData(String key, dynamic value) async {
    await _box.put(key, value);
  }

  Future<dynamic> getData(String key) async {
    return _box.get(key);
  }

  Future<void> deleteData(String key) async {
    await _box.delete(key);
  }

  bool hasKey(String key) {
    return _box.containsKey(key);
  }

  Future<void> clearAll() async {
    await _box.clear();
  }

  List<String> getKeys() {
    return _box.keys.cast<String>().toList();
  }
}
