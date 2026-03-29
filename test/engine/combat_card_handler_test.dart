import 'package:flutter_test/flutter_test.dart';
import 'package:drone_commander/engine/combat_card_handler.dart';
import 'package:drone_commander/engine/drone_state.dart';
import 'package:drone_commander/models/combat_card.dart';
import 'package:drone_commander/models/game_enums.dart';

void main() {
  group('CombatCardHandler minimal branch test', () {
    late DroneState state;
    setUp(() {
      state = DroneState(
        fuel: 10, maxFuel: 10, maxIntegrity: 10, altitude: Altitude.medium, allowedAltitudes: [Altitude.medium, Altitude.low, Altitude.vlow, Altitude.high],
        loadout: [], hasAesa: false, hasSatcom: false, hasCommsRedundancy: false, hasAutonomousAi: false, hasBuiltinFoLaze: false,
      );
    });

    test('CC024 altitude spike', () {
      final effect = CombatCardHandler.apply(const CombatCard(cardNumber: 'CC024', cardName: 'THERMAL SPIKE', instructions: ''), state);
      expect(effect.type, CombatCardEffectType.altitudeChange);
      expect(effect.altitudeSteps, 1);
      
      CombatCardHandler.applyAltitudeEffect(effect, state);
      expect(state.altitude, Altitude.high);
    });
  });
}
