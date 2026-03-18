import '../models/game_enums.dart';

/// Result of a CRT (Combat Resolution Table) lookup.
class CrtResult {
  const CrtResult({
    required this.fuelCost,
    this.damage = 0,
    this.isHit = false,
  });

  /// Fuel consumed by this action.
  final int fuelCost;

  /// Damage dealt (to drone in counterfire, ignored for attack).
  final int damage;

  /// Whether the attack hit (target destroyed).
  final bool isHit;

  /// No-effect result (dash in the table).
  static const CrtResult none = CrtResult(fuelCost: 0);

  @override
  String toString() =>
      'CrtResult(fuel=$fuelCost, damage=$damage, hit=$isHit)';
}

/// Combat Resolution Tables from the rulebook.
///
/// All tables are 3D: [AttackMode][Altitude][DRM column 1-6].
/// Column shifts are applied BEFORE lookup by adjusting the DRM column index.
class CombatResolution {
  CombatResolution._();

  // ---------------------------------------------------------------------------
  // DRONE ATTACK TABLE (§6.4.3)
  // Dimensions: [mode 0-2][altitude index 0-3][drm 0-5 (for columns 1-6)]
  //
  // VLOW row = index 0, LOW = 1, MEDIUM = 2, HIGH = 3
  // StandOff = 0, CloseIn = 1, FoLaze = 2
  // ---------------------------------------------------------------------------

  /// Resolve a drone attack.
  ///
  /// [mode] - attack mode selected by player.
  /// [altitude] - altitude at which attack is conducted.
  /// [rawDrm] - final DRM roll (1-6 from D6 + modifiers), clamped to 1-6.
  /// [sensorDamage] - current sensor damage for column right-shift.
  static CrtResult resolveAttack({
    required AttackMode mode,
    required Altitude altitude,
    required int rawDrm,
    int sensorDamage = 0,
  }) {
    // Clamp DRM to 1-6 (rulebook: DR cannot exceed 6 or be less than 1).
    int drm = rawDrm.clamp(1, 6);

    // Column shift: +1 RIGHT per 2 pts sensor damage → increases effective DRM.
    final rightShift = sensorDamage ~/ 2;
    drm = (drm + rightShift).clamp(1, 6);

    final altIdx = altitude.crtIndex;
    final modeIdx = mode.crtBlockIndex;

    return _attackTable[modeIdx][altIdx][drm - 1];
  }

  /// Attack CRT lookup table.
  /// [mode][altitude][drm-1]
  static final List<List<List<CrtResult>>> _attackTable = [
    // ---- Stand-Off (MEDIUM + HIGH only) ----
    [
      // VLOW: N/A (Stand-Off not available)
      _row(0, [false, false, false, false, false, false]),
      // LOW: N/A (Stand-Off not available)
      _row(0, [false, false, false, false, false, false]),
      // MEDIUM: 1F, hit on DRM 6
      _row(1, [false, false, false, false, false, true]),
      // HIGH: 1F, hit on DRM 5,6
      _row(1, [false, false, false, false, true, true]),
    ],
    // ---- Close-In (VLOW + LOW only) ----
    [
      // VLOW: 2F, hit on DRM 2,3,4,5,6
      _row(2, [false, true, true, true, true, true]),
      // LOW: 2F, hit on DRM 1,2,3
      _row(2, [true, true, true, false, false, false]),
      // MEDIUM: N/A (Close-In not available)
      _row(0, [false, false, false, false, false, false]),
      // HIGH: N/A (Close-In not available)
      _row(0, [false, false, false, false, false, false]),
    ],
    // ---- FO/Laze ----
    [
      // VLOW: 3F, hit on DRM 3,4,5,6
      _row(3, [false, false, true, true, true, true]),
      // LOW: 3F, hit on DRM 6
      _row(3, [false, false, false, false, false, true]),
      // MEDIUM: 3F, hit on DRM 1,2,3,4
      _row(3, [true, true, true, true, false, false]),
      // HIGH: 3F, hit on DRM 4,5,6
      _row(3, [false, false, false, true, true, true]),
    ],
  ];

