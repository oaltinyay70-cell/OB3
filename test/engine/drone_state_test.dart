import 'package:flutter_test/flutter_test.dart';
import 'package:drone_commander/engine/drone_state.dart';
import 'package:drone_commander/models/game_enums.dart';

void main() {
  group('DroneState Derived Getters', () {
    test('calculate damage cascades correctly', () {
      final state = DroneState(
        fuel: 100, maxFuel: 100, maxIntegrity: 10, altitude: Altitude.medium, allowedAltitudes: [Altitude.medium],
        loadout: [], hasAesa: false, hasSatcom: false, hasCommsRedundancy: false, hasAutonomousAi: false, hasBuiltinFoLaze: false,
        structuralDamage: 5, permanentSensorDamage: 1, permanentCommsDamage: 1,
      );
      expect(state.sensorsDamage, 3);
      expect(state.commsDamage, 2);
    });

    test('clamped values do not exceed max', () {
      final state = DroneState(
        fuel: 100, maxFuel: 100, maxIntegrity: 100, altitude: Altitude.high, allowedAltitudes: [Altitude.high],
        loadout: [], hasAesa: false, hasSatcom: false, hasCommsRedundancy: false, hasAutonomousAi: false, hasBuiltinFoLaze: false,
        structuralDamage: 50, permanentSensorDamage: 5, permanentCommsDamage: 5,
      );
      expect(state.sensorsDamage, 9);
      expect(state.commsDamage, 5);
    });
  });
}
