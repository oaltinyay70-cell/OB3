import 'dart:typed_data';

/// Represents a Combat Card drawn during the Counter Fire & Evasion step.
class CombatCard {
  final int id;
  final String cardNumber;
  final String cardType;
  final String cardName;
  final String instruction;
  final String? instructions; // OCR-scraped text
  final Uint8List? image;
  final Uint8List? backImage;

  const CombatCard({
    required this.id,
    required this.cardNumber,
    required this.cardType,
    required this.cardName,
    required this.instruction,
    this.instructions,
    this.image,
    this.backImage,
  });

  factory CombatCard.fromRow(Map<String, dynamic> row) => CombatCard(
    id: row['id'] as int,
    cardNumber: row['card_number'] as String,
    cardType: row['card_type'] as String,
    cardName: row['card_name'] as String,
    instruction: row['instruction'] as String,
    instructions: row['instructions'] as String?,
    image: row['image'] as Uint8List?,
    backImage: row['back_image'] as Uint8List?,
  );
}

/// Represents a Target Card with VP value, altitude/weapon restrictions.
class TargetCard {
  final int id;
  final String cardNumber;
  final String cardType;
  final String subCategory;
  final String cardName;
  final double vp;
  final String? instruction;
  final String? instructions;
  final String? altitudeRestriction;
  final String? weaponType;
  final Uint8List? image;
  final Uint8List? backImage;

  const TargetCard({
    required this.id,
    required this.cardNumber,
    required this.cardType,
    required this.subCategory,
    required this.cardName,
    required this.vp,
    this.instruction,
    this.instructions,
    this.altitudeRestriction,
    this.weaponType,
    this.image,
    this.backImage,
  });

  /// Returns true if a drone at [droneAltitude] can attack this target.
  /// NULL altitude_restriction means any altitude is valid.
  bool canBeAttackedFrom(String droneAltitude) {
    if (altitudeRestriction == null || altitudeRestriction!.isEmpty) return true;
    final allowed = altitudeRestriction!.toUpperCase().split(',').map((s) => s.trim()).toList();
    return allowed.contains(droneAltitude.toUpperCase());
  }

  factory TargetCard.fromRow(Map<String, dynamic> row) => TargetCard(
    id: row['id'] as int,
    cardNumber: row['card_number'] as String,
    cardType: row['card_type'] as String,
    subCategory: row['sub_category'] as String,
    cardName: row['card_name'] as String,
    vp: (row['vp'] as num).toDouble(),
    instruction: row['instruction'] as String?,
    instructions: row['instructions'] as String?,
    altitudeRestriction: row['altitude_restriction'] as String?,
    weaponType: row['weapon_type'] as String?,
    image: row['image'] as Uint8List?,
    backImage: row['back_image'] as Uint8List?,
  );
}

/// Represents a Threat Card with altitude restriction and column shift.
class ThreatCard {
  final String cardNumber;
  final String? cardType;
  final String? subCategory;
  final String? cardName;
  final String? instruction;
  final String? instructions;
  final String? altitudeRestriction;
  final String? columnShift;
  final int? cshiftBy;
  final Uint8List? image;
  final Uint8List? backImage;

  const ThreatCard({
    required this.cardNumber,
    this.cardType,
    this.subCategory,
    this.cardName,
    this.instruction,
    this.instructions,
    this.altitudeRestriction,
    this.columnShift,
    this.cshiftBy,
    this.image,
    this.backImage,
  });

  /// Returns true if this threat is active at the given [droneAltitude].
  /// NULL altitude_restriction means threat fires at ANY altitude.
  /// Generic CAP cards (THCAP) always activate.
  bool isActiveAt(String droneAltitude) {
    if (cardNumber.startsWith('THCAP')) return true;
    if (altitudeRestriction == null || altitudeRestriction!.isEmpty) return true;
    final altitudes = altitudeRestriction!.toUpperCase().split(',').map((s) => s.trim()).toList();
    return altitudes.contains(droneAltitude.toUpperCase());
  }

  factory ThreatCard.fromRow(Map<String, dynamic> row) => ThreatCard(
    cardNumber: row['card_number'] as String,
    cardType: row['card_type'] as String?,
    subCategory: row['sub_category'] as String?,
    cardName: row['card_name'] as String?,
    instruction: row['instruction'] as String?,
    instructions: row['instructions'] as String?,
    altitudeRestriction: row['altitude_restriction'] as String?,
    columnShift: row['column_shift'] as String?,
    cshiftBy: row['cshift_by'] as int?,
    image: row['image'] as Uint8List?,
    backImage: row['back_image'] as Uint8List?,
  );
}

/// Represents a Weapon from the weapons table.
class WeaponData {
  final int id;
  final String? wpnType;
  final String name;
  final String? description;
  final String? targets;
  final String? fireRange;
  final String? fireAltitude;

