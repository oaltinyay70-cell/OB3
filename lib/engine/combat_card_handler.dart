import '../models/combat_card.dart';
import '../models/game_enums.dart';
import 'drone_state.dart';

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
    this.altitudeSteps,
    this.forceAltitude,
  });

  final CombatCardEffectType type;
  final String description;

  /// Combat card attack mode restriction key (e.g. 'CLOSE_IN_ONLY').
  final String? attackModeRestriction;

  /// DRM applied to all attack rolls this turn (positive = bonus, negative = penalty).
  final int? drmModifier;

  /// Number of altitude levels to shift (±1, ±2). Applied after card resolution.
  /// Clamped to valid Altitude range by the caller.
  final int? altitudeSteps;

  /// Force drone to a specific altitude regardless of current level.
  final Altitude? forceAltitude;

  static const noEvent = CombatCardEffect(
    type: CombatCardEffectType.noEvent,
    description: 'No event — discard.',
  );
}

/// Interprets and applies combat card effects to the drone state.
///
/// All 31 merged combat cards (CC001–CC031) are handled explicitly.
/// Altitude effects are returned via [CombatCardEffect.altitudeSteps] /
/// [CombatCardEffect.forceAltitude] — the caller is responsible for applying
/// them to the active [DroneState].
class CombatCardHandler {
  CombatCardHandler._();

