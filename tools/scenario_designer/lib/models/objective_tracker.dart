/// Tracks primary and secondary scenario objectives.
/// Per BA spec §6.2.1 — objectives are evaluated after every kill in Step 2.
/// Secondary VP only counts in campaign score if primary is also achieved.
library;

class ScenarioObjective {
  final String id;

  /// Card description/name that satisfies this objective.
  final String cardDescription;

  /// How many of this target must be killed.
  final int requiredKills;

  /// VP value associated with this objective (in addition to normal VP).
  final int bonusVP;

  int killedCount = 0;

  ScenarioObjective({
    required this.id,
    required this.cardDescription,
    this.requiredKills = 1,
    this.bonusVP = 0,
  });

  bool get isComplete => killedCount >= requiredKills;

  Map<String, dynamic> toJson() => {
        'id': id,
        'cardDescription': cardDescription,
        'requiredKills': requiredKills,
        'bonusVP': bonusVP,
        'killedCount': killedCount,
      };

  factory ScenarioObjective.fromJson(Map<String, dynamic> json) {
    final obj = ScenarioObjective(
      id: json['id'] as String,
      cardDescription: json['cardDescription'] as String,
      requiredKills: json['requiredKills'] as int? ?? 1,
      bonusVP: json['bonusVP'] as int? ?? 0,
    );
    obj.killedCount = json['killedCount'] as int? ?? 0;
    return obj;
  }
}

class ObjectiveTracker {
  final List<ScenarioObjective> primaryObjectives;
  final List<ScenarioObjective> secondaryObjectives;

  /// Running ordered kill list — target description of each confirmed kill.
  final List<String> killList = [];

  /// VP banked specifically from secondary objective kills.
  int secondaryVPBanked = 0;

  /// Whether primary was already met (for RTB prompt — fires only once).
  bool _primaryJustCompleted = false;

  ObjectiveTracker({
    required this.primaryObjectives,
    required this.secondaryObjectives,
  });

  /// Factory for a scenario with no structured objectives defined.
  factory ObjectiveTracker.empty() =>
      ObjectiveTracker(primaryObjectives: [], secondaryObjectives: []);

  bool get hasPrimaryObjectives => primaryObjectives.isNotEmpty;
  bool get hasSecondaryObjectives => secondaryObjectives.isNotEmpty;
  bool get allPrimaryMet =>
      primaryObjectives.isNotEmpty && primaryObjectives.every((o) => o.isComplete);
  bool get allSecondaryMet =>
      secondaryObjectives.isEmpty || secondaryObjectives.every((o) => o.isComplete);

  /// Whether the RTB prompt should fire this kill.
  /// Returns true exactly once when primary transitions to complete.
  bool get primaryJustCompleted => _primaryJustCompleted;

  /// Acknowledge and dismiss the "primary just completed" flag.
  void clearPrimaryJustCompletedFlag() => _primaryJustCompleted = false;

  /// Called after every confirmed kill in Step 2.
  /// Records the kill in the kill list, updates objective counters.
  /// Returns true if primary objective was JUST completed by this kill.
  bool recordKill(String targetDescription, {int secondaryVP = 0}) {
    killList.add(targetDescription);

    final wasPrimaryMet = allPrimaryMet;

    // Check if this kill satisfies any primary objective
    for (final obj in primaryObjectives) {
      if (_matches(targetDescription, obj.cardDescription) && !obj.isComplete) {
        obj.killedCount++;
        break;
      }
    }

    // Check if this kill satisfies any secondary objective
    for (final obj in secondaryObjectives) {
      if (_matches(targetDescription, obj.cardDescription) && !obj.isComplete) {
        obj.killedCount++;
        secondaryVPBanked += secondaryVP;
        break;
      }
    }

    // Did primary become complete on this kill?
    _primaryJustCompleted = !wasPrimaryMet && allPrimaryMet;
    return _primaryJustCompleted;
  }

  /// Calculate the campaign-eligible VP.
  /// Per spec §12: secondary VP excluded from campaign total if primary not met.
  int calculateCampaignEligibleVP(int totalBankedVP) {
    if (!allPrimaryMet && hasPrimaryObjectives) {
      return totalBankedVP - secondaryVPBanked;
    }
    return totalBankedVP;
  }

  static bool _matches(String killName, String objectiveName) {
    return killName.toUpperCase().contains(objectiveName.toUpperCase()) ||
        objectiveName.toUpperCase().contains(killName.toUpperCase());
  }

  Map<String, dynamic> toJson() => {
        'primaryObjectives': primaryObjectives.map((o) => o.toJson()).toList(),
        'secondaryObjectives': secondaryObjectives.map((o) => o.toJson()).toList(),
        'killList': killList,
        'secondaryVPBanked': secondaryVPBanked,
      };

  factory ObjectiveTracker.fromJson(Map<String, dynamic> json) {
    final tracker = ObjectiveTracker(
      primaryObjectives: (json['primaryObjectives'] as List? ?? [])
          .map((j) => ScenarioObjective.fromJson(j as Map<String, dynamic>))
          .toList(),
      secondaryObjectives: (json['secondaryObjectives'] as List? ?? [])
          .map((j) => ScenarioObjective.fromJson(j as Map<String, dynamic>))
          .toList(),
    );
    tracker.killList.addAll(
        (json['killList'] as List? ?? []).cast<String>());
    tracker.secondaryVPBanked = json['secondaryVPBanked'] as int? ?? 0;
    return tracker;
  }
}
