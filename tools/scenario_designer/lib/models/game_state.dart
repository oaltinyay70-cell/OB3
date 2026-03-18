import '../../utils/constants.dart';
import 'drone.dart';
import 'cards.dart';

class GameState {
  final String gameId;
  final String userId;
  final GameMode mode;
  final String scenarioId;
  final int turnNumber;
  final Drone drone;
  final Box currentBox;
  final TargetCard? currentTarget;
  final ThreatCard? currentThreat;
  final List<TargetCard> destroyedTargets;
  final List<String> discardedCardIds;
  final DateTime gameStartTime;
  final DateTime? lastAutoSaveTime;
  final GameStatus gameStatus;

  // Sprint 1: Scenario modifiers
  final int modifierFuelCost;
  final int modifierAttackRoll;
  final int modifierEvasion;
  final int modifierAltitudeCost;
  final int modifierTargetAcquisition;
  final int modifierThreatDetermination;

  // Sprint 1: Profile tracking
  final int? profileId;
  final String? scoringMode;

  const GameState({
    required this.gameId,
    required this.userId,
    required this.mode,
    required this.scenarioId,
    this.turnNumber = 1,
    required this.drone,
    this.currentBox = Box.b0Start,
    this.currentTarget,
    this.currentThreat,
    this.destroyedTargets = const [],
    this.discardedCardIds = const [],
    required this.gameStartTime,
    this.lastAutoSaveTime,
    this.gameStatus = GameStatus.active,
    this.modifierFuelCost = 0,
    this.modifierAttackRoll = 0,
    this.modifierEvasion = 0,
    this.modifierAltitudeCost = 0,
    this.modifierTargetAcquisition = 0,
    this.modifierThreatDetermination = 0,
    this.profileId,
    this.scoringMode,
  });

  Map<String, dynamic> toJson() => {
    'gameId': gameId,
    'userId': userId,
    'mode': mode.index,
    'scenarioId': scenarioId,
    'turnNumber': turnNumber,
    'drone': drone.toJson(),
    'currentBox': currentBox.index,
    'currentTarget': currentTarget?.toJson(),
    'currentThreat': currentThreat?.toJson(),
    'destroyedTargets': destroyedTargets.map((t) => t.toJson()).toList(),
    'discardedCardIds': discardedCardIds,
    'gameStartTime': gameStartTime.toIso8601String(),
    'lastAutoSaveTime': lastAutoSaveTime?.toIso8601String(),
    'gameStatus': gameStatus.index,
    'modifierFuelCost': modifierFuelCost,
    'modifierAttackRoll': modifierAttackRoll,
    'modifierEvasion': modifierEvasion,
    'modifierAltitudeCost': modifierAltitudeCost,
    'modifierTargetAcquisition': modifierTargetAcquisition,
    'modifierThreatDetermination': modifierThreatDetermination,
    'profileId': profileId,
    'scoringMode': scoringMode,
  };

  factory GameState.fromJson(Map<String, dynamic> json) => GameState(
    gameId: json['gameId'] as String,
    userId: json['userId'] as String,
    mode: GameMode.values[json['mode'] as int],
    scenarioId: json['scenarioId'] as String,
    turnNumber: json['turnNumber'] as int,
    drone: Drone.fromJson(json['drone'] as Map<String, dynamic>),
    currentBox: Box.values[json['currentBox'] as int],
    currentTarget: json['currentTarget'] != null 
        ? TargetCard.fromJson(json['currentTarget'] as Map<String, dynamic>) 
        : null,
    currentThreat: json['currentThreat'] != null 
        ? ThreatCard.fromJson(json['currentThreat'] as Map<String, dynamic>) 
        : null,
    destroyedTargets: (json['destroyedTargets'] as List)
        .map((t) => TargetCard.fromJson(t as Map<String, dynamic>))
        .toList(),
    discardedCardIds: (json['discardedCardIds'] as List).cast<String>(),
    gameStartTime: DateTime.parse(json['gameStartTime'] as String),
    lastAutoSaveTime: json['lastAutoSaveTime'] != null 
        ? DateTime.parse(json['lastAutoSaveTime'] as String) 
        : null,
    gameStatus: GameStatus.values[json['gameStatus'] as int],
    modifierFuelCost: json['modifierFuelCost'] as int? ?? 0,
    modifierAttackRoll: json['modifierAttackRoll'] as int? ?? 0,
    modifierEvasion: json['modifierEvasion'] as int? ?? 0,
    modifierAltitudeCost: json['modifierAltitudeCost'] as int? ?? 0,
    modifierTargetAcquisition: json['modifierTargetAcquisition'] as int? ?? 0,
    modifierThreatDetermination: json['modifierThreatDetermination'] as int? ?? 0,
    profileId: json['profileId'] as int?,
    scoringMode: json['scoringMode'] as String?,
  );

  GameState copyWith({
    String? gameId,
    String? userId,
    GameMode? mode,
    String? scenarioId,
    int? turnNumber,
    Drone? drone,
    Box? currentBox,
    TargetCard? currentTarget,
    ThreatCard? currentThreat,
    List<TargetCard>? destroyedTargets,
    List<String>? discardedCardIds,
    DateTime? gameStartTime,
    DateTime? lastAutoSaveTime,
    GameStatus? gameStatus,
    int? modifierFuelCost,
    int? modifierAttackRoll,
    int? modifierEvasion,
    int? modifierAltitudeCost,
    int? modifierTargetAcquisition,
    int? modifierThreatDetermination,
    int? profileId,
    String? scoringMode,
  }) => GameState(
    gameId: gameId ?? this.gameId,
    userId: userId ?? this.userId,
    mode: mode ?? this.mode,
    scenarioId: scenarioId ?? this.scenarioId,
    turnNumber: turnNumber ?? this.turnNumber,
    drone: drone ?? this.drone,
    currentBox: currentBox ?? this.currentBox,
    currentTarget: currentTarget ?? this.currentTarget,
    currentThreat: currentThreat ?? this.currentThreat,
    destroyedTargets: destroyedTargets ?? this.destroyedTargets,
    discardedCardIds: discardedCardIds ?? this.discardedCardIds,
    gameStartTime: gameStartTime ?? this.gameStartTime,
    lastAutoSaveTime: lastAutoSaveTime ?? this.lastAutoSaveTime,
    gameStatus: gameStatus ?? this.gameStatus,
    modifierFuelCost: modifierFuelCost ?? this.modifierFuelCost,
    modifierAttackRoll: modifierAttackRoll ?? this.modifierAttackRoll,
    modifierEvasion: modifierEvasion ?? this.modifierEvasion,
    modifierAltitudeCost: modifierAltitudeCost ?? this.modifierAltitudeCost,
    modifierTargetAcquisition: modifierTargetAcquisition ?? this.modifierTargetAcquisition,
    modifierThreatDetermination: modifierThreatDetermination ?? this.modifierThreatDetermination,
    profileId: profileId ?? this.profileId,
    scoringMode: scoringMode ?? this.scoringMode,
  );
}
