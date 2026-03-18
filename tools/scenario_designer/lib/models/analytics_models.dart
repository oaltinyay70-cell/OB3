// l../models/analytics_models.dart
// Sprint 8 — Analytics & Game Balance

import 'dart:math';

// ---------------------------------------------------------------------------
// Event Types (100+ across 9 categories)
// ---------------------------------------------------------------------------

enum EventType {
  // Session
  sessionStart,
  sessionEnd,
  sessionResume,
  sessionPause,
  appBackground,
  appForeground,

  // Menu / Navigation
  mainMenuViewed,
  settingsOpened,
  settingsClosed,
  profileOpened,
  profileClosed,
  achievementsOpened,
  leaderboardOpened,
  lobbyOpened,
  lobbyCreated,
  lobbyJoined,
  lobbyLeft,
  analyticsOpened,
  cloudSaveOpened,

  // Gameplay — Mission
  missionStarted,
  missionCompleted,
  missionFailed,
  missionAborted,
  missionRetried,

  // Gameplay — Combat
  attackFired,
  attackHit,
  attackMiss,
  attackCritical,
  damageDealt,
  damageReceived,
  targetDestroyed,
  droneDestroyed,
  evasionAttempted,
  evasionSucceeded,
  evasionFailed,
  counterAttackFired,
  counterAttackHit,
  counterAttackMissed,

  // Gameplay — Loadout
  loadoutSelected,
  weaponEquipped,
  weaponFired,
  weaponReloaded,
  ammoDepletedWarning,

  // Gameplay — Resources
  fuelConsumed,
  fuelExhausted,
  commsCheck,
  commsDegraded,
  commsLost,

  // Phase transitions
  phaseCommsCheck,
  phaseTargetAcquisition,
  phaseAttack,
  phaseEvasion,
  phaseDamageAssessment,

  // Multiplayer
  matchStarted,
  matchEnded,
  matchWon,
  matchLost,
  matchDraw,
  turnStarted,
  turnEnded,
  chatMessageSent,
  chatMuted,
  friendAdded,
  friendRemoved,
  ratingChanged,
  leaderboardViewed,

  // Account / Cloud
  userSignedUp,
  userLoggedIn,
  userLoggedOut,
  passwordReset,
  cloudSaved,
  cloudLoaded,
  syncCompleted,
  syncConflict,
  backupCreated,
  backupRestored,

  // Achievements
  achievementUnlocked,
  achievementProgressUpdated,
  achievementsViewed,

  // Profile
  profileUpdated,
  settingsChanged,
  userBlocked,

  // Analytics / Balance
  balancePatchApplied,
  balancePatchRolledBack,
  abTestGroupAssigned,

  // Monetization (future)
  shopViewed,
  purchaseInitiated,
  purchaseCompleted,
  purchaseFailed,

  // Performance
  frameDrop,
  highLatency,
  lowMemoryWarning,

  // Errors
  crashReported,
  networkError,
  parseError,
  unknownError,
}

// ---------------------------------------------------------------------------
// Core Event
// ---------------------------------------------------------------------------

class GameEvent {
  final String eventId;
  final EventType type;
  final String playerId;
  final String sessionId;
  final DateTime timestamp;
  final DeviceInfo device;
  final Map<String, dynamic> payload;

  GameEvent({
    required this.eventId,
    required this.type,
    required this.playerId,
    required this.sessionId,
    required this.timestamp,
    required this.device,
    this.payload = const {},
  });

  factory GameEvent.create({
    required EventType type,
    required String playerId,
    required String sessionId,
    required DeviceInfo device,
    Map<String, dynamic> payload = const {},
  }) => GameEvent(
    eventId: _uuid(),
    type: type,
    playerId: playerId,
    sessionId: sessionId,
    timestamp: DateTime.now(),
    device: device,
    payload: payload,
  );

  Map<String, dynamic> toJson() => {
    'eventId': eventId,
    'type': type.name,
    'playerId': playerId,
    'sessionId': sessionId,
    'timestamp': timestamp.toIso8601String(),
    'device': device.toJson(),
    'payload': payload,
  };

