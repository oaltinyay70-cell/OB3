import '../models/target_card.dart';
import 'game_state.dart';
/// Describes one objective condition from the scenario editor.
///
/// Supports three match types:
///   1. **Specific card** — e.g. `CULT LEADER` (exact card_name match)
///   2. **Category wildcard** — e.g. `ANY TANK` (matches any card whose
///      sub_category equals "TANK")
///   3. **ALL TARGETS** — all target card decks must be empty
///
/// [weaponRequired] narrows kills to those made with a specific weapon type.
class ObjectiveCondition {
  const ObjectiveCondition({
    required this.cardNameOrCategory,
    this.requiredQty = 1,
    this.weaponRequired,
    this.description,
  });

  /// Target card name (e.g. "CULT LEADER") or category wildcard
  /// (e.g. "ANY TANK", "ANY SAM", "ALL TARGETS", "NONE").
  final String cardNameOrCategory;

  /// How many kills of this type are required.
  final int requiredQty;

  /// If set, kills only count when made with this weapon type.
  final String? weaponRequired;

  /// Human-readable description (from editor's objective text field).
  final String? description;

  /// Whether this condition is actually set (not NONE / empty).
  bool get isActive =>
      cardNameOrCategory.isNotEmpty &&
      cardNameOrCategory.toUpperCase() != 'NONE';
}

/// Tracks live progress toward an objective condition.
class ObjectiveStatus {
  const ObjectiveStatus({
    required this.condition,
    required this.currentCount,
    required this.isMet,
  });

  final ObjectiveCondition condition;
  final int currentCount;
  final bool isMet;

  /// Required count (from condition).
  int get requiredCount => condition.requiredQty;

  /// Progress label for HUD display: e.g. "TANKs: 2 / 3".
  String get progressLabel {
    final target = condition.cardNameOrCategory;
    return '$target: $currentCount / $requiredCount';
  }
}

/// Pure-function evaluator for scenario objectives.
///
/// Stateless — call [evaluate] after every kill to get updated status.
/// The engine stores the result in [GameState].
class ObjectiveEvaluator {
  const ObjectiveEvaluator._();

  /// Evaluate a single objective condition against the list of destroyed
  /// targets and the weapons used for each kill.
  ///
  /// [killRecords] — all targets destroyed so far and weapons used.
  /// [allDecksEmpty] — true if all target decks have 0 remaining cards.
  ///   Only relevant for ALL_TARGETS conditions.
  static ObjectiveStatus evaluate({
    required ObjectiveCondition condition,
    required List<KillRecord> killRecords,
    bool allDecksEmpty = false,
  }) {
    if (!condition.isActive) {
      return ObjectiveStatus(
        condition: condition,
        currentCount: 0,
        isMet: false,
      );
    }

    final key = condition.cardNameOrCategory.toUpperCase().trim();

    // ── ALL TARGETS ──
    if (key == 'ALL TARGETS') {
      return ObjectiveStatus(
        condition: condition,
        currentCount: killRecords.length,
        isMet: allDecksEmpty,
      );
    }

    // ── CATEGORY WILDCARD (ANY TANK, ANY SAM, etc.) ──
    if (key.startsWith('ANY ')) {
      final category = key.substring(4); // "TANK", "SAM", "HQ", etc.
      final count = _countMatches(
        killRecords: killRecords,
        weaponRequired: condition.weaponRequired,
        matcher: (card) => card.subCategory.toUpperCase() == category,
      );
      return ObjectiveStatus(
        condition: condition,
        currentCount: count,
        isMet: count >= condition.requiredQty,
      );
    }

    // ── SPECIFIC CARD NAME ──
    final count = _countMatches(
      killRecords: killRecords,
      weaponRequired: condition.weaponRequired,
      matcher: (card) => card.cardName.toUpperCase() == key,
    );
    return ObjectiveStatus(
      condition: condition,
      currentCount: count,
      isMet: count >= condition.requiredQty,
    );
  }

  /// Count how many destroyed targets match [matcher], optionally filtering
  /// by weapon used.
  static int _countMatches({
    required List<KillRecord> killRecords,
    required String? weaponRequired,
    required bool Function(TargetCard) matcher,
  }) {
    int count = 0;
    for (final record in killRecords) {
      if (!matcher(record.target)) continue;

      // Check weapon requirement if set
      if (weaponRequired != null && weaponRequired.isNotEmpty) {
        if (record.weaponName.toUpperCase() != weaponRequired.toUpperCase()) {
          continue; // Kill doesn't count — wrong weapon
        }
      }
      count++;
    }
    return count;
  }
}