  /// Apply a combat card's effect.
  ///
  /// State-mutating effects (COMMS damage, VIS reset, etc.) are applied
  /// immediately. Altitude and DRM effects are returned for the caller to apply.
  static CombatCardEffect apply(CombatCard card, DroneState state) {
    if (card.isNoEvent) return CombatCardEffect.noEvent;

    switch (card.cardNumber) {
      // ── SET A: Original cards (CC001–CC012) ──────────────────────────────

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
          description: 'COMMS PROBLEM: COMMS +2 damage.',
        );

      case 'CC003': // JAMMED! — +1 sensor damage (permanent)
        state.permanentSensorDamage += 1;
        return const CombatCardEffect(
          type: CombatCardEffectType.sensorsDamage,
          description: 'JAMMED: Sensors +1 permanent damage.',
        );

      case 'CC004': // SKILLED OPERATOR — reset VIS to 0
        state.permanentVisMod = -state.vis;
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

      case 'CC006': // ENEMY CAP! — fly at LOW altitude for rest of mission
        return const CombatCardEffect(
          type: CombatCardEffectType.altitudeChange,
          description: 'ENEMY CAP: Forced to LOW altitude for rest of mission.',
          forceAltitude: Altitude.low,
        );

      case 'CC007': // LOCAL ASSET — reveal next 3 target cards
        return const CombatCardEffect(
          type: CombatCardEffectType.other,
          description: 'LOCAL ASSET: Reveal next 3 Target cards, pick one, shuffle rest back.',
        );

      case 'CC008': // RADIO D/F — +1 DRM vs HQ/BUNKER stand-off
        return const CombatCardEffect(
          type: CombatCardEffectType.drmModifier,
          description: 'RADIO D/F: +1 DRM if next target is HQ/BUNKER and attacking Stand-Off.',
          drmModifier: 1,
        );

      case 'CC009': // WALKING DEAD — return last eliminated target to deck
        return const CombatCardEffect(
          type: CombatCardEffectType.other,
          description: 'WALKING DEAD: Last eliminated Target Card returned to deck (shuffle).',
        );

      case 'CC010': // SMOKING ACES — -1 column shift on drone attack
        return const CombatCardEffect(
          type: CombatCardEffectType.drmModifier,
          description: 'SMOKING ACES: Next target shrouded by smoke — 1 Left Shift to attack.',
          drmModifier: -1,
        );

      case 'CC011': // INTRUDER'S FLIGHT — skip next counterfire
        return const CombatCardEffect(
          type: CombatCardEffectType.other,
          description: "INTRUDER'S FLIGHT: Skip next counterfire procedure this turn.",
        );

      case 'CC012': // RADIO CHATTER — +1 Left Shift vs CAP/SAM counterfire
        return const CombatCardEffect(
          type: CombatCardEffectType.other,
          description: 'RADIO CHATTER: +1 Left Shift to counterfire if THREAT is CAP or SAM.',
        );

      // ── SET B: New cards — DRM effects (CC013–CC023) ────────────────────

      case 'CC013': // AGGRESSIVE STRIKE PROFILE — Attack DRM +2
        return const CombatCardEffect(
          type: CombatCardEffectType.drmModifier,
          description: 'AGGRESSIVE STRIKE PROFILE: Attack DRM +2 this turn.',
          drmModifier: 2,
        );

      case 'CC014': // WHITEOUT — Attack DRM -2
        return const CombatCardEffect(
          type: CombatCardEffectType.drmModifier,
          description: 'WHITEOUT: Attack DRM -2 this turn.',
          drmModifier: -2,
        );

      case 'CC015': // TAILWIND — Attack DRM +1
        return const CombatCardEffect(
          type: CombatCardEffectType.drmModifier,
          description: 'TAILWIND: Attack DRM +1 this turn.',
          drmModifier: 1,
        );

      case 'CC016': // STATIC — Attack DRM -1
        return const CombatCardEffect(
          type: CombatCardEffectType.drmModifier,
          description: 'STATIC: Attack DRM -1 this turn.',
          drmModifier: -1,
        );

      case 'CC017': // LOST SIGNAL — Attack DRM -2
        return const CombatCardEffect(
          type: CombatCardEffectType.drmModifier,
          description: 'LOST SIGNAL: Attack DRM -2 this turn.',
          drmModifier: -2,
        );

      case 'CC018': // CLEAR SKIES — Attack DRM +2
        return const CombatCardEffect(
          type: CombatCardEffectType.drmModifier,
          description: 'CLEAR SKIES: Attack DRM +2 this turn.',
          drmModifier: 2,
        );

      case 'CC019': // GROUND HUGGING — +1 DRM at VLOW/LOW only
        final atLowAlt = state.altitude == Altitude.vlow || state.altitude == Altitude.low;
        return CombatCardEffect(
          type: CombatCardEffectType.drmModifier,
          description: atLowAlt
              ? 'GROUND HUGGING: Attack DRM +1 (low altitude bonus active).'
              : 'GROUND HUGGING: No effect (altitude too high).',
          drmModifier: atLowAlt ? 1 : 0,
        );

      case 'CC020': // UPDRAFT — Attack DRM -1
        return const CombatCardEffect(
          type: CombatCardEffectType.drmModifier,
          description: 'UPDRAFT: Attack DRM -1 this turn.',
          drmModifier: -1,
        );

      case 'CC021': // GHOST SIGNAL — Attack DRM -1 (FO/Laze unaffected)
        return const CombatCardEffect(
          type: CombatCardEffectType.drmModifier,
          description: 'GHOST SIGNAL: Attack DRM -1 this turn. FO/Laze mode unaffected.',
          drmModifier: -1,
        );

      case 'CC022': // BURST TRANSMISSION — Attack DRM +1
        return const CombatCardEffect(
          type: CombatCardEffectType.drmModifier,
          description: 'BURST TRANSMISSION: Attack DRM +1 this turn.',
          drmModifier: 1,
        );

      case 'CC023': // FOG OF WAR — Attack DRM -2
        return const CombatCardEffect(
          type: CombatCardEffectType.drmModifier,
          description: 'FOG OF WAR: Attack DRM -2 this turn.',
          drmModifier: -2,
        );

      // ── SET B: Altitude effect cards (CC024–CC030) ───────────────────────

      case 'CC024': // THERMAL SPIKE — altitude +1
        return const CombatCardEffect(
          type: CombatCardEffectType.altitudeChange,
          description: 'THERMAL SPIKE: Altitude +1 level.',
          altitudeSteps: 1,
        );

      case 'CC025': // DIVE DIVE DIVE — altitude -1
        return const CombatCardEffect(
          type: CombatCardEffectType.altitudeChange,
          description: 'DIVE DIVE DIVE: Altitude -1 level.',
          altitudeSteps: -1,
        );

      case 'CC026': // DEAD DROP — altitude -1
        return const CombatCardEffect(
          type: CombatCardEffectType.altitudeChange,
          description: 'DEAD DROP: Altitude -1 level.',
          altitudeSteps: -1,
        );

      case 'CC027': // STRATOSPHERIC — altitude +2
        return const CombatCardEffect(
          type: CombatCardEffectType.altitudeChange,
          description: 'STRATOSPHERIC: Altitude +2 levels.',
          altitudeSteps: 2,
        );

      case 'CC028': // NOSEDIVE — altitude -2
        return const CombatCardEffect(
          type: CombatCardEffectType.altitudeChange,
          description: 'NOSEDIVE: Altitude -2 levels.',
          altitudeSteps: -2,
        );

      case 'CC029': // DECK LEVEL — forced to VLOW
        return const CombatCardEffect(
          type: CombatCardEffectType.altitudeChange,
          description: 'DECK LEVEL: Altitude forced to VERY LOW.',
          forceAltitude: Altitude.vlow,
        );

      case 'CC030': // TOP GUN — forced to HIGH
        return const CombatCardEffect(
          type: CombatCardEffectType.altitudeChange,
          description: 'TOP GUN: Altitude forced to HIGH.',
          forceAltitude: Altitude.high,
        );

      // CC031 — NO EVENT is caught by card.isNoEvent guard above.

      default:
        return CombatCardEffect(
          type: CombatCardEffectType.other,
          description: '${card.cardName}: ${card.instructions}',
        );
    }
  }

  /// Apply an altitude effect from a combat card to [DroneState].
  ///
  /// Call this after [apply()] if the returned effect has [altitudeSteps]
  /// or [forceAltitude] set.
  static void applyAltitudeEffect(CombatCardEffect effect, DroneState state) {
    if (effect.forceAltitude != null) {
      state.altitude = effect.forceAltitude!;
      return;
    }
    if (effect.altitudeSteps != null && effect.altitudeSteps != 0) {
      const values = Altitude.values;
      final currentIndex = values.indexOf(state.altitude);
      final newIndex = (currentIndex + effect.altitudeSteps!).clamp(0, values.length - 1);
      state.altitude = values[newIndex];
    }
  }
}