  factory GameEvent.fromJson(Map<String, dynamic> json) => GameEvent(
    eventId: json['eventId'] as String,
    type: EventType.values.firstWhere((e) => e.name == json['type']),
    playerId: json['playerId'] as String,
    sessionId: json['sessionId'] as String,
    timestamp: DateTime.parse(json['timestamp'] as String),
    device: DeviceInfo.fromJson(json['device'] as Map<String, dynamic>),
    payload: Map<String, dynamic>.from(json['payload'] as Map),
  );

  static String _uuid() {
    final rand = Random();
    return List.generate(
      16,
      (_) => rand.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
  }
}

// ---------------------------------------------------------------------------
// Session & Device
// ---------------------------------------------------------------------------

class SessionInfo {
  final String sessionId;
  final String playerId;
  final DateTime startTime;
  DateTime? endTime;
  int eventCount;

  SessionInfo({
    required this.sessionId,
    required this.playerId,
    required this.startTime,
    this.endTime,
    this.eventCount = 0,
  });

  Duration get duration => (endTime ?? DateTime.now()).difference(startTime);

  bool get isActive => endTime == null;
}

class DeviceInfo {
  final String platform; // 'android' | 'ios' | 'web' | 'test'
  final String osVersion;
  final String appVersion;
  final String deviceModel;
  final String locale;

  const DeviceInfo({
    this.platform = 'test',
    this.osVersion = '1.0',
    this.appVersion = '1.0.0',
    this.deviceModel = 'TestDevice',
    this.locale = 'en_US',
  });

  Map<String, dynamic> toJson() => {
    'platform': platform,
    'osVersion': osVersion,
    'appVersion': appVersion,
    'deviceModel': deviceModel,
    'locale': locale,
  };

  factory DeviceInfo.fromJson(Map<String, dynamic> json) => DeviceInfo(
    platform: json['platform'] as String? ?? 'test',
    osVersion: json['osVersion'] as String? ?? '1.0',
    appVersion: json['appVersion'] as String? ?? '1.0.0',
    deviceModel: json['deviceModel'] as String? ?? 'TestDevice',
    locale: json['locale'] as String? ?? 'en_US',
  );
}

// ---------------------------------------------------------------------------
// Dashboard Metrics
// ---------------------------------------------------------------------------

class DashboardMetrics {
  final int totalEvents;
  final int uniquePlayers;
  final int dau; // daily active users
  final int mau; // monthly active users
  final double avgSessionLengthSeconds;
  final double retentionDay1; // 0.0–1.0
  final double retentionDay7;
  final double retentionDay30;
  final Map<String, int> eventTypeCounts;
  final Map<String, double> featureAdoption; // feature name → %

  const DashboardMetrics({
    this.totalEvents = 0,
    this.uniquePlayers = 0,
    this.dau = 0,
    this.mau = 0,
    this.avgSessionLengthSeconds = 0,
    this.retentionDay1 = 0,
    this.retentionDay7 = 0,
    this.retentionDay30 = 0,
    this.eventTypeCounts = const {},
    this.featureAdoption = const {},
  });
}

class RetentionData {
  final DateTime cohortDate;
  final int cohortSize;
  final Map<int, int> retainedByDay; // day → retained count

  const RetentionData({
    required this.cohortDate,
    required this.cohortSize,
    this.retainedByDay = const {},
  });

  double rateForDay(int day) {
    if (cohortSize == 0) return 0;
    return (retainedByDay[day] ?? 0) / cohortSize;
  }
}

// ---------------------------------------------------------------------------
// Player Behaviour
// ---------------------------------------------------------------------------

enum PlayerLifecycle { newPlayer, casual, engaged, veteran, churned }

class PlayerCohort {
  final String cohortId;
  final DateTime signupDate;
  final List<String> playerIds;
  final String platform;

  const PlayerCohort({
    required this.cohortId,
    required this.signupDate,
    required this.playerIds,
    required this.platform,
  });

