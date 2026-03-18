
import '../models/scenario.dart';

/// Default Target Acquisition Table from the rulebook (§6.4.2.1).
///
/// Maps 2D10 roll ranges to target types.
/// Scenarios may override these with custom ranges.
const List<ProbabilityRange> defaultTargetRanges = [
  ProbabilityRange(typeName: 'TRUCK',      rangeMin: 0,   rangeMax: 18),
  ProbabilityRange(typeName: 'PERSONNEL',  rangeMin: 19,  rangeMax: 35),
  ProbabilityRange(typeName: 'AFV',        rangeMin: 36,  rangeMax: 45),
  ProbabilityRange(typeName: 'SAM',        rangeMin: 46,  rangeMax: 55),
  ProbabilityRange(typeName: 'TANK',       rangeMin: 56,  rangeMax: 70),
  ProbabilityRange(typeName: 'ARTILLERY',  rangeMin: 71,  rangeMax: 79),
  ProbabilityRange(typeName: 'HQ-BUNKER',  rangeMin: 80,  rangeMax: 91),
  ProbabilityRange(typeName: 'VIP',        rangeMin: 92,  rangeMax: 99),
  ProbabilityRange(typeName: 'AIR',        rangeMin: 100, rangeMax: 999),
];

/// Looks up which target type corresponds to a 2D10 roll + DRM.
///
/// [roll] - raw 2D10 value (0-99).
/// [drm] - DRM modifiers to add (AESA, COMMS bonuses/penalties).
/// [customRanges] - scenario-specific ranges (if null, uses default).
/// [availableTypes] - set of target types that still have cards in the deck.
///
/// Returns the target type name (DB sub_category), or null if no match.
String? lookupTargetType({
  required int roll,
  required int drm,
  List<ProbabilityRange>? customRanges,
  Set<String>? availableTypes,
}) {
  final finalRoll = roll + drm;
  final ranges = customRanges ?? defaultTargetRanges;

  // Direct match
  for (final range in ranges) {
    if (range.contains(finalRoll)) {
      if (availableTypes == null || availableTypes.contains(range.typeName)) {
        return range.typeName;
      }
      // Type matched but unavailable — use fallback
      return _fallback(ranges, range, availableTypes);
    }
  }

  // If roll exceeds all ranges (e.g., ≥100), check for AIR type
  if (finalRoll >= 100) {
    if (ranges.any((r) => r.typeName == 'AIR') &&
        (availableTypes == null || availableTypes.contains('AIR'))) {
      return 'AIR';
    }
  }

  return null;
}

/// Fallback: find the next available type by looking lower first, then higher.
String? _fallback(
  List<ProbabilityRange> ranges,
  ProbabilityRange matched,
  Set<String> availableTypes,
) {
  final matchedIndex = ranges.indexOf(matched);

  // Search LOWER ranges first
  for (int i = matchedIndex - 1; i >= 0; i--) {
    if (!ranges[i].isNa && availableTypes.contains(ranges[i].typeName)) {
      return ranges[i].typeName;
    }
  }

  // Then search HIGHER ranges
  for (int i = matchedIndex + 1; i < ranges.length; i++) {
    if (!ranges[i].isNa && availableTypes.contains(ranges[i].typeName)) {
      return ranges[i].typeName;
    }
  }

  return null; // All types exhausted
}
