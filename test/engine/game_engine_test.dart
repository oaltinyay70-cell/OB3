import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:drone_commander/engine/dice_service.dart';
import 'package:drone_commander/engine/deck_manager.dart';
import 'package:drone_commander/engine/combat_resolution.dart';
import 'package:drone_commander/engine/damage_system.dart';
import 'package:drone_commander/engine/drone_state.dart';
import 'package:drone_commander/engine/scoring_service.dart';
import 'package:drone_commander/engine/target_acquisition.dart';
import 'package:drone_commander/engine/threat_determination.dart';
import 'package:drone_commander/engine/game_engine.dart';
import 'package:drone_commander/engine/scenario_loader.dart';
import 'package:drone_commander/engine/combat_card_handler.dart';
import 'package:drone_commander/models/game_enums.dart';
import 'package:drone_commander/models/combat_card.dart';
import 'package:drone_commander/models/target_card.dart';
import 'package:drone_commander/models/threat_card.dart';
import 'package:drone_commander/models/weapon.dart';
import 'package:drone_commander/models/drone.dart';

void main() {
  // ===========================================================================
  // DiceService Tests
  // ===========================================================================
  group('DiceService', () {
    test('rollD6 returns values 1-6 with seeded Random', () {
      final dice = DiceService(random: Random(42));
      final rolls = List.generate(100, (_) => dice.rollD6());
      for (final r in rolls) {
        expect(r, greaterThanOrEqualTo(1));
        expect(r, lessThanOrEqualTo(6));
      }
    });

    test('roll2D10 returns values 0-99', () {
      final dice = DiceService(random: Random(42));
      final rolls = List.generate(100, (_) => dice.roll2D10());
      for (final r in rolls) {
        expect(r.value, greaterThanOrEqualTo(0));
        expect(r.value, lessThanOrEqualTo(99));
        expect(r.ones, greaterThanOrEqualTo(0));
        expect(r.ones, lessThanOrEqualTo(9));
        expect(r.tens, greaterThanOrEqualTo(0));
        expect(r.tens, lessThanOrEqualTo(9));
      }
    });

    test('seeded Random produces deterministic results', () {
      final dice1 = DiceService(random: Random(123));
      final dice2 = DiceService(random: Random(123));
      for (int i = 0; i < 20; i++) {
        expect(dice1.rollD6(), equals(dice2.rollD6()));
      }
    });
  });

  // ===========================================================================
  // DeckManager Tests
  // ===========================================================================
  group('DeckManager', () {
    test('draw returns cards and depletes draw pile', () {
      final deck = DeckManager<int>(cards: [1, 2, 3], random: Random(0));
      expect(deck.drawPileSize, 3);

      final c1 = deck.draw();
      expect(c1, isNotNull);
      expect(deck.drawPileSize, 2);

      deck.draw();
      deck.draw();
      expect(deck.drawPileSize, 0);
    });

    test('draw reshuffles discards when draw pile empty', () {
      final deck = DeckManager<int>(cards: [1, 2], random: Random(0));
      final c1 = deck.draw()!;
      final c2 = deck.draw()!;
      expect(deck.drawPileSize, 0);

      deck.discard(c1);
      deck.discard(c2);
      expect(deck.discardPileSize, 2);

      // Next draw should reshuffle
      final c3 = deck.draw();
      expect(c3, isNotNull);
      expect(deck.drawPileSize, 1);
      expect(deck.discardPileSize, 0);
    });

    test('draw returns null when fully exhausted', () {
      final deck = DeckManager<int>(cards: [1], random: Random(0));
      deck.draw();
      // Don't discard — card is gone
      expect(deck.draw(), isNull);
    });

    test('destroy moves card to destroyed pile', () {
      final deck = DeckManager<int>(cards: [1, 2, 3], random: Random(0));
      final card = deck.draw()!;
      deck.destroy(card);
      expect(deck.destroyedPileSize, 1);
      expect(deck.destroyedCards, contains(card));
    });

    test('isExhausted is true only when draw+discard are empty', () {
      final deck = DeckManager<int>(cards: [1], random: Random(0));
      expect(deck.isExhausted, isFalse);

      final card = deck.draw()!;
      expect(deck.isExhausted, isTrue); // draw empty, discard empty

      deck.discard(card);
      expect(deck.isExhausted, isFalse); // discard has 1
    });
  });

  // ===========================================================================
  // CombatResolution Tests
  // ===========================================================================
  group('CombatResolution - Attack CRT', () {
    test('LOW/StandOff never hits (DRM 1-6)', () {
      for (int drm = 1; drm <= 6; drm++) {
        final result = CombatResolution.resolveAttack(
          mode: AttackMode.standOff,
          altitude: Altitude.low,
          rawDrm: drm,
        );
        expect(result.isHit, isFalse, reason: 'DRM=$drm should miss');
        expect(result.fuelCost, 1);
      }
    });

    test('MEDIUM/StandOff DRM=6 hits', () {
      final result = CombatResolution.resolveAttack(
        mode: AttackMode.standOff,
        altitude: Altitude.medium,
        rawDrm: 6,
      );
      expect(result.isHit, isTrue);
      expect(result.fuelCost, 1);
    });

    test('MEDIUM/StandOff DRM=5 misses', () {
      final result = CombatResolution.resolveAttack(
        mode: AttackMode.standOff,
        altitude: Altitude.medium,
        rawDrm: 5,
      );
      expect(result.isHit, isFalse);
    });

    test('HIGH/CloseIn DRM=4 hits', () {
      final result = CombatResolution.resolveAttack(
        mode: AttackMode.closeIn,
        altitude: Altitude.high,
        rawDrm: 4,
      );
      expect(result.isHit, isTrue);
      expect(result.fuelCost, 2);
    });

    test('MEDIUM/FoLaze DRM=3 hits', () {
      final result = CombatResolution.resolveAttack(
        mode: AttackMode.foLaze,
        altitude: Altitude.medium,
        rawDrm: 3,
      );
      expect(result.isHit, isTrue);
      expect(result.fuelCost, 3);
    });

    test('sensor damage shifts column right (increases effective DRM)', () {
      // StandOff/MEDIUM normally needs DRM=6 to hit
      // With 2 sensor damage → +1 right shift → DRM 5 becomes DRM 6
      final result = CombatResolution.resolveAttack(
        mode: AttackMode.standOff,
        altitude: Altitude.medium,
        rawDrm: 5,
        sensorDamage: 2,
      );
      expect(result.isHit, isTrue);
    });
  });

  group('CombatResolution - Counterfire CRT', () {
    test('MEDIUM/StandOff DRM=5 → 1D+1F', () {
      final result = CombatResolution.resolveCounterfire(
        mode: AttackMode.standOff,
        altitude: Altitude.medium,
        rawDrm: 5,
      );
      expect(result.damage, 1);
      expect(result.fuelCost, 1);
    });

    test('HIGH/CloseIn DRM=4 → 1D+1F', () {
      final result = CombatResolution.resolveCounterfire(
        mode: AttackMode.closeIn,
        altitude: Altitude.high,
        rawDrm: 4,
      );
      expect(result.damage, 1);
      expect(result.fuelCost, 1);
    });

    test('LOW/StandOff all safe', () {
      for (int drm = 1; drm <= 6; drm++) {
        final result = CombatResolution.resolveCounterfire(
          mode: AttackMode.standOff,
          altitude: Altitude.low,
          rawDrm: drm,
        );
        expect(result.damage, 0, reason: 'DRM=$drm should be safe');
      }
    });

    test('VIS shifts column left (increases risk by dropping column)', () {
      // MEDIUM/StandOff DRM=6 normally → safe
      // With 2 VIS → shift 1 left → DRM 6 becomes DRM 5 (1D+1F)
      final result = CombatResolution.resolveCounterfire(
        mode: AttackMode.standOff,
        altitude: Altitude.medium,
        rawDrm: 6,
        vis: 2,
      );
      expect(result.damage, 1);
      expect(result.fuelCost, 1);
    });
  });

  group('CombatResolution - COMMS Check', () {
    test('DRM ≤ 2 → all OK (0)', () {
      expect(CombatResolution.resolveCommsCheck(1), 0);
      expect(CombatResolution.resolveCommsCheck(2), 0);
    });

    test('DRM 3-5 → controllable with difficulty (1)', () {
      expect(CombatResolution.resolveCommsCheck(3), 1);
      expect(CombatResolution.resolveCommsCheck(5), 1);
    });

    test('DRM ≥ 6 → destroyed (2)', () {
      expect(CombatResolution.resolveCommsCheck(6), 2);
      expect(CombatResolution.resolveCommsCheck(10), 2);
    });
  });

  // ===========================================================================
  // DamageSystem Tests
  // ===========================================================================
  group('DamageSystem', () {
    DroneState makeState({int maxIntegrity = 10}) {
      return DroneState(
        fuel: 24,
        maxFuel: 24,
        maxIntegrity: maxIntegrity,
        altitude: Altitude.medium,
        allowedAltitudes: [Altitude.low, Altitude.medium, Altitude.high],
        loadout: [],
        hasAesa: false,
        hasSatcom: false,
        hasCommsRedundancy: false,
        hasAutonomousAi: false,
        hasBuiltinFoLaze: true,
      );
    }

    test('1D damage adds 1 structural damage', () {
      final state = makeState();
      final report = DamageSystem.applyDamage(state, 1);
      expect(report.structuralAdded, 1);
      expect(state.structuralDamage, 1);
    });

    test('2 structural damage → 1 sensor damage', () {
      final state = makeState();
      DamageSystem.applyDamage(state, 2);
      expect(state.sensorsDamage, 1);
    });

    test('3 structural damage → 1 comms damage', () {
      final state = makeState();
      DamageSystem.applyDamage(state, 3);
      expect(state.commsDamage, 1);
    });

    test('sensor + comms damage cascades to VIS', () {
      final state = makeState();
      // 6 structural → 3 sensors + 2 comms = 5 VIS
      DamageSystem.applyDamage(state, 6);
      expect(state.sensorsDamage, 3);
      expect(state.commsDamage, 2);
      expect(state.vis, 5);
    });

    test('sensor damage capped at 9', () {
      final state = makeState(maxIntegrity: 100);
      DamageSystem.applyDamage(state, 20);
      expect(state.sensorsDamage, 9); // 20/2=10 but capped at 9
    });

    test('destruction when damage ≥ maxIntegrity', () {
      final state = makeState(maxIntegrity: 5);
      final report = DamageSystem.applyDamage(state, 5);
      expect(report.isDestroyed, isTrue);
      expect(state.isDestroyed, isTrue);
    });

    test('no damage returns safe report', () {
      final state = makeState();
      final report = DamageSystem.applyDamage(state, 0);
      expect(report.structuralAdded, 0);
      expect(report.isDestroyed, isFalse);
    });
  });

  // ===========================================================================
  // Target Acquisition Tests
  // ===========================================================================
  group('TargetAcquisition', () {
    test('roll 10 + DRM 0 → TRUCK (range ≤18)', () {
      final result = lookupTargetType(roll: 10, drm: 0);
      expect(result, 'TRUCK');
    });

    test('roll 25 + DRM 0 → PERSONNEL (range 19-35)', () {
      final result = lookupTargetType(roll: 25, drm: 0);
      expect(result, 'PERSONNEL');
    });

    test('roll 50 + DRM 0 → SAM (range 46-55)', () {
      final result = lookupTargetType(roll: 50, drm: 0);
      expect(result, 'SAM');
    });

    test('roll 95 + DRM 0 → VIP (range 92-99)', () {
      final result = lookupTargetType(roll: 95, drm: 0);
      expect(result, 'VIP');
    });

    test('DRM shifts result: roll 10 + DRM 10 → PERSONNEL', () {
      // 10 + 10 = 20, which is PERSONNEL range
      final result = lookupTargetType(roll: 10, drm: 10);
      expect(result, 'PERSONNEL');
    });

    test('fallback when type unavailable → lower first', () {
      // Roll 50 → SAM, but SAM not available
      final result = lookupTargetType(
        roll: 50,
        drm: 0,
        availableTypes: {'TRUCK', 'AFV', 'TANK'},
      );
      expect(result, 'AFV'); // Lower than SAM
    });

    test('roll ≥ 100 → AIR', () {
      final result = lookupTargetType(roll: 90, drm: 20);
      expect(result, 'AIR');
    });
  });

  // ===========================================================================
  // Threat Determination Tests
  // ===========================================================================
  group('ThreatDetermination', () {
    test('roll 10 → SMALL ARMS (range ≤19)', () {
      final result = lookupThreatType(roll: 10, drm: 0);
      expect(result, 'SMALL ARMS');
    });

    test('roll 50 → AAA (range 20-65)', () {
      final result = lookupThreatType(roll: 50, drm: 0);
      expect(result, 'AAA');
    });

    test('roll 70 → SAM (range 66-85)', () {
      final result = lookupThreatType(roll: 70, drm: 0);
      expect(result, 'SAM');
    });

    test('roll 90 → CAP (range 86-95)', () {
      final result = lookupThreatType(roll: 90, drm: 0);
      expect(result, 'CAP');
    });

    test('roll ≥ 96 → DRONE GUN', () {
      final result = lookupThreatType(roll: 96, drm: 0);
      expect(result, 'DRONE GUN');
    });
  });

  // ===========================================================================
  // Scoring Tests
  // ===========================================================================
  group('ScoringService', () {
    test('calculates VP sum from destroyed targets', () {
      final targets = [
        _makeTargetCard('TC1', 1.0),
        _makeTargetCard('TC2', 2.5),
        _makeTargetCard('TC3', 0.5),
      ];
      final score = ScoringService.calculateScore(targets);
      expect(score, 4.0);
    });

    test('final score subtracts drone VP', () {
      final targets = [_makeTargetCard('TC1', 5.0)];
      final score = ScoringService.calculateFinalScore(targets, droneVp: 2.0);
      expect(score, 3.0);
    });

    test('empty targets = 0 VP', () {
      expect(ScoringService.calculateScore([]), 0.0);
    });
  });

  // ===========================================================================
  // DroneState Tests
  // ===========================================================================
  group('DroneState', () {
    test('fuelFraction reports correct ratio', () {
      final state = _makeDroneState(fuel: 12, maxFuel: 24);
      expect(state.fuelFraction, 0.5);
    });

    test('spendFuel returns false if insufficient', () {
      final state = _makeDroneState(fuel: 2, maxFuel: 24);
      expect(state.spendFuel(3), isFalse);
      expect(state.fuel, 2); // unchanged
    });

    test('changeAltitude costs fuel when raising and updates altitude', () {
      final state = _makeDroneState(fuel: 10, maxFuel: 24);
      state.altitude = Altitude.low;
      final cost = state.changeAltitude(Altitude.high);
      expect(cost, 4); // low → high = 2 levels × 2F = 4F (PRD §4.2)
      expect(state.altitude, Altitude.high);
      expect(state.fuel, 6);
    });

    test('changeAltitude returns -1 for disallowed altitude', () {
      final state = DroneState(
        fuel: 10,
        maxFuel: 24,
        maxIntegrity: 10,
        altitude: Altitude.low,
        allowedAltitudes: [Altitude.low, Altitude.medium],
        loadout: [],
        hasAesa: false,
        hasSatcom: false,
        hasCommsRedundancy: false,
        hasAutonomousAi: false,
        hasBuiltinFoLaze: true,
      );
      expect(state.changeAltitude(Altitude.high), -1);
    });

    test('target acquisition DRM includes AESA bonus', () {
      final state = DroneState(
        fuel: 24,
        maxFuel: 24,
        maxIntegrity: 10,
        altitude: Altitude.medium,
        allowedAltitudes: Altitude.values.toList(),
        loadout: [],
        hasAesa: true,
        hasSatcom: false,
        hasCommsRedundancy: false,
        hasAutonomousAi: false,
        hasBuiltinFoLaze: true,
      );
      // AESA: +10, COMMS 0: +10 = 20
      expect(state.targetAcquisitionDrm, 20);
    });
  });

  // ===========================================================================
  // CombatCardHandler Tests
  // ===========================================================================
  group('CombatCardHandler', () {
    test('no-event card returns noEvent effect', () {
      final card = CombatCard(
        cardNumber: 'CC099',
        cardType: 'Combat Card',
        cardName: 'NO EVENT',
        instruction: 'No event occurs.',
      );
      final state = _makeDroneState();
      final effect = CombatCardHandler.apply(card, state);
      expect(effect.type, CombatCardEffectType.noEvent);
    });

    test('CC002 adds +2 COMMS damage', () {
      final card = CombatCard(
        cardNumber: 'CC002',
        cardType: 'Combat Card',
        cardName: 'COMMS PROBLEM',
        instruction: 'COMMs receive +2 Damage',
      );
      final state = _makeDroneState();
      final effect = CombatCardHandler.apply(card, state);
      expect(effect.type, CombatCardEffectType.commsDamage);
      expect(state.permanentCommsDamage, 2);
    });

    test('CC003 adds +1 sensor damage', () {
      final card = CombatCard(
        cardNumber: 'CC003',
        cardType: 'Combat Card',
        cardName: 'JAMMED!',
        instruction: 'Sensors +1 damage permanent.',
      );
      final state = _makeDroneState();
      CombatCardHandler.apply(card, state);
      expect(state.permanentSensorDamage, 1);
    });
  });

  // ===========================================================================
  // GameEngine Integration Test
  // ===========================================================================
  group('GameEngine - Full Cycle', () {
    test('completes B0→B1→B2→B3→B4→B5 with deterministic dice', () {
      // Build a minimal game setup
      final weapon = Weapon(
        id: 1,
        name: 'TEST-MISSILE',
        weaponType: WeaponType.atgm,
        fireAltitudes: [Altitude.low, Altitude.medium, Altitude.high],
        drmByTargetType: {for (final t in TargetType.values) t: 2},
      );

      final targetCard = _makeTargetCard('TEST_TARGET', 3.0);
      final threatCard = ThreatCard(
        cardNumber: 'TH001',
        cardType: 'Threat Card',
        subCategory: 'AAA',
        threatType: ThreatType.aaa,
        cardName: 'TEST-AAA',
      );
      final combatCard = CombatCard(
        cardNumber: 'CC099',
        cardType: 'Combat Card',
        cardName: 'NO EVENT',
        instruction: 'No event.',
      );

      final setup = GameSetup(
        drone: Drone(
          id: 1,
          name: 'TEST-DRONE',
          country: 'Test',
          category: 'Test',
          droneClass: DroneClass.b,
          allowedAltitudes: [Altitude.low, Altitude.medium, Altitude.high],
          maxStructuralIntegrity: 10,
          hasBuiltinFoLaze: true,
          hasAesa: true,
          hasSatcom: false,
          hasCommsRedundancy: false,
          hasAutonomousAi: false,
          loadoutOptions: [],
        ),
        droneState: DroneState(
          fuel: 20,
          maxFuel: 20,
          maxIntegrity: 10,
          altitude: Altitude.high,
          allowedAltitudes: [Altitude.low, Altitude.medium, Altitude.high],
          loadout: [LoadoutSlot(weapon: weapon, quantity: 5)],
          hasAesa: true,
          hasSatcom: false,
          hasCommsRedundancy: false,
          hasAutonomousAi: false,
          hasBuiltinFoLaze: true,
        ),
        combatDeck: DeckManager<CombatCard>(
          cards: [combatCard],
          random: Random(0),
        ),
        targetDecks: {
          'TRUCK': DeckManager<TargetCard>(
            cards: [targetCard],
            random: Random(0),
          ),
        },
        threatDecks: {
          'AAA': DeckManager<ThreatCard>(
            cards: [threatCard],
            random: Random(0),
          ),
        },
        weaponMap: {'TEST-MISSILE': weapon},
        targetRanges: [],
        threatRanges: [],
        scoringMode: ScoringMode.maximumKill,
      );

      final engine = GameEngine(
        setup: setup,
        diceService: DiceService(random: Random(42)),
      );

      // Phase transitions
      expect(engine.state.phase, GamePhase.setup);

      // Start game
      engine.startGame();
      expect(engine.state.phase, GamePhase.b0InTransit);

      // B0 → B1
      engine.processB0();
      expect(engine.state.phase, GamePhase.b1Search);

      // B1: draw combat card
      engine.drawCombatCard();
      engine.executeCombatCard();

      // B1 → B2
      engine.advanceFromB1();
      expect(engine.state.phase, GamePhase.b2TargetAcq);

      // B2: acquire target and threat
      engine.rollTargetAcquisition();
      engine.rollThreatDetermination();

      // B2 decision: engage
      engine.decideEngage();
      expect(engine.state.phase, GamePhase.b3Positioning);

      // B3: draw combat card
      engine.drawCombatCard();
      engine.executeCombatCard();

      // B3 → B4
      engine.advanceFromB3();
      expect(engine.state.phase, GamePhase.b4Attack);

      // B4: select attack and execute
      engine.selectAttack(mode: AttackMode.standOff, weapon: weapon);
      engine.executeAttack();
      // Phase should now be B5

      if (!engine.state.isGameOver) {
        expect(engine.state.phase, GamePhase.b5Evasion);

        // B5: execute evasion
        engine.executeEvasion();

        if (!engine.state.isGameOver) {
          // B5 decision: continue
          engine.decideContinue();
          expect(engine.state.phase, GamePhase.b0InTransit);
          expect(engine.state.cycleNumber, 2);
        }
      }

      // Verify game log has entries
      expect(engine.state.gameLog, isNotEmpty);
    });
  });

  // ===========================================================================
  // Enums Tests
  // ===========================================================================
  group('Enums', () {
    test('Altitude.parseFromDb parses comma-separated string', () {
      final alts = Altitude.parseFromDb('LOW, MEDIUM, HIGH');
      expect(alts, [Altitude.low, Altitude.medium, Altitude.high]);
    });

    test('Altitude.parseFromDb handles VLOW', () {
      final alts = Altitude.parseFromDb('VLOW, LOW');
      expect(alts, [Altitude.vlow, Altitude.low]);
    });

    test('TargetType.fromDb parses database value', () {
      expect(TargetType.fromDb('AFV'), TargetType.afv);
      expect(TargetType.fromDb('HQ-BUNKER'), TargetType.hqBunker);
    });

    test('ThreatType.fromDb parses database value', () {
      expect(ThreatType.fromDb('SMALL ARMS'), ThreatType.smallArms);
      expect(ThreatType.fromDb('DRONE GUN'), ThreatType.droneGun);
    });

    test('Altitude.fuelCostTo calculates PRD costs (2F up, 1F down)', () {
      expect(Altitude.low.fuelCostTo(Altitude.high), 4); // 2 levels × 2F
      expect(Altitude.medium.fuelCostTo(Altitude.low), 1); // 1 level × 1F
      expect(Altitude.medium.fuelCostTo(Altitude.medium), 0);
    });
  });
}

// =============================================================================
// Helpers
// =============================================================================

TargetCard _makeTargetCard(String number, double vp) {
  return TargetCard(
    cardNumber: number,
    cardType: 'Target Card',
    subCategory: 'TRUCK',
    targetType: TargetType.truck,
    cardName: 'Test Target $number',
    vp: vp,
  );
}

DroneState _makeDroneState({int fuel = 24, int maxFuel = 24}) {
  return DroneState(
    fuel: fuel,
    maxFuel: maxFuel,
    maxIntegrity: 10,
    altitude: Altitude.medium,
    allowedAltitudes: [Altitude.low, Altitude.medium, Altitude.high],
    loadout: [],
    hasAesa: false,
    hasSatcom: false,
    hasCommsRedundancy: false,
    hasAutonomousAi: false,
    hasBuiltinFoLaze: true,
  );
}
