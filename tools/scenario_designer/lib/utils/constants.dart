// Game constants and enums
class GameConstants {
  // Box names
  static const String boxStart = 'START';
  static const String boxSearch = 'SEARCH';
  static const String boxTargetAcq = 'TARGET ACQUISITION';
  static const String boxPositioning = 'POSITIONING TO ATTACK';
  static const String boxAttack = 'ATTACK';
  static const String boxEvasion = 'EVASION';
  static const String boxBase = 'BASE';

  // Game timing
  static const int maxInitializationTimeMs = 3000;

  // Damage limits
  static const int maxSensorsDamage = 9;
  static const int maxCommsDamage = 5;

  // Fuel thresholds
  static const int fuelCrisisThreshold = 5;

  // Dice ranges
  static const int d6Min = 1;
  static const int d6Max = 6;
  static const int d10Min = 0;
  static const int d10Max = 9;
}

// Box enum
enum Box {
  b0Start,
  b1Search,
  b2TargetAcq,
  b3Positioning,
  b4Attack,
  b5Evasion,
  b6Base;

  String get displayName {
    switch (this) {
      case Box.b0Start:
        return GameConstants.boxStart;
      case Box.b1Search:
        return GameConstants.boxSearch;
      case Box.b2TargetAcq:
        return GameConstants.boxTargetAcq;
      case Box.b3Positioning:
        return GameConstants.boxPositioning;
      case Box.b4Attack:
        return GameConstants.boxAttack;
      case Box.b5Evasion:
        return GameConstants.boxEvasion;
      case Box.b6Base:
        return GameConstants.boxBase;
    }
  }

  int get fuelCost {
    switch (this) {
      case Box.b0Start:
        return 0;
      case Box.b1Search:
        return 1;
      case Box.b2TargetAcq:
        return 1;
      case Box.b3Positioning:
      case Box.b4Attack:
      case Box.b5Evasion:
      case Box.b6Base:
        return 0;
    }
  }

  Box? get next {
    final nextIndex = index + 1;
    return nextIndex < Box.values.length ? Box.values[nextIndex] : null;
  }

  bool canTransitionTo(Box other) => other.index == index + 1;
}

// Drone enums
enum DroneClass { a, b, c, d }

enum Altitude {
  vlow,
  low,
  medium,
  high;

  String get displayName {
    switch (this) {
      case Altitude.vlow:
        return 'VLOW';
      case Altitude.low:
        return 'LOW';
      case Altitude.medium:
        return 'MEDIUM';
      case Altitude.high:
        return 'HIGH';
    }
  }

  /// Ordinal index: VLOW=0, LOW=1, MEDIUM=2, HIGH=3
  int get ordinal => index;

  /// Fuel cost to change FROM this altitude TO [target].
  /// +1 level = 2 fuel, -1 level = 1 fuel per step.
  int fuelCostTo(Altitude target) {
    final diff = target.ordinal - ordinal;
    if (diff == 0) return 0;
    if (diff > 0) return diff * 2; // climbing
    return diff.abs() * 1; // descending
  }

  /// Parse altitude string from DB (e.g. 'VLOW', 'LOW', 'MEDIUM', 'HIGH').
  static Altitude fromString(String s) {
    switch (s.trim().toUpperCase()) {
      case 'VLOW':
        return Altitude.vlow;
      case 'LOW':
        return Altitude.low;
      case 'MEDIUM':
        return Altitude.medium;
      case 'HIGH':
        return Altitude.high;
      default:
        return Altitude.low;
    }
  }

  /// Parse a comma-separated altitude list from DB (e.g. 'VLOW, LOW, MEDIUM').
  static List<Altitude> parseList(String s) {
    return s.split(',').map((e) => fromString(e.trim())).toList();
  }

  /// Get the highest altitude from a comma-separated DB string.
  static Altitude maxFromString(String s) {
    final list = parseList(s);
    return list.reduce((a, b) => a.ordinal > b.ordinal ? a : b);
  }
}

enum DroneStatus {
  operational,
  damaged,
  critical,
  destroyed;

  String get displayName {
    switch (this) {
      case DroneStatus.operational:
        return 'Operational';
      case DroneStatus.damaged:
        return 'Damaged';
      case DroneStatus.critical:
        return 'Critical';
      case DroneStatus.destroyed:
        return 'Destroyed';
    }
  }
}

// Game mode enums
enum GameMode {
  solitaire,
  campaign,
  scenario,
  multiplayer;

