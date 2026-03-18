import '../../utils/constants.dart';

class Loadout {
  final String id;
  final String name;
  final String type;
  final String description;
  final List<DroneClass> classRestrictions;
  final int drmModifier;
  final int fuelModifier;
  final bool isExclusive;
  final bool hasFuelBonus;

  final List<AttackMode> usageRestrictions;
  final List<String> targetTypes;
  final String category;
  final String briefDescription;
  final String targets;
  final String fireRegime;

  /// US-6.3: Remaining ammunition. -1 = unlimited.
  final int ammoCount;

  /// US-6.3: Altitude restriction. null = no restriction.
  final Altitude? altitudeRestriction;

  /// Parses weapon class restrictions like "*A", "*B" from text to determine which DroneClasses can equip.
  /// Rule: Class A -> *A, *B, *C, *D. Class B -> *B, *C, *D. Class C -> *C, *D. Class D -> *D.
  /// If weapon is *A, only A. If *B, A and B. If *C, A, B, C. If *D, A, B, C, D. 
  static List<DroneClass> parseClassRestrictions(String? text) {
    if (text == null || text.isEmpty) return DroneClass.values; // default: all
    final upper = text.toUpperCase();
    if (upper.contains('*A')) return [DroneClass.a];
    if (upper.contains('*B')) return [DroneClass.a, DroneClass.b];
    if (upper.contains('*C')) return [DroneClass.a, DroneClass.b, DroneClass.c];
    if (upper.contains('*D')) return DroneClass.values;
    // Default fallback if no tag
    return DroneClass.values;
  }


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

  const Loadout({
    required this.id,
    required this.name,
    required this.type,
    required this.description,
    required this.classRestrictions,
    this.usageRestrictions = const [],
    this.targetTypes = const [],
    this.drmModifier = 0,
    this.fuelModifier = 0,
    this.isExclusive = false,
    this.hasFuelBonus = false,
    this.ammoCount = -1,
    this.altitudeRestriction,
    this.category = '',
    this.briefDescription = '',
    this.targets = '',
    this.fireRegime = '',
    this.drmTruck = 0,
    this.drmPersonnel = 0,
    this.drmAfv = 0,
    this.drmSam = 0,
    this.drmTank = 0,
    this.drmArtillery = 0,
    this.drmHqBunker = 0,
    this.drmVip = 0,
    this.drmAir = 0,
  });

  /// US-6.3: True if weapon has ammo remaining (or is unlimited).
  bool get hasAmmo => ammoCount == -1 || ammoCount > 0;

  /// US-6.3: Returns a copy with one less ammo.
  Loadout consumeAmmo() {
    if (ammoCount == -1) return this; // unlimited
    return _copyWith(ammoCount: ammoCount - 1);
  }

  /// US-6.3 / PRD V1: True if weapon can be used at the given altitude.
  /// Uses fireRegime string (comma-separated: 'VLOW, LOW, MEDIUM') if set,
  /// falls back to legacy altitudeRestriction enum.
  bool isAvailableAt(Altitude altitude) {
    // PRD V1: check fireRegime string first
    if (fireRegime.isNotEmpty) {
      final allowed = fireRegime.toUpperCase().split(',').map((s) => s.trim()).toList();
      return allowed.contains(altitude.displayName);
    }
    // Legacy fallback
    if (altitudeRestriction == null) return true;
    return altitude == altitudeRestriction;
  }

  /// Returns the specific DRM modifier for the given target type from V0.2 DB.
  int getTargetDrm(TargetCardType targetType) {
    switch (targetType) {
      case TargetCardType.truck:
        return drmTruck;
      case TargetCardType.personnel:
        return drmPersonnel;
      case TargetCardType.afv:
        return drmAfv;
      case TargetCardType.sam:
        return drmSam;
      case TargetCardType.tank:
        return drmTank;
      case TargetCardType.artillery:
        return drmArtillery;
      case TargetCardType.hqBunker:
        return drmHqBunker;
      case TargetCardType.vip:
        return drmVip;
      case TargetCardType.aerial:
        return drmAir;
      case TargetCardType.engineer:
        return 0; // PRD V1: ENGINEER DRM — no specific column yet
    }
  }

