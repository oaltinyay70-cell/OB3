// l../models/account_models.dart
// Sprint 7 — Account System domain models

/// A player account.
class UserAccount {
  final String id;
  final String username;
  final String email;
  String passwordHash; // SHA-256(salt + password)
  final String salt;
  final bool emailVerified;
  final DateTime createdAt;
  DateTime lastLoginAt;
  String? sessionToken;
  DateTime? sessionExpiry;
  int failedAttempts;
  DateTime? lockedUntil;
  bool rememberMe;
  String? nationality; // Sprint 10: Player nationality for medal eligibility

  /// Sprint 10: Call Sign is the username (locked after creation)
  String get callSign => username;

  UserAccount({
    required this.id,
    required this.username,
    required this.email,
    required this.passwordHash,
    required this.salt,
    this.emailVerified = false,
    required this.createdAt,
    required this.lastLoginAt,
    this.sessionToken,
    this.sessionExpiry,
    this.failedAttempts = 0,
    this.lockedUntil,
    this.rememberMe = false,
    this.nationality,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'username': username,
    'email': email,
    'passwordHash': passwordHash,
    'salt': salt,
    'emailVerified': emailVerified,
    'createdAt': createdAt.toIso8601String(),
    'lastLoginAt': lastLoginAt.toIso8601String(),
    'sessionToken': sessionToken,
    'sessionExpiry': sessionExpiry?.toIso8601String(),
    'failedAttempts': failedAttempts,
    'lockedUntil': lockedUntil?.toIso8601String(),
    'rememberMe': rememberMe,
    'nationality': nationality,
  };

  factory UserAccount.fromMap(Map<dynamic, dynamic> m) => UserAccount(
    id: m['id'] as String,
    username: m['username'] as String,
    email: m['email'] as String,
    passwordHash: m['passwordHash'] as String,
    salt: m['salt'] as String,
    emailVerified: m['emailVerified'] as bool? ?? false,
    createdAt: DateTime.parse(m['createdAt'] as String),
    lastLoginAt: DateTime.parse(m['lastLoginAt'] as String),
    sessionToken: m['sessionToken'] as String?,
    sessionExpiry: m['sessionExpiry'] != null
        ? DateTime.parse(m['sessionExpiry'] as String)
        : null,
    failedAttempts: m['failedAttempts'] as int? ?? 0,
    lockedUntil: m['lockedUntil'] != null
        ? DateTime.parse(m['lockedUntil'] as String)
        : null,
    rememberMe: m['rememberMe'] as bool? ?? false,
    nationality: m['nationality'] as String?,
  );
}

/// One cloud save slot.
class SaveSlot {
  final String id;
  String slotName;
  final String userId;
  final String encryptedData; // AES-256 encrypted JSON blob
  final DateTime timestamp;
  final String deviceId;
  final int version;
  final int sizeBytes;

  SaveSlot({
    required this.id,
    required this.slotName,
    required this.userId,
    required this.encryptedData,
    required this.timestamp,
    required this.deviceId,
    required this.version,
    required this.sizeBytes,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'slotName': slotName,
    'userId': userId,
    'encryptedData': encryptedData,
    'timestamp': timestamp.toIso8601String(),
    'deviceId': deviceId,
    'version': version,
    'sizeBytes': sizeBytes,
  };

  factory SaveSlot.fromMap(Map<dynamic, dynamic> m) => SaveSlot(
    id: m['id'] as String,
    slotName: m['slotName'] as String,
    userId: m['userId'] as String,
    encryptedData: m['encryptedData'] as String,
    timestamp: DateTime.parse(m['timestamp'] as String),
    deviceId: m['deviceId'] as String,
    version: m['version'] as int,
    sizeBytes: m['sizeBytes'] as int,
  );
}

/// Tracks the last-known sync state for one device.
class SyncRecord {
  final String deviceId;
  final String deviceName;
  DateTime lastSyncAt;
  int saveVersion;
  SyncStatus status;

  SyncRecord({
    required this.deviceId,
    required this.deviceName,
    required this.lastSyncAt,
    required this.saveVersion,
    this.status = SyncStatus.synced,
  });

  Map<String, dynamic> toMap() => {
    'deviceId': deviceId,
    'deviceName': deviceName,
    'lastSyncAt': lastSyncAt.toIso8601String(),
    'saveVersion': saveVersion,
    'status': status.name,
  };

  factory SyncRecord.fromMap(Map<dynamic, dynamic> m) => SyncRecord(
    deviceId: m['deviceId'] as String,
    deviceName: m['deviceName'] as String,
    lastSyncAt: DateTime.parse(m['lastSyncAt'] as String),
    saveVersion: m['saveVersion'] as int,
    status: SyncStatus.values.firstWhere(
      (s) => s.name == m['status'],
      orElse: () => SyncStatus.synced,
    ),
  );
}

enum SyncStatus { synced, conflict, syncing, offline }

/// One entry in the 7-day backup ring.
class BackupEntry {
  final String id;
  final String userId;
  final DateTime timestamp;
  final String encryptedData;
  final int version;
  final int sizeBytes;
  final String checksumSha256;