  // New V0.2 DRM properties
  final int drmTruck;
  final int drmPersonnel;
  final int drmAfv;
  final int drmSam;
  final int drmTank;
  final int drmArtillery;
  final int drmHqBunker;
  final int drmVip;
  final int drmAir;

  // PRD V1
  final String? usedBy;

  const WeaponData({
    required this.id,
    this.wpnType,
    required this.name,
    this.description,
    this.targets,
    this.fireRange,
    this.fireAltitude,
    this.drmTruck = 0,
    this.drmPersonnel = 0,
    this.drmAfv = 0,
    this.drmSam = 0,
    this.drmTank = 0,
    this.drmArtillery = 0,
    this.drmHqBunker = 0,
    this.drmVip = 0,
    this.drmAir = 0,
    this.usedBy,
  });

  /// Returns true if this weapon can fire from [droneAltitude].
  /// NULL fire_altitude means weapon can fire from any altitude.
  bool canFireFrom(String droneAltitude) {
    if (fireAltitude == null || fireAltitude!.isEmpty) return true;
    final altitudes = fireAltitude!.toUpperCase().split(',').map((s) => s.trim()).toList();
    return altitudes.contains(droneAltitude.toUpperCase());
  }

  factory WeaponData.fromRow(Map<String, dynamic> row) => WeaponData(
    id: row['id'] as int,
    wpnType: row['wpn_type'] as String?,
    name: row['name'] as String,
    description: row['description'] as String?,
    targets: row['targets'] as String?,
    fireRange: row['fire_range'] as String?,
    fireAltitude: row['fire_altitude'] as String?,
    drmTruck: row['drm_truck'] as int? ?? 0,
    drmPersonnel: row['drm_personnel'] as int? ?? 0,
    drmAfv: row['drm_afv'] as int? ?? 0,
    drmSam: row['drm_sam'] as int? ?? 0,
    drmTank: row['drm_tank'] as int? ?? 0,
    drmArtillery: row['drm_artillery'] as int? ?? 0,
    drmHqBunker: row['drm_hq_bunker'] as int? ?? 0,
    drmVip: row['drm_vip'] as int? ?? 0,
    drmAir: row['drm_air'] as int? ?? 0,
    usedBy: row['used_by'] as String?,
  );
}

/// Represents a drone record from the DB with its loadout options.
class DroneData {
  final int id;
  final String? category;
  final String name;
  final String? country;
  final String? range;
  final int? stations;
  final String? maxPayload;
  final String? stationWeightLimits;
  final String? altitude; // e.g. "LOW, MEDIUM, HIGH"

  // Up to 3 loadout options, each with up to 2 weapon slots
  final String? opt1Wpn1Name;
  final int? opt1Wpn1Qty;
  final String? opt1Wpn2Name;
  final int? opt1Wpn2Qty;
  final String? opt2Wpn1Name;
  final int? opt2Wpn1Qty;
  final String? opt2Wpn2Name;
  final int? opt2Wpn2Qty;
  final String? opt3Wpn1Name;
  final int? opt3Wpn1Qty;
  final String? opt3Wpn2Name;
  final int? opt3Wpn2Qty;

  // New V0.2 Drone properties
  final int maxStructuralIntegrity;
  final bool hasBuiltInFoLaze;
  final String droneClass;
  final bool hasAeasaRadar;
  final bool hasSatcom;
  final bool hasCommsRedundancy;
  final bool hasAutonomousAi;

  // PRD V1 fields
  final double maxEnduranceHours;
  final double fuelPerAltitudeGain;
  final double fuelPerAltitudeLoss;
  final String? compatibleWeapons;

  const DroneData({
    required this.id,
    this.category,
    required this.name,
    this.country,
    this.range,
    this.stations,
    this.maxPayload,
    this.stationWeightLimits,
    this.altitude,
    this.opt1Wpn1Name,
    this.opt1Wpn1Qty,
    this.opt1Wpn2Name,
    this.opt1Wpn2Qty,
    this.opt2Wpn1Name,
    this.opt2Wpn1Qty,
    this.opt2Wpn2Name,
    this.opt2Wpn2Qty,
    this.opt3Wpn1Name,
    this.opt3Wpn1Qty,
    this.opt3Wpn2Name,
    this.opt3Wpn2Qty,
    this.maxStructuralIntegrity = 1000,
    this.hasBuiltInFoLaze = true,
    this.droneClass = 'B',
    this.hasAeasaRadar = false,
    this.hasSatcom = false,
    this.hasCommsRedundancy = false,
    this.hasAutonomousAi = false,
    this.maxEnduranceHours = 24.0,
    this.fuelPerAltitudeGain = 2.0,
    this.fuelPerAltitudeLoss = 1.0,
    this.compatibleWeapons,
  });

