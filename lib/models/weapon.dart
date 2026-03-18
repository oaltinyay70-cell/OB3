import 'package:equatable/equatable.dart';
import 'game_enums.dart';

/// Immutable weapon definition loaded from the database.
class Weapon extends Equatable {
  const Weapon({
    required this.id,
    required this.name,
    required this.weaponType,
    this.description,
    this.targets,
    this.fireRange,
    required this.fireAltitudes,
    required this.drmByTargetType,
  });

  final int id;
  final String name;
  final WeaponType weaponType;
  final String? description;
  final String? targets;
  final String? fireRange;
  final List<Altitude> fireAltitudes;

  /// DRM modifier per target type.
  final Map<TargetType, int> drmByTargetType;

  /// Allowed attack modes derived from the `fire_range` DB field.
  ///
  /// - Contains 'close' → Close-In allowed
  /// - Contains 'medium' or 'far' → Stand-Off allowed
  /// - 'close-medium' → both Close-In and Stand-Off
  /// - FO/Laze Kit is always used in FO/Laze mode only
  List<AttackMode> get allowedAttackModes {
    final raw = (fireRange ?? '').toLowerCase().trim();
    final modes = <AttackMode>[];

    if (raw.contains('close')) modes.add(AttackMode.closeIn);
    if (raw.contains('medium') || raw.contains('far')) {
      modes.add(AttackMode.standOff);
    }

    // Fallback: if no mode could be parsed, default to stand-off.
    if (modes.isEmpty) modes.add(AttackMode.standOff);

    return modes;
  }

  /// Whether this weapon can be fired in the given attack mode.
  bool canFireInMode(AttackMode mode) => allowedAttackModes.contains(mode);

  /// Get DRM for a specific target type.
  int getDrm(TargetType targetType) => drmByTargetType[targetType] ?? 0;

  /// Whether this weapon can engage the given target type.
  ///
  /// Uses two-layer check:
  /// 1. Weapon Type vs Target Type matrix (PRD §4.8.4) — hard constraint
  /// 2. Individual weapon DRM (if all DRM are 0 for a type already allowed
  ///    by the matrix, the weapon is still allowed — DRM 0 means neutral,
  ///    not blocked)
  bool canEngageTargetType(TargetType targetType) =>
      weaponType.canEngage(targetType);

  /// Whether this weapon can fire at the given altitude.
  bool canFireAtAltitude(Altitude alt) => fireAltitudes.contains(alt);

  factory Weapon.fromMap(Map<String, dynamic> map) {
    return Weapon(
      id: map['id'] as int,
      name: map['name'] as String,
      weaponType: WeaponType.fromDb(map['wpn_type'] as String? ?? 'ATGM'),
      description: map['description'] as String?,
      targets: map['targets'] as String?,
      fireRange: map['fire_range'] as String?,
      fireAltitudes:
          Altitude.parseFromDb(map['fire_altitude'] as String?),
      drmByTargetType: {
        TargetType.truck: map['drm_truck'] as int? ?? 0,
        TargetType.personnel: map['drm_personnel'] as int? ?? 0,
        TargetType.afv: map['drm_afv'] as int? ?? 0,
        TargetType.sam: map['drm_sam'] as int? ?? 0,
        TargetType.tank: map['drm_tank'] as int? ?? 0,
        TargetType.artillery: map['drm_artillery'] as int? ?? 0,
        TargetType.hqBunker: map['drm_hq_bunker'] as int? ?? 0,
        TargetType.vip: map['drm_vip'] as int? ?? 0,
        TargetType.air: map['drm_air'] as int? ?? 0,
      },
    );
  }

  @override
  List<Object?> get props => [id, name];
}