  const BackupEntry({
    required this.id,
    required this.userId,
    required this.timestamp,
    required this.encryptedData,
    required this.version,
    required this.sizeBytes,
    required this.checksumSha256,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'userId': userId,
    'timestamp': timestamp.toIso8601String(),
    'encryptedData': encryptedData,
    'version': version,
    'sizeBytes': sizeBytes,
    'checksumSha256': checksumSha256,
  };

  factory BackupEntry.fromMap(Map<dynamic, dynamic> m) => BackupEntry(
    id: m['id'] as String,
    userId: m['userId'] as String,
    timestamp: DateTime.parse(m['timestamp'] as String),
    encryptedData: m['encryptedData'] as String,
    version: m['version'] as int,
    sizeBytes: m['sizeBytes'] as int,
    checksumSha256: m['checksumSha256'] as String,
  );
}

/// Achievement definition (static catalogue entry).
class Achievement {
  final String id;
  final String title;
  final String description;
  final AchievementCategory category;
  final int maxProgress; // 1 means binary (lock/unlock)
  final bool isHidden;
  final double rarityPercent; // mocked; 0.0–100.0

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    this.maxProgress = 1,
    this.isHidden = false,
    this.rarityPercent = 50.0,
  });
}

enum AchievementCategory { combat, campaign, multiplayer, collection, hidden }

/// Mutable progress record stored per user.
class AchievementProgress {
  final String achievementId;
  final String userId;
  int current;
  bool unlocked;
  DateTime? unlockedAt;

  AchievementProgress({
    required this.achievementId,
    required this.userId,
    this.current = 0,
    this.unlocked = false,
    this.unlockedAt,
  });

  Map<String, dynamic> toMap() => {
    'achievementId': achievementId,
    'userId': userId,
    'current': current,
    'unlocked': unlocked,
    'unlockedAt': unlockedAt?.toIso8601String(),
  };

  factory AchievementProgress.fromMap(Map<dynamic, dynamic> m) =>
      AchievementProgress(
        achievementId: m['achievementId'] as String,
        userId: m['userId'] as String,
        current: m['current'] as int? ?? 0,
        unlocked: m['unlocked'] as bool? ?? false,
        unlockedAt: m['unlockedAt'] != null
            ? DateTime.parse(m['unlockedAt'] as String)
            : null,
      );
}

/// Aggregated gameplay statistics for one player.
class PlayerStats {
  final String userId;
  int totalPlaytimeSeconds;
  int missionsAttempted;
  int missionsCompleted;
  int totalKills;
  int wins;
  int losses;
  int highestRating;
  String favoriteMode;

  /// Missions played (alias for missionsAttempted).
  int get missionsPlayed => missionsAttempted;

  /// Missions won (alias for wins).
  int get missionsWon => wins;

  /// Highest rank string for display.
  String highestRank;

  PlayerStats({
    required this.userId,
    this.totalPlaytimeSeconds = 0,
    this.missionsAttempted = 0,
    this.missionsCompleted = 0,
    this.totalKills = 0,
    this.wins = 0,
    this.losses = 0,
    this.highestRating = 1000,
    this.favoriteMode = 'Campaign',
    this.highestRank = 'Recruit',
  });

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'totalPlaytimeSeconds': totalPlaytimeSeconds,
    'missionsAttempted': missionsAttempted,
    'missionsCompleted': missionsCompleted,
    'totalKills': totalKills,
    'wins': wins,
    'losses': losses,
    'highestRating': highestRating,
    'favoriteMode': favoriteMode,
  };

  factory PlayerStats.fromMap(Map<dynamic, dynamic> m) => PlayerStats(
    userId: m['userId'] as String,
    totalPlaytimeSeconds: m['totalPlaytimeSeconds'] as int? ?? 0,
    missionsAttempted: m['missionsAttempted'] as int? ?? 0,
    missionsCompleted: m['missionsCompleted'] as int? ?? 0,
    totalKills: m['totalKills'] as int? ?? 0,
    wins: m['wins'] as int? ?? 0,
    losses: m['losses'] as int? ?? 0,
    highestRating: m['highestRating'] as int? ?? 1000,
    favoriteMode: m['favoriteMode'] as String? ?? 'Campaign',
  );
}