  String get displayName {
    switch (this) {
      case GameMode.solitaire:
        return 'Solitaire';
      case GameMode.campaign:
        return 'Campaign';
      case GameMode.scenario:
        return 'Scenario';
      case GameMode.multiplayer:
        return 'Multiplayer';
    }
  }
}

enum GameStatus {
  active,
  paused,
  complete,
  failed,
  aborted;

  String get displayName {
    switch (this) {
      case GameStatus.active:
        return 'Active';
      case GameStatus.paused:
        return 'Paused';
      case GameStatus.complete:
        return 'Complete';
      case GameStatus.failed:
        return 'Failed';
      case GameStatus.aborted:
        return 'Aborted';
    }
  }
}

/// Sprint 5 (B-01/B-02): Reason a mission ended.
/// Sprint RTB: Added voluntaryRtb, fuelZeroRtb, crash.
enum MissionEndReason {
  missionComplete,
  fuelExhausted,
  commsLost,
  droneDestroyed,
  aborted,
  voluntaryRtb,
  fuelZeroRtb,
  crash;

  String get displayName {
    switch (this) {
      case MissionEndReason.missionComplete:
        return 'Mission Complete';
      case MissionEndReason.fuelExhausted:
        return 'Fuel Exhausted';
      case MissionEndReason.commsLost:
        return 'COMMS Lost';
      case MissionEndReason.droneDestroyed:
        return 'Drone Destroyed';
      case MissionEndReason.aborted:
        return 'Mission Aborted';
      case MissionEndReason.voluntaryRtb:
        return 'Voluntary Return to Base';
      case MissionEndReason.fuelZeroRtb:
        return 'Fuel Depleted — Mandatory Return';
      case MissionEndReason.crash:
        return 'Drone Crashed — Fuel Depletion';
    }
  }

  bool get isSuccess => this == MissionEndReason.missionComplete;
  bool get isRtb => this == MissionEndReason.voluntaryRtb || this == MissionEndReason.fuelZeroRtb;
  bool get isCrash => this == MissionEndReason.crash || this == MissionEndReason.droneDestroyed;
}

// Attack mode enums
enum AttackMode {
  standoff,
  closeIn,
  foLaze;

  String get displayName {
    switch (this) {
      case AttackMode.standoff:
        return 'Standoff';
      case AttackMode.closeIn:
        return 'Close-in';
      case AttackMode.foLaze:
        return 'FO-Laze';
    }
  }
}

// Card enums
enum TargetCardType {
  truck,
  personnel,
  afv,
  sam,
  tank,
  artillery,
  hqBunker,
  vip,
  aerial,
  engineer;

  String get displayName {
    switch (this) {
      case TargetCardType.truck:
        return 'Truck';
      case TargetCardType.personnel:
        return 'Personnel';
      case TargetCardType.afv:
        return 'AFV';
      case TargetCardType.sam:
        return 'SAM';
      case TargetCardType.tank:
        return 'Tank';
      case TargetCardType.artillery:
        return 'Artillery';
      case TargetCardType.hqBunker:
        return 'HQ/Bunker';
      case TargetCardType.vip:
        return 'VIP';
      case TargetCardType.aerial:
        return 'Aerial';
      case TargetCardType.engineer:
        return 'Engineer';
    }
  }
}

enum ThreatCardType {
  smallArms,
  aaa,
  sam,
  cap,
  antiDrone;

  String get displayName {
    switch (this) {
      case ThreatCardType.smallArms:
        return 'Small Arms';
      case ThreatCardType.aaa:
        return 'AAA';
      case ThreatCardType.sam:
        return 'SAM';
      case ThreatCardType.cap:
        return 'CAP';
      case ThreatCardType.antiDrone:
        return 'Anti-Drone';
    }
  }
}

enum CardStatus { inDeck, current, destroyed, discarded }

// Dice roll types
enum RollType {
  d6,
  d10x2;

  String get displayName {
    switch (this) {
      case RollType.d6:
        return '1D6';
      case RollType.d10x2:
        return '2D10';
    }
  }
}

// Exceptions
class GameException implements Exception {
  final String message;
  GameException(this.message);

  @override
  String toString() => 'GameException: $message';
}

class GameBoardException extends GameException {
  GameBoardException(super.message);
}

class TurnException extends GameException {
  TurnException(super.message);
}

class DroneException extends GameException {
  DroneException(super.message);
}

class GameInitializationException extends GameException {
  GameInitializationException(super.message);
}
