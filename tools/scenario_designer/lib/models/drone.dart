import '../../utils/constants.dart';
import 'loadout.dart';
import 'loadout_preset.dart';

class Drone {
  final String droneId;
  final String name;
  final DroneClass droneClass;
  final int maxStructuralIntegrity;
  final Altitude maxAltitude;
  final int structuralIntegrityDamage;
  final int sensorsDamage;
  final int commsDamage;
  final int visibility;
  final Altitude currentAltitude;
  final List<Loadout> activeLoadout;
  final String category;
  final String country;
  final String range;
  final int hardpoints;
  final String maxPayload;
  final String stationWeightLimits;
  final List<LoadoutPreset> validLoadoutPresets;

  // New V0.2 Drone properties
  final bool hasBuiltInFoLaze;
  final bool hasAeasaRadar;
  final bool hasSatcom;
  final bool hasCommsRedundancy;
  final bool hasAutonomousAi;

  // Unified Fuel System (hours): replaces old int fuel + endurance
  final double maxFuel;         // max endurance in hours (from DB max_endurance_hours)
  final double fuelOnboard;     // current fuel remaining in hours
  final double fuelPerAltitudeGain;
  final double fuelPerAltitudeLoss;

  // Weapon Lock
  final String compatibleWeapons; // pipe-separated weapon names from DB

  const Drone({
    required this.droneId,
    required this.name,
    required this.droneClass,
    required this.maxStructuralIntegrity,
    required this.maxFuel,
    required this.maxAltitude,
    this.structuralIntegrityDamage = 0,
    this.sensorsDamage = 0,
    this.commsDamage = 0,
    this.visibility = 0,
    required this.fuelOnboard,
    this.currentAltitude = Altitude.medium,  // default: medium altitude
    this.activeLoadout = const [],
    this.category = '',
    this.country = '',
    this.range = '',
    this.hardpoints = 4,
    this.maxPayload = '',
    this.stationWeightLimits = '',
    this.validLoadoutPresets = const [],
    this.hasBuiltInFoLaze = true,
    this.hasAeasaRadar = false,
    this.hasSatcom = false,
    this.hasCommsRedundancy = false,
    this.hasAutonomousAi = false,
    this.fuelPerAltitudeGain = 2.0,
    this.fuelPerAltitudeLoss = 1.0,
    this.compatibleWeapons = '',
  });

  bool get isDestroyed => structuralIntegrityDamage >= maxStructuralIntegrity;

  int get attackPenalty => -(sensorsDamage ~/ 4);

  DroneStatus get status {
    if (isDestroyed) return DroneStatus.destroyed;
    if (structuralIntegrityDamage >= maxStructuralIntegrity * 0.75) {
      return DroneStatus.critical;
    }
    if (structuralIntegrityDamage > 0) return DroneStatus.damaged;
    return DroneStatus.operational;
  }

  Drone takeDamage(int amount) {
    // Rules: 
    // - Every 2 points integrity → +1 sensor (max 9)
    // - Every 3 points integrity → +1 COMMS (max 5)
    // - Every sensor/COMMS gained adds +1 visibility
    
    final newIntegrityDamage = structuralIntegrityDamage + amount;
    
    final totalSensors = (newIntegrityDamage ~/ 2).clamp(0, GameConstants.maxSensorsDamage);
    final totalComms = (newIntegrityDamage ~/ 3).clamp(0, GameConstants.maxCommsDamage);
    
    return copyWith(
      structuralIntegrityDamage: newIntegrityDamage,
      sensorsDamage: totalSensors,
      commsDamage: totalComms,
      visibility: totalSensors + totalComms,
    );
  }

  /// Consume fuel hours. Allows going negative (crash scenario).
  Drone consumeFuel(double hours) {
    return copyWith(fuelOnboard: fuelOnboard - hours);
  }

  /// Add fuel hours, capped at maxFuel (e.g. weapon range bonus).
  Drone addFuel(double hours) {
    return copyWith(fuelOnboard: (fuelOnboard + hours).clamp(0.0, maxFuel));
  }

