import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'game_enums.dart';

/// A single loadout option defined on a drone info card.
/// Each option can carry up to 2 weapon types with quantities.
class LoadoutOption extends Equatable {
  const LoadoutOption({
    required this.optionNumber,
    required this.weapon1Name,
    required this.weapon1Qty,
    this.weapon2Name,
    this.weapon2Qty,
  });

  final int optionNumber;
  final String weapon1Name;
  final int weapon1Qty;
  final String? weapon2Name;
  final int? weapon2Qty;

  @override
  List<Object?> get props =>
      [optionNumber, weapon1Name, weapon1Qty, weapon2Name, weapon2Qty];
}

/// Immutable drone definition loaded from the database.
class Drone extends Equatable {
  const Drone({
    required this.id,
    required this.name,
    required this.country,
    required this.category,
    required this.droneClass,
    required this.allowedAltitudes,
    required this.maxStructuralIntegrity,
    required this.hasBuiltinFoLaze,
    required this.hasAesa,
    required this.hasSatcom,
    required this.hasCommsRedundancy,
    required this.hasAutonomousAi,
    required this.loadoutOptions,
    required this.rcs,
    required this.vis,
    this.range,
    this.stations,
    this.maxPayload,
    this.description,
    this.image,
  });

  final int id;
  final String name;
  final String country;
  final String? category;
  final DroneClass droneClass;
  final List<Altitude> allowedAltitudes;
  final int maxStructuralIntegrity;
  final bool hasBuiltinFoLaze;
  final bool hasAesa;
  final bool hasSatcom;
  final bool hasCommsRedundancy;
  final bool hasAutonomousAi;
  final List<LoadoutOption> loadoutOptions;
  final int rcs;
  final int vis;
  final String? range;
  final int? stations;
  final String? maxPayload;
  final String? description;
  final Uint8List? image;

  /// Default fuel value. Will be replaced by endurance_hours when column is added.
  int get defaultFuel => 24;

  /// Highest altitude this drone can reach.
  Altitude get maxAltitude =>
      allowedAltitudes.isNotEmpty ? allowedAltitudes.last : Altitude.low;

  /// COMMS check DRM reduction from capabilities.
  int get commsCheckDrmReduction {
    int reduction = 0;
    if (hasSatcom) reduction -= 1;
    if (hasCommsRedundancy) reduction -= 1;
    if (hasAutonomousAi) reduction -= 1;
    return reduction;
  }

  /// Parse a drone from a database row map.
  factory Drone.fromMap(Map<String, dynamic> map) {
    final loadouts = <LoadoutOption>[];
    for (int i = 1; i <= 5; i++) {
      final w1Name = map['opt${i}_wpn1_name'] as String?;
      final w1Qty = map['opt${i}_wpn1_qty'] as int?;
      if (w1Name != null && w1Name.isNotEmpty && w1Qty != null && w1Qty > 0) {
        loadouts.add(LoadoutOption(
          optionNumber: i,
          weapon1Name: w1Name,
          weapon1Qty: w1Qty,
          weapon2Name: map['opt${i}_wpn2_name'] as String?,
          weapon2Qty: map['opt${i}_wpn2_qty'] as int?,
        ));
      }
    }

    return Drone(
      id: map['id'] as int,
      name: map['name'] as String,
      country: map['country'] as String? ?? 'Unknown',
      category: map['category'] as String?,
      droneClass: DroneClass.fromDb(map['drone_class'] as String?),
      allowedAltitudes: Altitude.parseFromDb(map['altitude'] as String?),
      maxStructuralIntegrity: map['max_structural_integrity'] as int? ?? 1000,
      hasBuiltinFoLaze: (map['has_builtin_fo_laze'] as int? ?? 1) == 1,
      hasAesa: (map['has_aeasa_radar'] as int? ?? 0) == 1,
      hasSatcom: (map['has_satcom'] as int? ?? 0) == 1,
      hasCommsRedundancy: (map['has_comms_redundancy'] as int? ?? 0) == 1,
      hasAutonomousAi: (map['has_autonomous_ai'] as int? ?? 0) == 1,
      loadoutOptions: loadouts,
      rcs: map['rcs'] as int? ?? 0,
      vis: map['vis'] as int? ?? 0,
      range: map['range'] as String?,
      stations: map['stations'] as int?,
      maxPayload: map['max_payload'] as String?,
      description: map['description'] as String?,
      image: map['image'] as Uint8List?,
    );
  }

  @override
  List<Object?> get props => [id, name];
}
