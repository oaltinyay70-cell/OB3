// Core enums for the OB3 Drone Commander game engine.

/// Drone altitude levels (4 levels per Q9 clarification).
enum Altitude {
  vlow,
  low,
  medium,
  high;

  /// Index used for CRT table lookups (0-based).
  int get crtIndex => index;

  /// Calculates fuel cost to change to a target altitude.
  /// PRD §4.2/§6.2: Ascending costs 2F per level, descending costs 1F per level.
  int fuelCostTo(Altitude target) {
    if (this == target) return 0;
    // index is 0=VLOW, 1=LOW, 2=MEDIUM, 3=HIGH
    final levels = (target.index - index).abs();
    if (target.index > index) {
      return levels * 2; // 2F per level UP
    }
    return levels * 1; // 1F per level DOWN
  }

  /// Parse comma-separated altitude string from DB (e.g. "LOW, MEDIUM, HIGH").
  static List<Altitude> parseFromDb(String? raw) {
    if (raw == null || raw.trim().isEmpty) return [Altitude.low];
    return raw
        .split(',')
        .map((s) => s.trim().toUpperCase())
        .map((s) => switch (s) {
              'VLOW' => Altitude.vlow,
              'LOW' => Altitude.low,
              'MEDIUM' => Altitude.medium,
              'HIGH' => Altitude.high,
              _ => null,
            })
        .whereType<Altitude>()
        .toList();
  }
}

/// Drone size class (A=heavy … D=micro).
enum DroneClass {
  a('A', 'Heavy/Large'),
  b('B', 'Medium'),
  c('C', 'Small'),
  d('D', 'Micro');

  const DroneClass(this.code, this.label);
  final String code;
  final String label;

  static DroneClass fromDb(String? raw) {
    if (raw == null) return DroneClass.b;
    return DroneClass.values.firstWhere(
      (e) => e.code == raw.trim().toUpperCase(),
      orElse: () => DroneClass.b,
    );
  }
}

/// Attack mode selection at B4.
enum AttackMode {
  standOff('Stand-Off'),
  closeIn('Close-In'),
  foLaze('FO/Laze');

  const AttackMode(this.label);
  final String label;

  /// CRT column block index (0=StandOff, 1=CloseIn, 2=FoLaze).
  int get crtBlockIndex => index;
}

/// Game phase state machine (B0 through B6 + gameOver).
enum GamePhase {
  setup('Setup'),
  b0InTransit('B0 — In Transit'),
  b1Search('B1 — Search'),
  b2TargetAcq('B2 — Target Acquisition'),
  b3Positioning('B3 — Positioning'),
  b4Attack('B4 — Drone Attack'),
  b5Evasion('B5 — Evasive Action'),
  b6Base('B6 — Base'),
  gameOver('Game Over');

  const GamePhase(this.label);
  final String label;
}

/// Target card sub-categories matching DB sub_category values.
enum TargetType {
  truck('TRUCK'),
  personnel('PERSONNEL'),
  afv('AFV'),
  sam('SAM'),
  tank('TANK'),
  artillery('ARTILLERY'),
  hqBunker('HQ-BUNKER'),
  vip('VIP'),
  air('AIR'),
  engineer('ENGINEER');

  const TargetType(this.dbValue);
  final String dbValue;

  static TargetType fromDb(String raw) {
    return TargetType.values.firstWhere(
      (e) => e.dbValue == raw.trim().toUpperCase(),
      orElse: () => TargetType.truck,
    );
  }
}

/// Threat card sub-categories matching DB sub_category values.
enum ThreatType {
  smallArms('SMALL ARMS'),
  aaa('AAA'),
  sam('SAM'),
  cap('CAP'),
  droneGun('DRONE GUN');

  const ThreatType(this.dbValue);
  final String dbValue;

  static ThreatType fromDb(String raw) {
    return ThreatType.values.firstWhere(
      (e) => e.dbValue == raw.trim().toUpperCase(),
      orElse: () => ThreatType.smallArms,
    );
  }
}

/// Weapon type categories from DB wpn_type.
enum WeaponType {
  atgm('ATGM'),
  cruiseMissile('Cruise Missile'),
  guidedBomb('Guided Bomb'),
  kit('KIT'),
  missile('Missile');

  const WeaponType(this.dbValue);
  final String dbValue;

  static WeaponType fromDb(String raw) {
    return WeaponType.values.firstWhere(
      (e) => e.dbValue.toUpperCase() == raw.trim().toUpperCase(),
      orElse: () => WeaponType.atgm,
    );
  }

  /// Weapon Type vs Target Type engagement matrix (PRD §4.8.4).
  ///
  /// Returns true if this weapon type can legally engage the given target type.
  /// If the matrix says ❌, the weapon is greyed out in the B4 weapon list.
  bool canEngage(TargetType target) {
    return switch (this) {
      WeaponType.atgm => const {
          TargetType.truck,
          TargetType.afv,
          TargetType.tank,
          TargetType.vip,
        }.contains(target),

      WeaponType.guidedBomb => const {
          TargetType.truck,
          TargetType.personnel,
          TargetType.afv,
          TargetType.sam,
          TargetType.tank,
          TargetType.artillery,
          TargetType.hqBunker,
          TargetType.vip,
          TargetType.engineer,
        }.contains(target),

      WeaponType.cruiseMissile => const {
          TargetType.sam,
          TargetType.hqBunker,
        }.contains(target),

      WeaponType.missile => const {
          TargetType.truck,
          TargetType.personnel,
          TargetType.afv,
          TargetType.tank,
          TargetType.vip,
        }.contains(target),

      WeaponType.kit => const {
          TargetType.truck,
          TargetType.personnel,
          TargetType.afv,
          TargetType.sam,
          TargetType.tank,
          TargetType.artillery,
          TargetType.hqBunker,
          TargetType.vip,
          TargetType.engineer,
        }.contains(target),
    };
  }
}

/// Scoring mode for end-of-game.
enum ScoringMode {
  maximumKill,
  quickKill;

  static ScoringMode fromDb(String? raw) {
    if (raw == null) return ScoringMode.maximumKill;
    return raw.toUpperCase().contains('QUICK')
        ? ScoringMode.quickKill
        : ScoringMode.maximumKill;
  }
}
