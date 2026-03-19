import 'drone_state.dart';
import '../models/combat_card.dart';

/// Identifies the type of effect a combat card has.
enum CombatCardEffectType {
  noEvent,
  attackModeRestriction,
  commsDamage,
  sensorsDamage,
  visReset,
  commsRepair,
  drmModifier,
  fuelCost,
  altitudeChange,
  other,
}

/// Result of applying a combat card.
class CombatCardEffect {
  const CombatCardEffect({
    required this.type,
    required this.description,
    this.attackModeRestriction,
    this.drmModifier,
  });

  final CombatCardEffectType type;
  final String description;
  final String? attackModeRestriction;
  final int? drmModifier;

  static const noEvent = CombatCardEffect(
    type: CombatCardEffectType.noEvent,
    description: 'No event — discard.',
  );
}

/// Interprets and applies combat card effects to the drone state.
///
/// Each of the 31 merged combat cards has a specific effect parsed from the
/// instructions text. This handler maps card numbers to their game effects.
class CombatCardHandler {
  CombatCardHandler._();

  /// Apply a combat card's effect to the drone state.
  ///
  /// Returns a description of what happened for the game log.
  static CombatCardEffect apply(CombatCard card, DroneState state) {
    if (card.isNoEvent) return CombatCardEffect.noEvent;

    // Match by card number for deterministic behavior
    switch (card.cardNumber) {
      case 'CC001': // WORLD IS WATCHING — close-in only until next B0
        return const CombatCardEffect(
          type: CombatCardEffectType.attackModeRestriction,
          description: 'WORLD IS WATCHING: Close-in attacks only until next B0.',
          attackModeRestriction: 'CLOSE_IN_ONLY',
        );

      case 'CC002': // COMMS PROBLEM — +2 COMMS damage
        state.permanentCommsDamage += 2;
        return const CombatCardEffect(
          type: CombatCardEffectType.commsDamage,
          description: 'COMMS PROBLEM: COMMS receive +2 damage.',
        );

      case 'CC003': // JAMMED! — +1 sensor damage (permanent)
        state.permanentSensorDamage += 1;
        return const CombatCardEffect(
          type: CombatCardEffectType.sensorsDamage,
          description: 'JAMMED: Sensors receive +1 permanent damage.',
        );

      case 'CC004': // SKILLED OPERATOR — reset VIS to 0
        state.permanentVisMod = -state.vis; // offset to make final vis = 0
        return const CombatCardEffect(
          type: CombatCardEffectType.visReset,
          description: 'SKILLED OPERATOR: VIS/RCS reset to 0.',
        );

      case 'CC005': // IONIZING LAYER — clear COMMS damage
        state.permanentCommsDamage = -state.commsDamage;
        return const CombatCardEffect(
          type: CombatCardEffectType.commsRepair,
          description: 'IONIZING LAYER: All COMMS damage cleared.',
        );

      default:
        // For any combat card not explicitly handled, parse instruction text
        return _parseInstruction(card, state);
    }
  }

  /// Fallback: try to parse common instruction patterns.
  static CombatCardEffect _parseInstruction(
      CombatCard card, DroneState state) {
    final text = card.instructions.toUpperCase();

    if (text.contains('NO EVENT') || text.contains('NOTHING HAPPENS')) {
      return CombatCardEffect.noEvent;
    }

    if (text.contains('COMMS') && text.contains('DAMAGE')) {
      // Extract damage amount if present
      final match = RegExp(r'\+(\d+)\s*DAMAGE').firstMatch(text);
      final amount = match != null ? int.parse(match.group(1)!) : 1;
      state.permanentCommsDamage += amount;
      return CombatCardEffect(
        type: CombatCardEffectType.commsDamage,
        description: '${card.cardName}: COMMS +$amount damage.',
      );
    }

    if (text.contains('SENSOR') && text.contains('DAMAGE')) {
      final match = RegExp(r'\+(\d+)\s*DAMAGE').firstMatch(text);
      final amount = match != null ? int.parse(match.group(1)!) : 1;
      state.permanentSensorDamage += amount;
      return CombatCardEffect(
        type: CombatCardEffectType.sensorsDamage,
        description: '${card.cardName}: Sensors +$amount damage.',
      );
    }

    if (text.contains('VIS') && text.contains('0')) {
      state.permanentVisMod = -state.vis;
      return CombatCardEffect(
        type: CombatCardEffectType.visReset,
        description: '${card.cardName}: VIS/RCS reset.',
      );
    }

    // Unrecognized — treat as informational
    return CombatCardEffect(
      type: CombatCardEffectType.other,
      description: '${card.cardName}: ${card.instructions}',
    );
  }
}