  Loadout _copyWith({int? ammoCount}) => Loadout(
    id: id,
    name: name,
    type: type,
    description: description,
    classRestrictions: classRestrictions,
    usageRestrictions: usageRestrictions,
    targetTypes: targetTypes,
    drmModifier: drmModifier,
    fuelModifier: fuelModifier,
    isExclusive: isExclusive,
    hasFuelBonus: hasFuelBonus,
    ammoCount: ammoCount ?? this.ammoCount,
    altitudeRestriction: altitudeRestriction,
    category: category,
    briefDescription: briefDescription,
    targets: targets,
    fireRegime: fireRegime,
    drmTruck: drmTruck,
    drmPersonnel: drmPersonnel,
    drmAfv: drmAfv,
    drmSam: drmSam,
    drmTank: drmTank,
    drmArtillery: drmArtillery,
    drmHqBunker: drmHqBunker,
    drmVip: drmVip,
    drmAir: drmAir,
  );

  /// US-B-12: Replenish ammunition.
  Loadout addAmmo(int amount) {
    if (ammoCount == -1) return this;
    return _copyWith(ammoCount: ammoCount + amount);
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type,
    'description': description,
    'classRestrictions': classRestrictions.map((c) => c.index).toList(),
    'usageRestrictions': usageRestrictions.map((m) => m.index).toList(),
    'targetTypes': targetTypes,
    'drmModifier': drmModifier,
    'fuelModifier': fuelModifier,
    'isExclusive': isExclusive,
    'hasFuelBonus': hasFuelBonus,
    'ammoCount': ammoCount,
    'altitudeRestriction': altitudeRestriction?.index,
    'category': category,
    'briefDescription': briefDescription,
    'targets': targets,
    'fireRegime': fireRegime,
    'drmTruck': drmTruck,
    'drmPersonnel': drmPersonnel,
    'drmAfv': drmAfv,
    'drmSam': drmSam,
    'drmTank': drmTank,
    'drmArtillery': drmArtillery,
    'drmHqBunker': drmHqBunker,
    'drmVip': drmVip,
    'drmAir': drmAir,
  };

  factory Loadout.fromJson(Map<String, dynamic> json) => Loadout(
    id: json['id'] as String,
    name: json['name'] as String,
    type: json['type'] as String,
    description: json['description'] as String,
    classRestrictions: (json['classRestrictions'] as List).map((c) {
      if (c is int) return DroneClass.values[c];
      final name = (c as String).toLowerCase();
      return DroneClass.values.firstWhere(
        (e) => e.name == name,
        orElse: () => DroneClass.a,
      );
    }).toList(),
    usageRestrictions: (json['usageRestrictions'] as List? ?? [])
        .map((m) => AttackMode.values[m as int])
        .toList(),
    targetTypes: (json['targetTypes'] as List? ?? []).cast<String>(),
    drmModifier: json['drmModifier'] as int? ?? 0,
    fuelModifier: json['fuelModifier'] as int? ?? 0,
    isExclusive: json['isExclusive'] as bool? ?? false,
    hasFuelBonus: json['hasFuelBonus'] as bool? ?? false,
    ammoCount: json['ammoCount'] as int? ?? -1,
    altitudeRestriction: json['altitudeRestriction'] != null
        ? Altitude.values[json['altitudeRestriction'] as int]
        : null,
    category: json['category'] as String? ?? '',
    briefDescription: json['briefDescription'] as String? ?? '',
    targets: json['targets'] as String? ?? '',
    fireRegime: json['fireRegime'] as String? ?? '',
    drmTruck: json['drmTruck'] as int? ?? 0,
    drmPersonnel: json['drmPersonnel'] as int? ?? 0,
    drmAfv: json['drmAfv'] as int? ?? 0,
    drmSam: json['drmSam'] as int? ?? 0,
    drmTank: json['drmTank'] as int? ?? 0,
    drmArtillery: json['drmArtillery'] as int? ?? 0,
    drmHqBunker: json['drmHqBunker'] as int? ?? 0,
    drmVip: json['drmVip'] as int? ?? 0,
    drmAir: json['drmAir'] as int? ?? 0,
  );
}
