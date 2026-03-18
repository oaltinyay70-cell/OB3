/// Sprint RTB: Mission result model for end-of-mission scoring and display.
library;
import '../../utils/constants.dart';

/// Mission outcome classification.
enum MissionStatus {
  success,
  partialSuccess,
  objectiveFailed, // Primary objective not met — VP counted, scenario failed
  failure;

  String get displayName {
    switch (this) {
      case MissionStatus.success:
        return 'SUCCESS';
      case MissionStatus.partialSuccess:
        return 'PARTIAL SUCCESS';
      case MissionStatus.objectiveFailed:
        return 'OBJECTIVE FAILED';
      case MissionStatus.failure:
        return 'FAILURE';
    }
  }

  String get emoji {
    switch (this) {
      case MissionStatus.success:
        return '✓';
      case MissionStatus.partialSuccess:
        return '◐';
      case MissionStatus.objectiveFailed:
        return '⚠';
      case MissionStatus.failure:
        return '✗';
    }
  }
}

/// Complete snapshot of mission results for the results screen.
class MissionResult {
  final String scenarioName;
  final MissionEndReason endReason;
  final MissionStatus status;

  // Scoring
  final double targetVP;
  final double droneBonus;
  final double rtbSurvivalBonus;
  final double droneDestroyedPenalty;
  final double totalVP;

  // Drone state
  final int currentIntegrity;
  final int startingIntegrity;
  final double fuelRemaining;
  final double maxFuel;
  final int sensorsDamage;
  final int commsDamage;
  final String droneName;

  // Targets
  final int targetsDestroyed;
  final List<Map<String, dynamic>> destroyedTargetsList;
  final List<Map<String, dynamic>> threatsEvadedList;
  final List<Map<String, dynamic>> targetsLazedList;

  // Objectives
  final String? primaryObjective;
  final bool primaryObjectiveMet;
  final String? secondaryObjective;
  final bool secondaryObjectiveMet;

  // Meta
  final int turnsPlayed;
  final DateTime timestamp;

  const MissionResult({
    required this.scenarioName,
    required this.endReason,
    required this.status,
    required this.targetVP,
    required this.droneBonus,
    this.rtbSurvivalBonus = 0.0,
    this.droneDestroyedPenalty = 0.0,
    required this.totalVP,
    required this.currentIntegrity,
    required this.startingIntegrity,
    required this.fuelRemaining,
    required this.maxFuel,
    required this.sensorsDamage,
    required this.commsDamage,
    required this.droneName,
    required this.targetsDestroyed,
    required this.destroyedTargetsList,
    this.threatsEvadedList = const [],
    this.targetsLazedList = const [],
    this.primaryObjective,
    this.primaryObjectiveMet = false,
    this.secondaryObjective,
    this.secondaryObjectiveMet = false,
    required this.turnsPlayed,
    required this.timestamp,
  });

  /// Whether the drone returned safely (not crashed/destroyed).
  bool get droneReturnedSafely => endReason.isRtb || endReason.isSuccess;

  /// Human-readable end reason for display.
  String get endReasonText {
    switch (endReason) {
      case MissionEndReason.voluntaryRtb:
        return 'Voluntary Return to Base';
      case MissionEndReason.fuelZeroRtb:
        return 'Fuel Depleted — Mandatory Return';
      case MissionEndReason.crash:
        return 'Drone Crashed — Fuel Depletion';
      case MissionEndReason.missionComplete:
        return 'Mission Complete';
      default:
        return endReason.displayName;
    }
  }

  Map<String, dynamic> toJson() => {
    'scenarioName': scenarioName,
    'endReason': endReason.index,
    'status': status.index,
    'targetVP': targetVP,
    'droneBonus': droneBonus,
    'rtbSurvivalBonus': rtbSurvivalBonus,
    'droneDestroyedPenalty': droneDestroyedPenalty,
    'totalVP': totalVP,
    'currentIntegrity': currentIntegrity,
    'startingIntegrity': startingIntegrity,
    'fuelRemaining': fuelRemaining,
    'maxFuel': maxFuel,
    'sensorsDamage': sensorsDamage,
    'commsDamage': commsDamage,
    'droneName': droneName,
    'targetsDestroyed': targetsDestroyed,
    'destroyedTargetsList': destroyedTargetsList,
    'threatsEvadedList': threatsEvadedList,
    'targetsLazedList': targetsLazedList,
    'primaryObjective': primaryObjective,
    'primaryObjectiveMet': primaryObjectiveMet,
    'secondaryObjective': secondaryObjective,
    'secondaryObjectiveMet': secondaryObjectiveMet,
    'turnsPlayed': turnsPlayed,
    'timestamp': timestamp.toIso8601String(),
  };

  factory MissionResult.fromJson(Map<String, dynamic> json) => MissionResult(
    scenarioName: json['scenarioName'] as String,
    endReason: MissionEndReason.values[json['endReason'] as int],
    status: MissionStatus.values[json['status'] as int],
    targetVP: (json['targetVP'] as num).toDouble(),
    droneBonus: (json['droneBonus'] as num).toDouble(),
    rtbSurvivalBonus: (json['rtbSurvivalBonus'] as num?)?.toDouble() ?? 0.0,
    droneDestroyedPenalty: (json['droneDestroyedPenalty'] as num?)?.toDouble() ?? 0.0,
    totalVP: (json['totalVP'] as num).toDouble(),
    currentIntegrity: json['currentIntegrity'] as int,
    startingIntegrity: json['startingIntegrity'] as int,
    fuelRemaining: (json['fuelRemaining'] as num?)?.toDouble()
        ?? (json['enduranceRemaining'] as num?)?.toDouble() ?? 24.0,
    maxFuel: (json['maxFuel'] as num?)?.toDouble()
        ?? (json['maxEnduranceHours'] as num?)?.toDouble() ?? 24.0,
    sensorsDamage: json['sensorsDamage'] as int,
    commsDamage: json['commsDamage'] as int,
    droneName: json['droneName'] as String,
    targetsDestroyed: json['targetsDestroyed'] as int,
    destroyedTargetsList: (json['destroyedTargetsList'] as List)
        .cast<Map<String, dynamic>>(),
    threatsEvadedList: (json['threatsEvadedList'] as List? ?? [])
        .cast<Map<String, dynamic>>(),
    targetsLazedList: (json['targetsLazedList'] as List? ?? [])
        .cast<Map<String, dynamic>>(),
    primaryObjective: json['primaryObjective'] as String?,
    primaryObjectiveMet: json['primaryObjectiveMet'] as bool? ?? false,
    secondaryObjective: json['secondaryObjective'] as String?,
    secondaryObjectiveMet: json['secondaryObjectiveMet'] as bool? ?? false,
    turnsPlayed: json['turnsPlayed'] as int,
    timestamp: DateTime.parse(json['timestamp'] as String),
  );
}
