class MissionSave {
  final Map<String, dynamic> boardState;
  final Map<String, dynamic> turnState;
  final List<Map<String, dynamic>> rollHistory;
  final Map<String, dynamic>? droneState;
  final Map<String, dynamic>? targetState;
  final Map<String, dynamic>? threatState;
  final Map<String, dynamic>? combatState;
  final Map<String, dynamic>? scenarioState;
  final Map<String, dynamic>? combatResultState;
  final DateTime saveTimestamp;

  const MissionSave({
    required this.boardState,
    required this.turnState,
    required this.rollHistory,
    this.droneState,
    this.targetState,
    this.threatState,
    this.combatState,
    this.scenarioState,
    this.combatResultState,
    required this.saveTimestamp,
  });

  Map<String, dynamic> toJson() => {
    'boardState': boardState,
    'turnState': turnState,
    'rollHistory': rollHistory,
    'droneState': droneState,
    'targetState': targetState,
    'threatState': threatState,
    'combatState': combatState,
    'scenarioState': scenarioState,
    'combatResultState': combatResultState,
    'saveTimestamp': saveTimestamp.toIso8601String(),
  };

  /// Safely cast a dynamic map (from Hive) to Map<String, dynamic>.
  static Map<String, dynamic>? _castMap(dynamic value) {
    if (value == null) return null;
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  factory MissionSave.fromJson(Map<String, dynamic> json) => MissionSave(
    boardState: _castMap(json['boardState']) ?? {},
    turnState: _castMap(json['turnState']) ?? {},
    rollHistory: (json['rollHistory'] as List? ?? [])
        .map((e) => _castMap(e) ?? <String, dynamic>{})
        .toList(),
    droneState: _castMap(json['droneState']),
    targetState: _castMap(json['targetState']),
    threatState: _castMap(json['threatState']),
    combatState: _castMap(json['combatState']),
    scenarioState: _castMap(json['scenarioState']),
    combatResultState: _castMap(json['combatResultState']),
    saveTimestamp: DateTime.parse(json['saveTimestamp'] as String),
  );
}

