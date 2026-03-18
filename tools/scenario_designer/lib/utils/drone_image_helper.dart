/// Maps drone names to their image asset paths.
/// Image filenames are lowercase with underscores, matching the files in assets/images/drones/.
class DroneImageHelper {
  DroneImageHelper._();

  static const String _basePath = 'assets/images/drones/';

  /// Map of drone name (uppercase) → image filename
  static const Map<String, String> _nameToFile = {
    'AKSUNGUR': 'aksungur.jpg',
    'ALTIUS-RU': 'altius-ru.jpg',
    'ANKA-S': 'anka-s.jpg',
    'AVENGER': 'avenger.jpg',
    'BAYRAKTAR AKINCI': 'bayraktar_akinci.jpg',
    'AKINCI': 'bayraktar_akinci.jpg',
    'TB2 BAYRAKTAR': 'bayraktar_tb2.jpg',
    'BAYRAKTAR TB2': 'bayraktar_tb2.jpg',
    'BURRAQ': 'burraq.jpg',
    'CH-4B': 'ch-4b.jpg',
    'CH-5': 'ch-5.jpg',
    'EURODRONE': 'eurodrone.jpg',
    'FALCO XPLORER': 'falco_xplorer.jpg',
    'GHATAK': 'ghatak.jpg',
    'GRAY EAGLE': 'gray_eagle.jpg',
    'MQ-1C GRAY EAGLE': 'gray_eagle.jpg',
    'HERMES 450': 'hermes_450.jpg',
    'HERMES 900': 'hermes_900.jpg',
    'HERON TP': 'heron_tp.jpg',
    'MQ-9 REAPER': 'mq-9_reaper.jpg',
    'MQ-9B PROTECTOR': 'mq-9b_protector.jpg',
    'MOHAJER-10': 'mohajer-10.jpg',
    'MOHAJER-6': 'mohajer-6.jpg',
    'NEURON': 'neuron.jpg',
    'NEURON (UCAV)': 'neuron.jpg',
    'ORION': 'orion.jpg',
    'S-70 OKHOTNIK-B': 's-70_okhotnik-b.jpg',
    'OKHOTNIK': 's-70_okhotnik-b.jpg',
    'SHAHED-129': 'shahed-129.jpg',
    'TARANIS': 'taranis.jpg',
    'TB-001 SCORPION': 'tb-001_scorpion.jpg',
    'WING LOONG II': 'wing_loong_ii.jpg',
    'WING LOONG-3': 'wing_loong-3.jpg',
    'WING LOONG 3': 'wing_loong-3.jpg',
  };

  /// Get the asset path for a drone name. Returns null if no image found.
  static String? getImagePath(String droneName) {
    final key = droneName.toUpperCase().trim();
    final file = _nameToFile[key];
    if (file != null) return '$_basePath$file';

    // Fuzzy match: try to find a key that contains the drone name or vice versa
    for (final entry in _nameToFile.entries) {
      if (key.contains(entry.key) || entry.key.contains(key)) {
        return '$_basePath${entry.value}';
      }
    }
    return null;
  }

  /// Whether an image exists for the given drone name.
  static bool hasImage(String droneName) => getImagePath(droneName) != null;
}