  /// Returns parsed altitude list: ["LOW", "MEDIUM", "HIGH"]
  List<String> get altitudes {
    if (altitude == null || altitude!.isEmpty) return [];
    return altitude!.toUpperCase().split(',').map((s) => s.trim()).toList();
  }

  /// Returns list of loadout options (non-null ones only).
  List<LoadoutOption> get loadoutOptions {
    final options = <LoadoutOption>[];

    if (opt1Wpn1Name != null) {
      options.add(LoadoutOption(
        optionIndex: 1,
        wpn1Name: opt1Wpn1Name!,
        wpn1Qty: opt1Wpn1Qty ?? 0,
        wpn2Name: opt1Wpn2Name,
        wpn2Qty: opt1Wpn2Qty,
      ));
    }
    if (opt2Wpn1Name != null) {
      options.add(LoadoutOption(
        optionIndex: 2,
        wpn1Name: opt2Wpn1Name!,
        wpn1Qty: opt2Wpn1Qty ?? 0,
        wpn2Name: opt2Wpn2Name,
        wpn2Qty: opt2Wpn2Qty,
      ));
    }
    if (opt3Wpn1Name != null) {
      options.add(LoadoutOption(
        optionIndex: 3,
        wpn1Name: opt3Wpn1Name!,
        wpn1Qty: opt3Wpn1Qty ?? 0,
        wpn2Name: opt3Wpn2Name,
        wpn2Qty: opt3Wpn2Qty,
      ));
    }

    return options;
  }

  factory DroneData.fromRow(Map<String, dynamic> row) => DroneData(
    id: row['id'] as int,
    category: row['category'] as String?,
    name: row['name'] as String,
    country: row['country'] as String?,
    range: row['range'] as String?,
    stations: row['stations'] as int?,
    maxPayload: row['max_payload'] as String?,
    stationWeightLimits: row['station_weight_limits'] as String?,
    altitude: row['altitude'] as String?,
    opt1Wpn1Name: row['opt1_wpn1_name'] as String?,
    opt1Wpn1Qty: row['opt1_wpn1_qty'] as int?,
    opt1Wpn2Name: row['opt1_wpn2_name'] as String?,
    opt1Wpn2Qty: row['opt1_wpn2_qty'] as int?,
    opt2Wpn1Name: row['opt2_wpn1_name'] as String?,
    opt2Wpn1Qty: row['opt2_wpn1_qty'] as int?,
    opt2Wpn2Name: row['opt2_wpn2_name'] as String?,
    opt2Wpn2Qty: row['opt2_wpn2_qty'] as int?,
    opt3Wpn1Name: row['opt3_wpn1_name'] as String?,
    opt3Wpn1Qty: row['opt3_wpn1_qty'] as int?,
    opt3Wpn2Name: row['opt3_wpn2_name'] as String?,
    opt3Wpn2Qty: row['opt3_wpn2_qty'] as int?,
    maxStructuralIntegrity: row['max_structural_integrity'] as int? ?? 1000,
    hasBuiltInFoLaze: (row['has_builtin_fo_laze'] as int? ?? 1) == 1,
    droneClass: row['drone_class'] as String? ?? 'B',
    hasAeasaRadar: (row['has_aeasa_radar'] as int? ?? 0) == 1,
    hasSatcom: (row['has_satcom'] as int? ?? 0) == 1,
    hasCommsRedundancy: (row['has_comms_redundancy'] as int? ?? 0) == 1,
    hasAutonomousAi: (row['has_autonomous_ai'] as int? ?? 0) == 1,
    maxEnduranceHours: (row['max_endurance_hours'] as num?)?.toDouble() ?? 24.0,
    fuelPerAltitudeGain: (row['fuel_per_altitude_gain'] as num?)?.toDouble() ?? 2.0,
    fuelPerAltitudeLoss: (row['fuel_per_altitude_loss'] as num?)?.toDouble() ?? 1.0,
    compatibleWeapons: row['compatible_weapons'] as String?,
  );
}

/// Represents a single loadout option (one of opt1/opt2/opt3) on a drone.
class LoadoutOption {
  final int optionIndex;
  final String wpn1Name;
  final int wpn1Qty;
  final String? wpn2Name;
  final int? wpn2Qty;

  const LoadoutOption({
    required this.optionIndex,
    required this.wpn1Name,
    required this.wpn1Qty,
    this.wpn2Name,
    this.wpn2Qty,
  });

  /// Human-readable label: "4× MAM-L + 2× MAM-C"
  String get label {
    String result = '$wpn1Qty× $wpn1Name';
    if (wpn2Name != null && wpn2Qty != null && wpn2Qty! > 0) {
      result += ' + $wpn2Qty× $wpn2Name';
    }
    return result;
  }

  /// Total weapon count across both slots
  int get totalCount => wpn1Qty + (wpn2Qty ?? 0);
}
