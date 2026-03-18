/// Height modifier values per altitude level for all 4 mechanics.
/// Per BA spec §8.3 — height affects hit probability, evasion probability,
/// damage multiplier, and fuel consumption rate simultaneously.
///
/// Values are placeholder defaults — the game designer can override them
/// by adding a `height_modifiers` table to the DB in a future sprint.
library;

import '../../utils/constants.dart';

class HeightModifiers {
  /// Additive DRM on hit probability (positive = better chance to hit).
  final int hitProbabilityDRM;

  /// Additive DRM on evasion probability (positive = better evasion).
  final int evasionDRM;

  /// Multiplicative modifier on incoming damage (1.0 = no change).
  final double damageMultiplier;

  /// Multiplicative modifier on base fuel consumption per cycle (1.0 = no change).
  final double fuelRateMultiplier;

  const HeightModifiers({
    required this.hitProbabilityDRM,
    required this.evasionDRM,
    required this.damageMultiplier,
    required this.fuelRateMultiplier,
  });

  /// Default modifier table per altitude.
  /// Very Low: worst evasion + most damage, cheap fuel (low altitude = short range)
  /// Low: moderate penalties.
  /// Medium: baseline (no modifiers).
  /// High: hard to hit targets, best evasion, more fuel burned.
  ///
  /// Note: enum values cannot be used as const map keys in Dart, so this is
  /// a static final (not const).
  static final Map<Altitude, HeightModifiers> defaults = {
    Altitude.vlow: const HeightModifiers(
      hitProbabilityDRM: 2,
      evasionDRM: -2,
      damageMultiplier: 1.5,
      fuelRateMultiplier: 0.75,
    ),
    Altitude.low: const HeightModifiers(
      hitProbabilityDRM: 1,
      evasionDRM: -1,
      damageMultiplier: 1.25,
      fuelRateMultiplier: 0.9,
    ),
    Altitude.medium: const HeightModifiers(
      hitProbabilityDRM: 0,
      evasionDRM: 0,
      damageMultiplier: 1.0,
      fuelRateMultiplier: 1.0,
    ),
    Altitude.high: const HeightModifiers(
      hitProbabilityDRM: -1,
      evasionDRM: 2,
      damageMultiplier: 0.75,
      fuelRateMultiplier: 1.25,
    ),
  };

  static HeightModifiers forAltitude(Altitude altitude) =>
      defaults[altitude] ?? defaults[Altitude.medium]!;
}