  /// Check if consuming fuel would crash the drone.
  bool wouldCrash(double fuelCost) => (fuelOnboard - fuelCost) < 0;

  /// Number of turns flown (1h/turn).
  int get turnsFlown => (maxFuel - fuelOnboard).round().clamp(0, maxFuel.round());

  /// PRD V1: Check if a weapon is compatible with this drone.
  bool isWeaponCompatible(String weaponName) {
    if (compatibleWeapons.isEmpty) return true; // no restriction
    return compatibleWeapons.split('|').any(
      (w) => w.trim().toLowerCase() == weaponName.trim().toLowerCase(),
    );
  }

  /// PRD V1: Get list of compatible weapon names.
  List<String> get compatibleWeaponList {
    if (compatibleWeapons.isEmpty) return [];
    return compatibleWeapons.split('|').map((w) => w.trim()).toList();
  }

  Drone copyWith({
    String? droneId,
    String? name,
    DroneClass? droneClass,
    int? maxStructuralIntegrity,
    double? maxFuel,
    Altitude? maxAltitude,
    int? structuralIntegrityDamage,
    int? sensorsDamage,
    int? commsDamage,
    int? visibility,
    double? fuelOnboard,
    Altitude? currentAltitude,
    List<Loadout>? activeLoadout,
    String? category,
    String? country,
    String? range,
    int? hardpoints,
    String? maxPayload,
    String? stationWeightLimits,
    List<LoadoutPreset>? validLoadoutPresets,
    bool? hasBuiltInFoLaze,
    bool? hasAeasaRadar,
    bool? hasSatcom,
    bool? hasCommsRedundancy,
    bool? hasAutonomousAi,
    double? fuelPerAltitudeGain,
    double? fuelPerAltitudeLoss,
    String? compatibleWeapons,
  }) {
    return Drone(
      droneId: droneId ?? this.droneId,
      name: name ?? this.name,
      droneClass: droneClass ?? this.droneClass,
      maxStructuralIntegrity: maxStructuralIntegrity ?? this.maxStructuralIntegrity,
      maxFuel: maxFuel ?? this.maxFuel,
      maxAltitude: maxAltitude ?? this.maxAltitude,
      structuralIntegrityDamage: structuralIntegrityDamage ?? this.structuralIntegrityDamage,
      sensorsDamage: sensorsDamage ?? this.sensorsDamage,
      commsDamage: commsDamage ?? this.commsDamage,
      visibility: visibility ?? this.visibility,
      fuelOnboard: fuelOnboard ?? this.fuelOnboard,
      currentAltitude: currentAltitude ?? this.currentAltitude,
      activeLoadout: activeLoadout ?? this.activeLoadout,
      category: category ?? this.category,
      country: country ?? this.country,
      range: range ?? this.range,
      hardpoints: hardpoints ?? this.hardpoints,
      maxPayload: maxPayload ?? this.maxPayload,
      stationWeightLimits: stationWeightLimits ?? this.stationWeightLimits,
      validLoadoutPresets: validLoadoutPresets ?? this.validLoadoutPresets,
      hasBuiltInFoLaze: hasBuiltInFoLaze ?? this.hasBuiltInFoLaze,
      hasAeasaRadar: hasAeasaRadar ?? this.hasAeasaRadar,
      hasSatcom: hasSatcom ?? this.hasSatcom,
      hasCommsRedundancy: hasCommsRedundancy ?? this.hasCommsRedundancy,
      hasAutonomousAi: hasAutonomousAi ?? this.hasAutonomousAi,
      fuelPerAltitudeGain: fuelPerAltitudeGain ?? this.fuelPerAltitudeGain,
      fuelPerAltitudeLoss: fuelPerAltitudeLoss ?? this.fuelPerAltitudeLoss,
      compatibleWeapons: compatibleWeapons ?? this.compatibleWeapons,
    );
  }

