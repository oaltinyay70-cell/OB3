import '../models/scenario.dart';

/// Default Threat Determination Table from the rulebook (§6.4.2.2).
const List<ProbabilityRange> defaultThreatRanges = [
  ProbabilityRange(typeName: 'SMALL ARMS',       rangeMin: 0,  rangeMax: 19),
  ProbabilityRange(typeName: 'AAA',              rangeMin: 20, rangeMax: 65),
  ProbabilityRange(typeName: 'SAM',              rangeMin: 66, rangeMax: 85),
  ProbabilityRange(typeName: 'CAP',              rangeMin: 86, rangeMax: 95),
  ProbabilityRange(typeName: 'DRONE GUN',        rangeMin: 96, rangeMax: 999),
];

/// Looks up which threat type corresponds to a 2D10 roll + DRM.
///
/// [roll] - raw 2D10 value (0-99).
/// [drm] - DRM modifiers to add (VIS-based).
/// [customRanges] - scenario-specific ranges (if null, uses default).
/// [availableTypes] - set of threat types that still have cards in the deck.
///
/// Returns the threat type name (DB sub_category), or null if no match.
String? lookupThreatType({
  required int roll,
  required int drm,
  List<ProbabilityRange>? customRanges,
  Set<String>? availableTypes,
}) {
  final finalRoll = roll + drm;
  final ranges = customRanges ?? defaultThreatRanges;

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

  // Roll above max range → last type
  if (finalRoll >= 96) {
    if (ranges.any((r) => r.typeName == 'DRONE GUN') &&
        (availableTypes == null || availableTypes.contains('DRONE GUN'))) {
      return 'DRONE GUN';
    }
  }

  return null;
}

/// Fallback: find nearest available type (lower first, then higher).
String? _fallback(
  List<ProbabilityRange> ranges,
  ProbabilityRange matched,
  Set<String> availableTypes,
) {
  final matchedIndex = ranges.indexOf(matched);

  for (int i = matchedIndex - 1; i >= 0; i--) {
    if (!ranges[i].isNa && availableTypes.contains(ranges[i].typeName)) {
      return ranges[i].typeName;
    }
  }

  for (int i = matchedIndex + 1; i < ranges.length; i++) {
    if (!ranges[i].isNa && availableTypes.contains(ranges[i].typeName)) {
      return ranges[i].typeName;
    }
  }

  return null;
}
