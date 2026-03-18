import '../models/game_enums.dart';
import '../models/weapon.dart';

/// A weapon slot in the drone's active loadout during a game.
class LoadoutSlot {
  LoadoutSlot({
    required this.weapon,
    required this.quantity,
    int? initialQuantity,
  }) : initialQuantity = initialQuantity ?? quantity;

  final Weapon weapon;
  int quantity;
  final int initialQuantity;

  /// Whether this slot still has ammunition.
  bool get hasAmmo => quantity > 0;

  /// Use one unit of this weapon. Returns false if already empty.
  bool use() {
    if (quantity <= 0) return false;
    quantity--;
    return true;
  }

  /// Create a deep copy.
  LoadoutSlot copyWith({int? quantity, int? initialQuantity}) =>
      LoadoutSlot(
        weapon: weapon, 
        quantity: quantity ?? this.quantity,
        initialQuantity: initialQuantity ?? this.initialQuantity,
      );
}

/// Mutable state of the drone during gameplay.
///
/// Tracks fuel, damage, altitude, loadout, and derived values.
/// Uses copyWith for immutable-style updates while allowing
/// direct mutation for the engine's internal state machine.
class DroneState {
  DroneState({
    required this.fuel,
    required this.maxFuel,
    required this.maxIntegrity,
    required this.altitude,
    required this.allowedAltitudes,
    required this.loadout,
    required this.hasAesa,
    required this.hasSatcom,
    required this.hasCommsRedundancy,
    required this.hasAutonomousAi,
    required this.hasBuiltinFoLaze,
    this.structuralDamage = 0,
    this.permanentSensorDamage = 0,
    this.permanentCommsDamage = 0,
    this.permanentVisMod = 0,
    this.commsCheckPenalty = 0,
  });

  // --- Fuel ---
  int fuel;
  final int maxFuel;

  // --- Structural ---
  int structuralDamage;
  final int maxIntegrity;

  // --- Altitude ---
  Altitude altitude;
  final List<Altitude> allowedAltitudes;

  // --- Loadout ---
  final List<LoadoutSlot> loadout;

  // --- Capabilities ---
  final bool hasAesa;
  final bool hasSatcom;
  final bool hasCommsRedundancy;
  final bool hasAutonomousAi;
  final bool hasBuiltinFoLaze;

  // --- Permanent modifiers from combat cards ---
  int permanentSensorDamage;
  int permanentCommsDamage;
  int permanentVisMod;

  // --- COMMS check penalty applied this turn ---
  int commsCheckPenalty;

  // ---------------------------------------------------------------------------
  // Derived values (cascading damage per rulebook §6.4.5)
  // ---------------------------------------------------------------------------

  /// Sensor damage = structural / 2 + permanent, capped at 9.
  int get sensorsDamage =>
      (structuralDamage ~/ 2 + permanentSensorDamage).clamp(0, 9);

  /// COMMS damage = structural / 3 + permanent, capped at 5.
  int get commsDamage =>
      (structuralDamage ~/ 3 + permanentCommsDamage).clamp(0, 5);

  /// VIS/RCS = sensors damage + comms damage + permanent modifier.
  int get vis => sensorsDamage + commsDamage + permanentVisMod;

  /// Attack DRM penalty from sensor damage: -1 per 4 points.
  int get sensorAttackPenalty => -(sensorsDamage ~/ 4);

  /// Whether COMMS check is required (damage > 2).
  bool get requiresCommsCheck => commsDamage > 2;

  /// COMMS check DRM reduction from drone capabilities.
  int get commsCheckDrmReduction {
    int mod = 0;
    if (hasSatcom) mod -= 1;
    if (hasCommsRedundancy) mod -= 1;
    if (hasAutonomousAi) mod -= 1;
    return mod;
  }

  /// Target acquisition DRM from capabilities.
  int get targetAcquisitionDrm {
    int drm = 0;
    if (hasAesa) drm += 10;
    if (commsDamage == 0) {
      drm += 10;
    } else {
      drm -= commsDamage * 10;
    }
    return drm;
  }

  /// Threat determination DRM from VIS.
  int get threatDeterminationDrm {
    // +10 for each 2 points of VIS
    return (vis ~/ 2) * 10;
  }

  /// Whether the drone is destroyed.
  bool get isDestroyed => structuralDamage >= maxIntegrity;

  /// Whether the drone has any weapons remaining.
  bool get hasAmmo => loadout.any((slot) => slot.hasAmmo);

  /// Whether the drone can perform FO/Laze missions.
  bool get canFoLaze =>
      hasBuiltinFoLaze ||
      loadout.any(
          (slot) => slot.weapon.weaponType == WeaponType.kit && slot.hasAmmo);

  /// Fuel as a fraction (0.0 to 1.0) for UI fuel bar.
  double get fuelFraction => maxFuel > 0 ? fuel / maxFuel : 0.0;

  // ---------------------------------------------------------------------------
  // Mutations
  // ---------------------------------------------------------------------------

  /// Spend fuel. Returns false if insufficient.
  bool spendFuel(int amount) {
    if (fuel < amount) return false;
    fuel -= amount;
    return true;
  }

  /// Take structural damage and cascade to subsystems.
  void takeDamage(int amount) {
    structuralDamage += amount;
    // Cascading happens automatically via derived getters.
  }

  /// Change altitude. Returns fuel cost (0 if invalid).
  int changeAltitude(Altitude target) {
    if (!allowedAltitudes.contains(target)) return -1;
    final cost = altitude.fuelCostTo(target);
    if (cost > 0 && fuel < cost) return -1;
    if (cost > 0) fuel -= cost;
    altitude = target;
    return cost;
  }
}