  /// Helper: build a row of CrtResults with uniform fuel cost and per-column hit flags.
  static List<CrtResult> _row(int fuel, List<bool> hits) {
    return List.generate(6, (i) => CrtResult(fuelCost: fuel, isHit: hits[i]));
  }

  // ---------------------------------------------------------------------------
  // COUNTERFIRE & EVASIVE ACTION TABLE (§6.4.4)
  // ---------------------------------------------------------------------------

  /// Resolve counterfire/evasion.
  ///
  /// [mode] - attack mode used during the attack phase.
  /// [altitude] - current altitude.
  /// [rawDrm] - D6 roll + modifiers, clamped 1-6.
  /// [vis] - current VIS/RCS for column left-shift.
  /// [threatColumnShift] - column shift from threat card (positive = RIGHT, negative = LEFT).
  static CrtResult resolveCounterfire({
    required AttackMode mode,
    required Altitude altitude,
    required int rawDrm,
    int vis = 0,
    int threatColumnShift = 0,
  }) {
    int drm = rawDrm.clamp(1, 6);

    // Column shift: -1 LEFT per 2 pts VIS → decreases effective DRM column.
    final leftShift = vis ~/ 2;
    drm = (drm - leftShift + threatColumnShift).clamp(1, 6);

    final altIdx = altitude.crtIndex;
    final modeIdx = mode.crtBlockIndex;

    return _counterfireTable[modeIdx][altIdx][drm - 1];
  }

  /// D = damage, F = fuel. Format from table: "—" = none, "1D+1F", "2D+F", etc.
  static final List<List<List<CrtResult>>> _counterfireTable = [
    // ---- Stand-Off (MEDIUM + HIGH only) ----
    [
      _noneRow(), // VLOW: N/A
      _noneRow(), // LOW: N/A
      // MEDIUM: DRM 1-4=safe, DRM 5=1D+1F, DRM 6=safe
      [CrtResult.none, CrtResult.none, CrtResult.none, CrtResult.none, const CrtResult(fuelCost: 1, damage: 1), CrtResult.none],
      // HIGH: DRM 1-4=safe, DRM 5,6=1D+2F
      [CrtResult.none, CrtResult.none, CrtResult.none, CrtResult.none, const CrtResult(fuelCost: 2, damage: 1), const CrtResult(fuelCost: 2, damage: 1)],
    ],
    // ---- Close-In (VLOW + LOW only) ----
    [
      // VLOW: DRM 1-3=safe, DRM 4,5=3D+2F, DRM 6=safe
      [CrtResult.none, CrtResult.none, CrtResult.none, const CrtResult(fuelCost: 2, damage: 3), const CrtResult(fuelCost: 2, damage: 3), CrtResult.none],
      // LOW: DRM 1-3=safe, DRM 4=2D+1F, DRM 5,6=safe
      [CrtResult.none, CrtResult.none, CrtResult.none, const CrtResult(fuelCost: 1, damage: 2), CrtResult.none, CrtResult.none],
      // MEDIUM: N/A (Close-In not available)
      _noneRow(),
      // HIGH: N/A (Close-In not available)
      _noneRow(),
    ],
    // ---- FO/Laze ----
    [
      // VLOW: DRM 1-5=safe, DRM 6=1D+1F
      [CrtResult.none, CrtResult.none, CrtResult.none, CrtResult.none, CrtResult.none, const CrtResult(fuelCost: 1, damage: 1)],
      // LOW: DRM 1-5=safe, DRM 6=1D+1F
      [CrtResult.none, CrtResult.none, CrtResult.none, CrtResult.none, CrtResult.none, const CrtResult(fuelCost: 1, damage: 1)],
      // MEDIUM: DRM 1-6=1D+1F
      [const CrtResult(fuelCost: 1, damage: 1), const CrtResult(fuelCost: 1, damage: 1), const CrtResult(fuelCost: 1, damage: 1), const CrtResult(fuelCost: 1, damage: 1), const CrtResult(fuelCost: 1, damage: 1), const CrtResult(fuelCost: 1, damage: 1)],
      // HIGH: DRM 1-3=safe, DRM 4,5,6=1D+1F
      [CrtResult.none, CrtResult.none, CrtResult.none, const CrtResult(fuelCost: 1, damage: 1), const CrtResult(fuelCost: 1, damage: 1), const CrtResult(fuelCost: 1, damage: 1)],
    ],
  ];