  int get size => playerIds.length;
}

class FunnelStep {
  final String name;
  final int entered;
  final int completed;

  const FunnelStep({
    required this.name,
    required this.entered,
    required this.completed,
  });

  double get completionRate => entered == 0 ? 0 : completed / entered;
  int get dropped => entered - completed;
}

class EngagementScore {
  final String playerId;
  final double score; // 0–100
  final int sessionsLast7Days;
  final double avgSessionMinutes;
  final int featuresUsed;
  final bool churnRisk;

  const EngagementScore({
    required this.playerId,
    required this.score,
    required this.sessionsLast7Days,
    required this.avgSessionMinutes,
    required this.featuresUsed,
    required this.churnRisk,
  });
}

// ---------------------------------------------------------------------------
// Balance Data
// ---------------------------------------------------------------------------

class WeaponStat {
  final String weaponId;
  int uses;
  int wins; // missions won when this weapon fired at least once
  int losses;
  int totalDamage;
  int hits;
  int misses;

  WeaponStat({
    required this.weaponId,
    this.uses = 0,
    this.wins = 0,
    this.losses = 0,
    this.totalDamage = 0,
    this.hits = 0,
    this.misses = 0,
  });

  int get shots => hits + misses;
  double get hitRate => shots == 0 ? 0 : hits / shots;
  double get winRate => uses == 0 ? 0 : wins / uses;
  double get avgDamagePerShot => shots == 0 ? 0 : totalDamage / shots;
}

class ThreatStat {
  final String threatId;
  int encounters;
  int kills; // threat killed drone
  int playerDefeats; // player defeated threat
  int counterAttacks;
  int counterAttackHits;

  ThreatStat({
    required this.threatId,
    this.encounters = 0,
    this.kills = 0,
    this.playerDefeats = 0,
    this.counterAttacks = 0,
    this.counterAttackHits = 0,
  });

  double get lethality => encounters == 0 ? 0 : kills / encounters;
  double get counterHitRate =>
      counterAttacks == 0 ? 0 : counterAttackHits / counterAttacks;
}

class BalanceSnapshot {
  final DateTime takenAt;
  final Map<String, WeaponStat> weapons;
  final Map<String, ThreatStat> threats;
  final double overallWinRate;
  final double evasionSuccessRate;
  final List<String> flaggedItems; // items outside healthy range

  const BalanceSnapshot({
    required this.takenAt,
    required this.weapons,
    required this.threats,
    required this.overallWinRate,
    required this.evasionSuccessRate,
    required this.flaggedItems,
  });

  static const double targetWinRate = 0.48;
  static const double winRateTolerance = 0.02;
  static const double minUsageRatio = 0.80;
  static const double maxUsageRatio = 1.20;
}

// ---------------------------------------------------------------------------
// Balance Patches
// ---------------------------------------------------------------------------

enum PatchStatus { pending, active, rolledBack }

enum AbTestGroup { control, treatment }

class BalancePatch {
  final String patchId;
  final String reason;
  final DateTime appliedAt;
  DateTime? rolledBackAt;
  PatchStatus status;
  final Map<String, double> weaponMultipliers; // weaponId → multiplier
  final Map<String, double> threatMultipliers; // threatId → multiplier
  final double? abSplitRatio; // null = full rollout, 0.5 = 50/50

  BalancePatch({
    required this.patchId,
    required this.reason,
    required this.appliedAt,
    this.rolledBackAt,
    this.status = PatchStatus.pending,
    this.weaponMultipliers = const {},
    this.threatMultipliers = const {},
    this.abSplitRatio,
  });

  bool get isAbTest => abSplitRatio != null;
}

class PatchAlertThreshold {
  final double minWinRate; // below this → alert
  final double maxWinRate; // above this → alert
  final int minSampleSize; // don't alert without this many data points

  const PatchAlertThreshold({
    this.minWinRate = 0.40,
    this.maxWinRate = 0.58,
    this.minSampleSize = 30,
  });
}
