import 'drone_state.dart';

/// Encapsulates all damage application logic per rulebook §6.4.5.
///
/// Damage cascading:
/// - Structural integrity → direct damage counter
/// - Every 2 pts structural → +1 sensors (max 9)
/// - Every 3 pts structural → +1 comms (max 5)
/// - Every 1 pt sensors OR comms raise → +1 VIS
/// - Every 4 pts sensor damage → -1 attack DRM
/// - Destruction: structural damage ≥ max integrity
class DamageSystem {
  DamageSystem._();

  /// Apply damage to the drone state and return a summary.
  ///
  /// [amount] is the "D" value from the CRT (e.g., 1D = 1, 2D = 2).
  /// Returns a [DamageReport] describing what happened.
  static DamageReport applyDamage(DroneState state, int amount) {
    if (amount <= 0) {
      return const DamageReport(
        structuralAdded: 0,
        sensorsAdded: 0,
        commsAdded: 0,
        visAdded: 0,
        isDestroyed: false,
      );
    }


    final prevSensors = state.sensorsDamage;
    final prevComms = state.commsDamage;
    final prevVis = state.vis;

    // Apply structural damage
    state.takeDamage(amount);

    // Calculate cascaded changes (derived from getters)
    final newSensors = state.sensorsDamage;
    final newComms = state.commsDamage;
    final newVis = state.vis;

    return DamageReport(
      structuralAdded: amount,
      sensorsAdded: newSensors - prevSensors,
      commsAdded: newComms - prevComms,
      visAdded: newVis - prevVis,
      isDestroyed: state.isDestroyed,
    );
  }

  /// Check if the drone should be destroyed based on current state.
  static bool checkDestruction(DroneState state) => state.isDestroyed;
}

/// Summary of damage application.
class DamageReport {
  const DamageReport({
    required this.structuralAdded,
    required this.sensorsAdded,
    required this.commsAdded,
    required this.visAdded,
    required this.isDestroyed,
  });

  final int structuralAdded;
  final int sensorsAdded;
  final int commsAdded;
  final int visAdded;
  final bool isDestroyed;

  @override
  String toString() {
    final parts = <String>[];
    if (structuralAdded > 0) parts.add('$structuralAdded structural');
    if (sensorsAdded > 0) parts.add('$sensorsAdded sensors');
    if (commsAdded > 0) parts.add('$commsAdded comms');
    if (visAdded > 0) parts.add('$visAdded VIS');
    if (isDestroyed) parts.add('DESTROYED');
    return parts.isEmpty ? 'No damage' : parts.join(', ');
  }
}