  static List<CrtResult> _noneRow() => List.filled(6, CrtResult.none);

  // ---------------------------------------------------------------------------
  // SAM SPECIAL COUNTERFIRE TABLE (§6.4.3.1)
  // ---------------------------------------------------------------------------

  /// Resolve SAM reaction shot (only when attack misses a SAM target).
  ///
  /// [vis] shifts column LEFT (opposite direction from normal counterfire).
  static CrtResult resolveSamCounterfire({
    required AttackMode mode,
    required Altitude altitude,
    required int rawDrm,
    int vis = 0,
  }) {
    int drm = rawDrm.clamp(1, 6);

    // SAM table: shift 1 LEFT per 2 pts VIS
    final leftShift = vis ~/ 2;
    drm = (drm - leftShift).clamp(1, 6);

    final altIdx = altitude.crtIndex;
    final modeIdx = mode.crtBlockIndex;

    return _samCounterfireTable[modeIdx][altIdx][drm - 1];
  }

  static final List<List<List<CrtResult>>> _samCounterfireTable = [
    // ---- Stand-Off ----
    [
      _noneRow(), // VLOW
      _noneRow(), // LOW
      _noneRow(), // MEDIUM
      // HIGH: DRM 1-5=safe, DRM 6=1D+2F
      [CrtResult.none, CrtResult.none, CrtResult.none, CrtResult.none, CrtResult.none, const CrtResult(fuelCost: 2, damage: 1)],
    ],
    // ---- Close-In ----
    [
      _noneRow(), // VLOW
      _noneRow(), // LOW
      // MEDIUM: DRM 1-5=safe, DRM 6=1D+1F
      [CrtResult.none, CrtResult.none, CrtResult.none, CrtResult.none, CrtResult.none, const CrtResult(fuelCost: 1, damage: 1)],
      // HIGH: DRM 1-4=safe, DRM 5,6=1D+1F
      [CrtResult.none, CrtResult.none, CrtResult.none, CrtResult.none, const CrtResult(fuelCost: 1, damage: 1), const CrtResult(fuelCost: 1, damage: 1)],
    ],
    // ---- FO/Laze ----
    [
      _noneRow(), // VLOW
      _noneRow(), // LOW
      // MEDIUM: DRM 1-4=safe, DRM 5,6=1D+1F
      [CrtResult.none, CrtResult.none, CrtResult.none, CrtResult.none, const CrtResult(fuelCost: 1, damage: 1), const CrtResult(fuelCost: 1, damage: 1)],
      // HIGH: DRM 1-4=safe, DRM 5,6=1D+1F
      [CrtResult.none, CrtResult.none, CrtResult.none, CrtResult.none, const CrtResult(fuelCost: 1, damage: 1), const CrtResult(fuelCost: 1, damage: 1)],
    ],
  ];

  // ---------------------------------------------------------------------------
  // COMMS CHECK TABLE (§6.4.5.3)
  // ---------------------------------------------------------------------------

  /// Resolve a COMMS controllability check at B0.
  ///
  /// [drm] = D6 roll + comms damage + capability reductions.
  /// Returns: 0 = all OK, 1 = controllable with -1 attack penalty, 2 = destroyed.
  static int resolveCommsCheck(int drm) {
    if (drm <= 2) return 0;       // All OK
    if (drm <= 5) return 1;       // Controllable with difficulty: -1 attack
    return 2;                     // Uncontrollable — drone destroyed
  }
}
