import '../models/target_card.dart';

/// Scoring service per rulebook §7.
class ScoringService {
  ScoringService._();

  /// Calculate final score from destroyed targets.
  ///
  /// Maximum Kill: sum VP from destroyed target card pile.
  /// Quick Kill: same, but game ends when objective complete.
  static double calculateScore(List<TargetCard> destroyedTargets) {
    return destroyedTargets.fold(0.0, (sum, card) => sum + card.vp);
  }

  /// Final score after subtracting drone VP value (for Solitaire Quick Game §5.1).
  /// [droneVp] is not currently in the DB — defaults to 0 until added.
  static double calculateFinalScore(
    List<TargetCard> destroyedTargets, {
    double droneVp = 0.0,
  }) {
    return calculateScore(destroyedTargets) - droneVp;
  }
}