/// User preferences / settings.
class PlayerSettings {
  String language;
  String difficulty; // Easy | Normal | Hard | Elite
  double musicVolume; // 0.0–1.0
  double sfxVolume;
  bool notificationsEnabled;
  bool isPublicProfile;
  List<String> blockedUserIds;
  // Sprint 7 extended fields
  bool soundEnabled;
  bool musicEnabled;
  bool autoSaveEnabled;
  bool darkMode;
  double masterVolume; // 0.0–1.0
  bool showOnLeaderboard;
  bool shareAchievements;

  PlayerSettings({
    this.language = 'en',
    this.difficulty = 'Normal',
    this.musicVolume = 0.7,
    this.sfxVolume = 1.0,
    this.notificationsEnabled = true,
    this.isPublicProfile = true,
    List<String>? blockedUserIds,
    this.soundEnabled = true,
    this.musicEnabled = true,
    this.autoSaveEnabled = true,
    this.darkMode = true,
    this.masterVolume = 0.8,
    this.showOnLeaderboard = true,
    this.shareAchievements = true,
  }) : blockedUserIds = blockedUserIds ?? [];

  PlayerSettings copyWith({
    String? language,
    String? difficulty,
    double? musicVolume,
    double? sfxVolume,
    bool? notificationsEnabled,
    bool? isPublicProfile,
    List<String>? blockedUserIds,
    bool? soundEnabled,
    bool? musicEnabled,
    bool? autoSaveEnabled,
    bool? darkMode,
    double? masterVolume,
    bool? showOnLeaderboard,
    bool? shareAchievements,
  }) => PlayerSettings(
    language: language ?? this.language,
    difficulty: difficulty ?? this.difficulty,
    musicVolume: musicVolume ?? this.musicVolume,
    sfxVolume: sfxVolume ?? this.sfxVolume,
    notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    isPublicProfile: isPublicProfile ?? this.isPublicProfile,
    blockedUserIds: blockedUserIds ?? List.from(this.blockedUserIds),
    soundEnabled: soundEnabled ?? this.soundEnabled,
    musicEnabled: musicEnabled ?? this.musicEnabled,
    autoSaveEnabled: autoSaveEnabled ?? this.autoSaveEnabled,
    darkMode: darkMode ?? this.darkMode,
    masterVolume: masterVolume ?? this.masterVolume,
    showOnLeaderboard: showOnLeaderboard ?? this.showOnLeaderboard,
    shareAchievements: shareAchievements ?? this.shareAchievements,
  );

  Map<String, dynamic> toMap() => {
    'language': language,
    'difficulty': difficulty,
    'musicVolume': musicVolume,
    'sfxVolume': sfxVolume,
    'notificationsEnabled': notificationsEnabled,
    'isPublicProfile': isPublicProfile,
    'blockedUserIds': blockedUserIds,
    'soundEnabled': soundEnabled,
    'musicEnabled': musicEnabled,
    'autoSaveEnabled': autoSaveEnabled,
    'darkMode': darkMode,
    'masterVolume': masterVolume,
    'showOnLeaderboard': showOnLeaderboard,
    'shareAchievements': shareAchievements,
  };

  factory PlayerSettings.fromMap(Map<dynamic, dynamic> m) => PlayerSettings(
    language: m['language'] as String? ?? 'en',
    difficulty: m['difficulty'] as String? ?? 'Normal',
    musicVolume: (m['musicVolume'] as num?)?.toDouble() ?? 0.7,
    sfxVolume: (m['sfxVolume'] as num?)?.toDouble() ?? 1.0,
    notificationsEnabled: m['notificationsEnabled'] as bool? ?? true,
    isPublicProfile: m['isPublicProfile'] as bool? ?? true,
    blockedUserIds: (m['blockedUserIds'] as List?)?.cast<String>() ?? [],
    soundEnabled: m['soundEnabled'] as bool? ?? true,
    musicEnabled: m['musicEnabled'] as bool? ?? true,
    autoSaveEnabled: m['autoSaveEnabled'] as bool? ?? true,
    darkMode: m['darkMode'] as bool? ?? true,
    masterVolume: (m['masterVolume'] as num?)?.toDouble() ?? 0.8,
    showOnLeaderboard: m['showOnLeaderboard'] as bool? ?? true,
    shareAchievements: m['shareAchievements'] as bool? ?? true,
  );
}

/// Combined player profile returned to UI.
class PlayerProfile {
  final UserAccount account;
  final PlayerStats stats;
  final List<AchievementProgress> achievements;
  final PlayerSettings settings;

  const PlayerProfile({
    required this.account,
    required this.stats,
    required this.achievements,
    required this.settings,
  });
}

/// Password-strength rating.
enum PasswordStrength { weak, fair, strong, veryStrong }

/// Auth result returned by MockAuthAdapter.
class AuthResult {
  final bool success;
  final String? error;
  final UserAccount? account;

  const AuthResult.ok(this.account) : success = true, error = null;

  const AuthResult.fail(this.error) : success = false, account = null;
}
