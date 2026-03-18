/// Sprint 10 (Epic 4): Campaign models.
library;

class Campaign {
  final int id;
  final String name;
  final String? description;
  final String? narrative;
  final List<int> scenarioIds;
  final List<CampaignDroneEntry> startingDrones;
  final int repairPointsPool;

  const Campaign({
    required this.id,
    required this.name,
    this.description,
    this.narrative,
    required this.scenarioIds,
    required this.startingDrones,
    this.repairPointsPool = 10,
  });

  factory Campaign.fromRows({
    required Map<String, dynamic> campaignRow,
    required List<Map<String, dynamic>> scenarioRows,
    required List<Map<String, dynamic>> droneRows,
  }) {
    return Campaign(
      id: campaignRow['id'] as int,
      name: campaignRow['name'] as String,
      description: campaignRow['description'] as String?,
      narrative: campaignRow['narrative'] as String?,
      scenarioIds: scenarioRows
          .map((r) => r['scenario_id'] as int)
          .toList(),
      startingDrones: droneRows
          .map((r) => CampaignDroneEntry(
                droneId: r['drone_id'] as int,
                quantity: r['quantity'] as int? ?? 1,
              ))
          .toList(),
      repairPointsPool: campaignRow['repair_points_pool'] as int? ?? 10,
    );
  }
}

class CampaignDroneEntry {
  final int droneId;
  final int quantity;

  const CampaignDroneEntry({required this.droneId, this.quantity = 1});
}

/// Mutable campaign state (persisted between scenarios).
class CampaignState {
  final int campaignId;
  final String campaignName;
  int currentScenarioIndex;
  Map<int, CampaignDroneState> droneStates;
  int repairPointsRemaining;
  List<int> completedScenarioIds;
  List<String> earnedMedalIds;
  int totalVP;
  int totalKills;

  CampaignState({
    required this.campaignId,
    required this.campaignName,
    this.currentScenarioIndex = 0,
    required this.droneStates,
    required this.repairPointsRemaining,
    List<int>? completedScenarioIds,
    List<String>? earnedMedalIds,
    this.totalVP = 0,
    this.totalKills = 0,
  })  : completedScenarioIds = completedScenarioIds ?? [],
        earnedMedalIds = earnedMedalIds ?? [];

  bool get isLost =>
      droneStates.values.every((d) => d.isDestroyed);

  int get availableDroneCount =>
      droneStates.values.where((d) => !d.isDestroyed).length;

  Map<String, dynamic> toJson() => {
    'campaignId': campaignId,
    'campaignName': campaignName,
    'currentScenarioIndex': currentScenarioIndex,
    'droneStates': droneStates.map(
      (k, v) => MapEntry(k.toString(), v.toJson()),
    ),
    'repairPointsRemaining': repairPointsRemaining,
    'completedScenarioIds': completedScenarioIds,
    'earnedMedalIds': earnedMedalIds,
    'totalVP': totalVP,
    'totalKills': totalKills,
  };

  factory CampaignState.fromJson(Map<String, dynamic> json) {
    final droneMap = (json['droneStates'] as Map<String, dynamic>).map(
      (k, v) => MapEntry(
        int.parse(k),
        CampaignDroneState.fromJson(v as Map<String, dynamic>),
      ),
    );
    return CampaignState(
      campaignId: json['campaignId'] as int,
      campaignName: json['campaignName'] as String,
      currentScenarioIndex: json['currentScenarioIndex'] as int? ?? 0,
      droneStates: droneMap,
      repairPointsRemaining: json['repairPointsRemaining'] as int? ?? 0,
      completedScenarioIds:
          (json['completedScenarioIds'] as List?)?.cast<int>() ?? [],
      earnedMedalIds:
          (json['earnedMedalIds'] as List?)?.cast<String>() ?? [],
      totalVP: json['totalVP'] as int? ?? 0,
      totalKills: json['totalKills'] as int? ?? 0,
    );
  }
}

class CampaignDroneState {
  final int droneId;
  final String droneName;
  int currentHP;
  final int maxHP;
  bool isDestroyed;

  CampaignDroneState({
    required this.droneId,
    required this.droneName,
    required this.currentHP,
    required this.maxHP,
    this.isDestroyed = false,
  });

  void repair(int points) {
    currentHP = (currentHP + points).clamp(0, maxHP);
    if (currentHP > 0) isDestroyed = false;
  }

  Map<String, dynamic> toJson() => {
    'droneId': droneId,
    'droneName': droneName,
    'currentHP': currentHP,
    'maxHP': maxHP,
    'isDestroyed': isDestroyed,
  };

  factory CampaignDroneState.fromJson(Map<String, dynamic> json) =>
      CampaignDroneState(
        droneId: json['droneId'] as int,
        droneName: json['droneName'] as String? ?? 'Unknown',
        currentHP: json['currentHP'] as int? ?? 10,
        maxHP: json['maxHP'] as int? ?? 10,
        isDestroyed: json['isDestroyed'] as bool? ?? false,
      );
}
