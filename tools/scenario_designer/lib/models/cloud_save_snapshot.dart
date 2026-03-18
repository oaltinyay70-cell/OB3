// l../models/cloud_save_snapshot.dart
// Sprint 7 — Full game-state snapshot for cloud save / backup

import 'dart:convert';

/// A serialisable snapshot of the complete player game state.
/// This is what gets AES-256 encrypted and stored in a SaveSlot.
class CloudSaveSnapshot {
  final int version; // incremented on every save
  final String userId;
  final DateTime timestamp;
  final String deviceId;

  // Campaign progress
  final int scenariosCompleted;
  final int totalMissionsPlayed;
  final List<String> completedScenarioIds;
  final String? lastActiveMission;

  // Loadout
  final String? selectedDroneId;
  final List<String> unlockedWeaponIds;

  // Multiplayer stats snapshot
  final int multiplayerRating;
  final int multiplayerWins;
  final int multiplayerLosses;

  // Achievement progress map: achievementId → current progress int
  final Map<String, int> achievementProgress;

  // Settings snapshot (so restoring a backup also restores prefs)
  final String language;
  final String difficulty;
  final double musicVolume;
  final double sfxVolume;

  const CloudSaveSnapshot({
    required this.version,
    required this.userId,
    required this.timestamp,
    required this.deviceId,
    this.scenariosCompleted = 0,
    this.totalMissionsPlayed = 0,
    this.completedScenarioIds = const [],
    this.lastActiveMission,
    this.selectedDroneId,
    this.unlockedWeaponIds = const [],
    this.multiplayerRating = 1000,
    this.multiplayerWins = 0,
    this.multiplayerLosses = 0,
    this.achievementProgress = const {},
    this.language = 'en',
    this.difficulty = 'Normal',
    this.musicVolume = 0.7,
    this.sfxVolume = 1.0,
  });

  Map<String, dynamic> toMap() => {
    'version': version,
    'userId': userId,
    'timestamp': timestamp.toIso8601String(),
    'deviceId': deviceId,
    'scenariosCompleted': scenariosCompleted,
    'totalMissionsPlayed': totalMissionsPlayed,
    'completedScenarioIds': completedScenarioIds,
    'lastActiveMission': lastActiveMission,
    'selectedDroneId': selectedDroneId,
    'unlockedWeaponIds': unlockedWeaponIds,
    'multiplayerRating': multiplayerRating,
    'multiplayerWins': multiplayerWins,
    'multiplayerLosses': multiplayerLosses,
    'achievementProgress': achievementProgress,
    'language': language,
    'difficulty': difficulty,
    'musicVolume': musicVolume,
    'sfxVolume': sfxVolume,
  };

  String toJson() => jsonEncode(toMap());

  factory CloudSaveSnapshot.fromMap(Map<String, dynamic> m) =>
      CloudSaveSnapshot(
        version: m['version'] as int,
        userId: m['userId'] as String,
        timestamp: DateTime.parse(m['timestamp'] as String),
        deviceId: m['deviceId'] as String,
        scenariosCompleted: m['scenariosCompleted'] as int? ?? 0,
        totalMissionsPlayed: m['totalMissionsPlayed'] as int? ?? 0,
        completedScenarioIds:
            (m['completedScenarioIds'] as List?)?.cast<String>() ?? [],
        lastActiveMission: m['lastActiveMission'] as String?,
        selectedDroneId: m['selectedDroneId'] as String?,
        unlockedWeaponIds:
            (m['unlockedWeaponIds'] as List?)?.cast<String>() ?? [],
        multiplayerRating: m['multiplayerRating'] as int? ?? 1000,
        multiplayerWins: m['multiplayerWins'] as int? ?? 0,
        multiplayerLosses: m['multiplayerLosses'] as int? ?? 0,
        achievementProgress:
            (m['achievementProgress'] as Map?)?.map(
              (k, v) => MapEntry(k as String, v as int),
            ) ??
            {},
        language: m['language'] as String? ?? 'en',
        difficulty: m['difficulty'] as String? ?? 'Normal',
        musicVolume: (m['musicVolume'] as num?)?.toDouble() ?? 0.7,
        sfxVolume: (m['sfxVolume'] as num?)?.toDouble() ?? 1.0,
      );

  factory CloudSaveSnapshot.fromJson(String json) =>
      CloudSaveSnapshot.fromMap(jsonDecode(json) as Map<String, dynamic>);

  CloudSaveSnapshot copyWith({
    int? version,
    String? userId,
    DateTime? timestamp,
    String? deviceId,
    int? scenariosCompleted,
    int? totalMissionsPlayed,
    List<String>? completedScenarioIds,
    String? lastActiveMission,
    String? selectedDroneId,
    List<String>? unlockedWeaponIds,
    int? multiplayerRating,
    int? multiplayerWins,
    int? multiplayerLosses,
    Map<String, int>? achievementProgress,
    String? language,
    String? difficulty,
    double? musicVolume,
    double? sfxVolume,
  }) => CloudSaveSnapshot(
    version: version ?? this.version,
    userId: userId ?? this.userId,
    timestamp: timestamp ?? this.timestamp,
    deviceId: deviceId ?? this.deviceId,
    scenariosCompleted: scenariosCompleted ?? this.scenariosCompleted,
    totalMissionsPlayed: totalMissionsPlayed ?? this.totalMissionsPlayed,
    completedScenarioIds: completedScenarioIds ?? this.completedScenarioIds,
    lastActiveMission: lastActiveMission ?? this.lastActiveMission,
    selectedDroneId: selectedDroneId ?? this.selectedDroneId,
    unlockedWeaponIds: unlockedWeaponIds ?? this.unlockedWeaponIds,
    multiplayerRating: multiplayerRating ?? this.multiplayerRating,
    multiplayerWins: multiplayerWins ?? this.multiplayerWins,
    multiplayerLosses: multiplayerLosses ?? this.multiplayerLosses,
    achievementProgress: achievementProgress ?? this.achievementProgress,
    language: language ?? this.language,
    difficulty: difficulty ?? this.difficulty,
    musicVolume: musicVolume ?? this.musicVolume,
    sfxVolume: sfxVolume ?? this.sfxVolume,
  );
}
