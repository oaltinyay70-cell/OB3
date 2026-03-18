/// Maps weapon names to their image asset paths.
/// Image filenames are lowercase with hyphens, matching the files in assets/images/weapons/.
class WeaponImageHelper {
  WeaponImageHelper._();

  static const String _basePath = 'assets/images/weapons/';

  /// Map of weapon name (uppercase) → image filename
  static const Map<String, String> _nameToFile = {
    // Turkish
    'MAM-L': 'mam-l.jpg',
    'MAM-C': 'mam-c.jpg',
    'UMTAS': 'umtas.jpg',
    'SOM': 'umtas.jpg', // placeholder — similar Turkish munition

    // Chinese
    'AR-1': 'b8.jpg', // Chinese air-to-ground
    'AR-2': 'b8.jpg', // Chinese air-to-ground
    'FT-7': 'ft-9.jpg', // same FT family
    'FT-9': 'ft-9.jpg',
    'FT-10': 'ft-12.jpg', // same FT family
    'FT-12': 'ft-12.jpg',
    'HJ-10': 'hj-10.jpg',
    'BA-7': 'b8.jpg', // Chinese missile

    // US / NATO
    'AGM-114 HELLFIRE': 'hj-10.jpg', // placeholder until Hellfire pic supplied
    'BRIMSTONE': 'hj-10.jpg', // placeholder — similar missile class
    'GBU-12 PAVEWAY II': 'gbu-12.jpg',
    'GBU-31 JDAM': 'gbu-31.jpg',
    'GBU-38 JDAM': 'gbu-38.jpg',
    'PAVEWAY IV': 'gbu-12.jpg', // same Paveway family
    'SPIKE': 's8.jpg', // placeholder
    'SPICE-250': 'spice-250.jpg',
    'AASM HAMMER': 'gbu53.jpg', // similar precision bomb
    'SAAW': 'gbu39.jpg', // placeholder — similar small bomb

    // Iranian
    'ALMAS': 'almas.jpg',
    'BARQ': 'barq.jpg',
    'QAEM-5': 'qaem5.jpg',
    'QAEM-9': 'qaem9.jpg',
    'SADID-345': 's5.jpg', // Iranian Sadid family
    'H-2': 'h2.jpg',

    // Russian
    'KAB-20': 'kab20.jpg',
    'KAB-250': 'kab250.jpg',
    'KAB-500': 'kab500.jpg',

    // Special / Equipment
    'FO/LAZE KIT': 'spice-250.jpg', // placeholder — targeting pod
  };

  /// Get the asset path for a weapon name. Returns null if no image found.
  static String? getImagePath(String weaponName) {
    final key = weaponName.toUpperCase().trim();
    final file = _nameToFile[key];
    if (file != null) return '$_basePath$file';

    // Fuzzy match: try to find a key that contains the weapon name or vice versa
    for (final entry in _nameToFile.entries) {
      if (key.contains(entry.key) || entry.key.contains(key)) {
        return '$_basePath${entry.value}';
      }
    }
    return null;
  }

  /// Whether an image exists for the given weapon name.
  static bool hasImage(String weaponName) => getImagePath(weaponName) != null;
}
