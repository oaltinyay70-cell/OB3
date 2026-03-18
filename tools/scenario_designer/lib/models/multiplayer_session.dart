// ignore_for_file: constant_identifier_names
/// Sprint 9 (US-9.1 – US-9.6): Core domain models for multiplayer.
library;

// ---------------------------------------------------------------------------
// Enums
// ---------------------------------------------------------------------------

enum MatchMode { casual, competitive, cooperative }

enum MatchStatus { waiting, starting, inProgress, finished, cancelled }

enum RatingDivision {
  bronze,
  silver,
  gold,
  platinum,
  diamond;

  String get displayName => name[0].toUpperCase() + name.substring(1);

  static RatingDivision fromRating(int r) {
    if (r < 1500) return bronze;
    if (r < 2000) return silver;
    if (r < 2800) return gold;
    if (r < 3500) return platinum;
    return diamond;
  }
}

enum NetworkMessageType {
  playerJoined,
  playerLeft,
  actionSent,
  actionBroadcast,
  stateSync,
  desynced,
  chatMessage,
  matchStarted,
  matchEnded,
  turnChanged,
  ping,
  pong,
}

// ---------------------------------------------------------------------------
// PlayerRating
// ---------------------------------------------------------------------------

class PlayerRating {
  final String playerId;
  int rating;
  int matchesPlayed;
  bool get isProvisional => matchesPlayed < 10;
  RatingDivision get division => RatingDivision.fromRating(rating);

  PlayerRating({
    required this.playerId,
    this.rating = 1200,
    this.matchesPlayed = 0,
  });

  PlayerRating copyWith({int? rating, int? matchesPlayed}) => PlayerRating(
    playerId: playerId,
    rating: rating ?? this.rating,
    matchesPlayed: matchesPlayed ?? this.matchesPlayed,
  );
}

// ---------------------------------------------------------------------------
// MatchPlayer
// ---------------------------------------------------------------------------

class MatchPlayer {
  final String id;
  final String displayName;
  final PlayerRating rating;
  bool isHost;
  bool isReady;
  bool isConnected;
  int pingMs;
  int victoryPoints;

  MatchPlayer({
    required this.id,
    required this.displayName,
    required this.rating,
    this.isHost = false,
    this.isReady = false,
    this.isConnected = true,
    this.pingMs = 0,
    this.victoryPoints = 0,
  });

  String get avatarInitial =>
      displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';
}

// ---------------------------------------------------------------------------
// MultiplayerMatch
// ---------------------------------------------------------------------------

class MultiplayerMatch {
  final String id;
  final String hostId;
  MatchMode mode;
  MatchStatus status;
  final String scenarioName;
  final String difficulty; // Easy / Normal / Hard
  final bool isPasswordProtected;
  final String? password;
  final int maxPlayers;
  final List<MatchPlayer> players;
  final DateTime createdAt;
  int currentTurnIndex; // index into players
  int turnNumber;
  int turnTimerSeconds; // remaining seconds in current turn
  final int maxTurnSeconds;

  MultiplayerMatch({
    required this.id,
    required this.hostId,
    this.mode = MatchMode.casual,
    this.status = MatchStatus.waiting,
    this.scenarioName = 'Alpha Strike',
    this.difficulty = 'Normal',
    this.isPasswordProtected = false,
    this.password,
    this.maxPlayers = 2,
    List<MatchPlayer>? players,
    DateTime? createdAt,
    this.currentTurnIndex = 0,
    this.turnNumber = 1,
    this.turnTimerSeconds = 30,
    this.maxTurnSeconds = 30,
  }) : players = players ?? [],
       createdAt = createdAt ?? DateTime.now();

  MatchPlayer? get currentPlayer =>
      players.isNotEmpty ? players[currentTurnIndex % players.length] : null;

  bool get isFull => players.length >= maxPlayers;
  int get playerCount => players.length;

  MatchPlayer? playerById(String id) {
    try {
      return players.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  void advanceTurn() {
    currentTurnIndex = (currentTurnIndex + 1) % players.length;
    turnNumber++;
    turnTimerSeconds = maxTurnSeconds;
  }
}

// ---------------------------------------------------------------------------
// CoopSession
// ---------------------------------------------------------------------------

class CoopSession {
  final MultiplayerMatch match;
  int sharedVictoryPoints;
  int sharedThreatCount;
  final int vpGoal;
  bool isTeamAlive;

  CoopSession({
    required this.match,
    this.sharedVictoryPoints = 0,
    this.sharedThreatCount = 0,
    this.vpGoal = 10,
    this.isTeamAlive = true,
  });

  bool get isWon => sharedVictoryPoints >= vpGoal;

  /// Difficulty scaling: each additional player adds 2 extra threats.
  int get scaledThreatPool => 6 + ((match.playerCount - 1) * 2).clamp(0, 8);
}

// ---------------------------------------------------------------------------
// NetworkMessage
// ---------------------------------------------------------------------------

class NetworkMessage {
  final NetworkMessageType type;
  final String senderId;
  final String matchId;
  final DateTime timestamp;
  final Map<String, dynamic> payload;

  NetworkMessage({
    required this.type,
    required this.senderId,
    required this.matchId,
    Map<String, dynamic>? payload,
  }) : timestamp = DateTime.now(),
       payload = payload ?? {};

  factory NetworkMessage.action({
    required String senderId,
    required String matchId,
    required String actionType,
    Map<String, dynamic>? data,
  }) => NetworkMessage(
    type: NetworkMessageType.actionSent,
    senderId: senderId,
    matchId: matchId,
    payload: {'actionType': actionType, ...?data},
  );

  factory NetworkMessage.chat({
    required String senderId,
    required String matchId,
    required String text,
    bool isQuickMessage = false,
  }) => NetworkMessage(
    type: NetworkMessageType.chatMessage,
    senderId: senderId,
    matchId: matchId,
    payload: {'text': text, 'isQuickMessage': isQuickMessage},
  );
}

// ---------------------------------------------------------------------------
// FriendEntry
// ---------------------------------------------------------------------------

class FriendEntry {
  final String id;
  final String displayName;
  final int rating;
  final bool isOnline;

  const FriendEntry({
    required this.id,
    required this.displayName,
    required this.rating,
    this.isOnline = false,
  });
}

// ---------------------------------------------------------------------------
// MatchResult
// ---------------------------------------------------------------------------

class MatchResult {
  final String matchId;
  final MatchMode mode;
  final List<MatchPlayer> players;
  final String? winnerId;
  final int ratingDelta; // for competitive
  final int durationSeconds;
  final bool wasRageQuit;
  final DateTime completedAt;

  MatchResult({
    required this.matchId,
    required this.mode,
    required this.players,
    this.winnerId,
    this.ratingDelta = 0,
    this.durationSeconds = 0,
    this.wasRageQuit = false,
    DateTime? completedAt,
  }) : completedAt = completedAt ?? DateTime.now();

  bool didPlayerWin(String playerId) => winnerId == playerId;
}