  Map<String, dynamic> toJson() => {
    'droneId': droneId,
    'name': name,
    'droneClass': droneClass.index,
    'maxStructuralIntegrity': maxStructuralIntegrity,
    'maxFuel': maxFuel,
    'maxAltitude': maxAltitude.index,
    'structuralIntegrityDamage': structuralIntegrityDamage,
    'sensorsDamage': sensorsDamage,
    'commsDamage': commsDamage,
    'visibility': visibility,
    'fuelOnboard': fuelOnboard,
    'currentAltitude': currentAltitude.index,
    'activeLoadout': activeLoadout.map((l) => l.toJson()).toList(),
    'category': category,
    'country': country,
    'range': range,
    'hardpoints': hardpoints,
    'maxPayload': maxPayload,
    'stationWeightLimits': stationWeightLimits,
    'validLoadoutPresets': validLoadoutPresets.map((p) => p.toJson()).toList(),
    'hasBuiltInFoLaze': hasBuiltInFoLaze,
    'hasAeasaRadar': hasAeasaRadar,
    'hasSatcom': hasSatcom,
    'hasCommsRedundancy': hasCommsRedundancy,
    'hasAutonomousAi': hasAutonomousAi,
    'fuelPerAltitudeGain': fuelPerAltitudeGain,
    'fuelPerAltitudeLoss': fuelPerAltitudeLoss,
    'compatibleWeapons': compatibleWeapons,
  };

  factory Drone.fromJson(Map<String, dynamic> json) => Drone(
    droneId: json['droneId'] as String,
    name: json['name'] as String,
    droneClass: DroneClass.values[json['droneClass'] as int],
    maxStructuralIntegrity: json['maxStructuralIntegrity'] as int,
    maxFuel: (json['maxFuel'] as num?)?.toDouble() ?? 24.0,
    maxAltitude: Altitude.values[json['maxAltitude'] as int],
    structuralIntegrityDamage: json['structuralIntegrityDamage'] as int,
    sensorsDamage: json['sensorsDamage'] as int,
    commsDamage: json['commsDamage'] as int,
    visibility: json['visibility'] as int,
    fuelOnboard: (json['fuelOnboard'] as num?)?.toDouble() 
        ?? (json['enduranceRemaining'] as num?)?.toDouble() 
        ?? 24.0,
    currentAltitude: Altitude.values[json['currentAltitude'] as int? ?? Altitude.medium.index],
    activeLoadout: (json['activeLoadout'] as List)
        .map((l) => Loadout.fromJson(l is Map<String, dynamic> ? l : Map<String, dynamic>.from(l as Map)))
        .toList(),
    category: json['category'] as String? ?? '',
    country: json['country'] as String? ?? '',
    range: json['range'] as String? ?? '',
    hardpoints: json['hardpoints'] as int? ?? 4,
    maxPayload: json['maxPayload'] as String? ?? '',
    stationWeightLimits: json['stationWeightLimits'] as String? ?? '',
    validLoadoutPresets: (json['validLoadoutPresets'] as List? ?? [])
        .map((p) => LoadoutPreset.fromJson(p is Map<String, dynamic> ? p : Map<String, dynamic>.from(p as Map)))
        .toList(),
    hasBuiltInFoLaze: json['hasBuiltInFoLaze'] as bool? ?? true,
    hasAeasaRadar: json['hasAeasaRadar'] as bool? ?? false,
    hasSatcom: json['hasSatcom'] as bool? ?? false,
    hasCommsRedundancy: json['hasCommsRedundancy'] as bool? ?? false,
    hasAutonomousAi: json['hasAutonomousAi'] as bool? ?? false,
    fuelPerAltitudeGain: (json['fuelPerAltitudeGain'] as num?)?.toDouble() ?? 2.0,
    fuelPerAltitudeLoss: (json['fuelPerAltitudeLoss'] as num?)?.toDouble() ?? 1.0,
    compatibleWeapons: json['compatibleWeapons'] as String? ?? '',
  );
}
