# Game Engine API Reference

> Internal API reference documenting every game mechanic in Drone Commander as a callable interface. This is a specification for the Senior Developer — not a user-facing API.

---

## Dice System

### `rollD6() → int`

Roll a single six-sided die.

- **Returns:** Integer in range `[1, 6]`
- **Rule:** Raw DR (Dice Roll) cannot exceed 6 or be less than 1

### `roll2D10() → int`

Roll two ten-sided dice and combine into a two-digit number.

- **First die** = ones digit, **second die** = tens digit
- **Returns:** Integer in range `[0, 99]` (displayed as `00`–`99`)
- **Examples:** Roll 2, 0 → `02`; Roll 2, 5 → `25`; Roll 0, 9 → `90`

### `applyDRM(baseRoll: int, modifiers: List<int>) → int`

Apply all DRM (Dice Roll Modifiers) to a base roll.

- **Returns:** `baseRoll + sum(modifiers)`
- **Rule:** DRM result CAN exceed 10 or go below 1 (unlike raw DR)

---

## Phase B0 — In Transit

### `checkComms(commsDamage: int, drone: Drone) → CommsResult`

Perform the COMMS controllability check. Called at B0 when returning from B5 with `commsDamage > 2`.

**Procedure:**
1. Roll 1D6
2. Apply DRM modifiers:
   - `−1` if drone has SATCOM
   - `−1` if drone has Comms System Redundancy
   - `−1` if drone has Autonomous DM AI
3. Consult COMMS Check Table

**Returns:**

| DRM Result | `CommsResult` | Effect |
|------------|---------------|--------|
| ≤ 2 | `ALL_OK` | Continue mission normally |
| 3, 4, 5 | `DEGRADED` | −1 to Drone Attack Dice Roll for this cycle |
| ≥ 6 | `UNCONTROLLABLE` | Drone destroyed — **game ends immediately** |

---

## Phase B1 — Search

### `changeAltitude(current: Altitude, target: Altitude, drone: Drone) → AltitudeResult`

Optional altitude change. Called at B1, B3, or **B4** (before attack execution).

- **Cost:** 2F per UP level, 1F per DOWN level
- **Validation:** Target altitude must be in `drone.altitude` (supported altitudes)
- **Returns:** `{newAltitude, fuelCost}`

### `drawCombatCard(deck: Stack<CombatCard>) → CombatCard`

Draw and execute a combat card. Called at **B1 only** (not B3).

- If deck is empty → reshuffle discard pile, place back face-up
- **Returns:** The drawn combat card
- **Side effects:** Execute card instructions (may modify DRM, fuel, or game state)

---

## Phase B3 — Positioning (IP)

B3 is an altitude-only positioning phase. **No combat card is drawn.**

### `advanceFromB3() → void`

Advance from B3 (IP) to B4 (Attack). The player may optionally change altitude before advancing.

- **No combat card draw** — this was removed from B3 to streamline gameplay
- **Resets:** attack mode, weapon selection

---

## Phase B2 — Target Acquisition & Threat Determination

### `acquireTarget(roll: int, commsDamage: int, drone: Drone, scenario: Scenario) → TargetCard`

Perform target acquisition. Called at B2.

**Procedure:**
1. Roll 2D10
2. Apply DRM modifiers:
   - `+10` if drone has AEASA Radar
   - `+10` if COMMS damage = 0
   - `−10` per each 1 point of COMMS damage
3. Consult Target Acquisition Table (may vary by scenario)
4. Draw top card from matching target type deck

**Default Target Acquisition Table:**

| Range | Target Type |
|-------|-------------|
| ≤ 18 | TRUCK |
| 19–35 | PERSONNEL |
| 35–45 | AFV |
| 46–55 | SAM |
| 56–70 | TANK |
| 71–79 | ARTILLERY |
| 80–91 | HQ/BUNKER |
| 91–99 | VIP |
| ≥ 100 | AERIAL TARGET |

**Fallback rule:** If no card of the matching type exists, try next **lower** range first, then next **higher**.

### `determineThreat(roll: int, vis: int, scenario: Scenario) → ThreatCard`

Perform threat determination. Called at B2.

**Procedure:**
1. Roll 2D10
2. Apply DRM: `+10` per each 2 points of VIS
3. Consult Threat Determination Table (may vary by scenario)
4. Draw top card from matching threat type deck

**Default Threat Determination Table:**

| Range | Threat Type |
|-------|-------------|
| ≤ 19 | Small Arms |
| 20–65 | AAA |
| 66–85 | SAM |
| 86–95 | CAP |
| ≥ 96 | Anti-Drone Weapon |

**Fallback rule:** Same as target acquisition (lower first, then higher).

**Deck exhaustion:** If all threat cards used but target cards remain and primary mission not accomplished → reshuffle used threat cards back into play.

---

## Phase B4 — Drone Attack

### `resolveAttack(params: AttackParams) → AttackResult`

Resolve a drone attack. Called at B4.

**`AttackParams`:**

```
{
  mode: Enum(STANDOFF, CLOSE_IN, FO_LAZE)
  weapon: Weapon
  altitude: Enum(VLOW, LOW, MEDIUM, HIGH)
  target: TargetCard
  sensorDamage: int
  combatCardDRM: int
  droneInfoDRM: int
  scenarioDRM: int
}
```

**Procedure:**
1. Validate attack mode vs altitude:
   - **Stand-Off**: MEDIUM or HIGH only
   - **Close-In**: VLOW or LOW only
   - **FO/Laze**: any altitude
2. Validate weapon type vs target type (engagement matrix):
   - **ATGM**: TRUCK, AFV, TANK, VIP only
   - **Guided Bomb**: all ground targets (not AIR)
   - **Cruise Missile**: SAM, HQ/BUNKER only
   - **Missile**: TRUCK, PERSONNEL, AFV, TANK, VIP only
   - **KIT**: all ground targets (not AIR)
3. Validate weapon vs attack mode (`fire_range` field):
   - `close` → Close-In only
   - `medium` / `far` → Stand-Off only
   - `close-medium` → both Close-In and Stand-Off
4. Validate weapon can fire at current altitude (`fire_altitude` field)
5. Roll 1D6
3. Sum DRM: loadout counter + combat card + drone info + target card + scenario
4. Apply column shifts: shift 1 RIGHT per 2 points of Sensor Damage
5. Clamp final DRM column to `[1, 6]`
6. Look up CRT cell at `[mode][altitude][drmColumn]`

**Returns:**

```
AttackResult {
  hit: bool
  fuelCost: int        // from CRT cell (1F, 2F, or 3F)
  weaponConsumed: Weapon
  targetDestroyed: bool // same as hit
}
```

**Post-attack:**
- If HIT → move target card to Destroyed pile, add VP
- If miss → move target card to Discard pile
- Remove used weapon from loadout
- Add `fuelCost` to cycle total (deducted at end of cycle)

### `resolveSAMReaction(vis: int, attackMode: AttackMode, altitude: Altitude) → SAMReactionResult`

Optional rule. Called after `resolveAttack` if target was a SAM type and attack **missed**.

**Procedure:**
1. Roll 1D6
2. Add VIS value as DRM
3. If final DRM ≥ 6 → SAM fires reaction shot
4. Consult SAM Special Counterfire Table
5. Apply column shifts: shift 1 LEFT per 2 points of VIS

**Returns:**

```
SAMReactionResult {
  samFired: bool
  damage: int          // 0 or 1D
  fuelCost: int        // 0, 1F, or 2F
  droneDestroyed: bool // if damage exceeds remaining integrity
}
```

---

## Phase B5 — Counterfire & Evasive Action

### `resolveEvasion(params: EvasionParams) → EvasionResult`

Resolve counterfire and evasive action. Called at B5.

**`EvasionParams`:**

```
{
  mode: Enum(STANDOFF, CLOSE_IN, FO_LAZE)
  altitude: Enum(VLOW, LOW, MEDIUM, HIGH)
  threat: ThreatCard
  vis: int
  combatCardDRM: int
  droneInfoDRM: int
  scenarioDRM: int
}
```

**Procedure:**
1. Roll 1D6 (if SAM optional rule was used, reuse that D6 roll)
2. Sum DRM: loadout counter + combat card + drone info + threat card + scenario
3. Apply column shifts: shift 1 LEFT per 2 points of VIS/RCS
4. Clamp final DRM column to `[1, 6]`
5. Look up CRT cell at `[mode][altitude][drmColumn]`

**Returns:**

```
EvasionResult {
  damage: int       // 0, 1D, or 2D
  fuelCost: int     // 0, 1F, or 2F
}
```

---

## Damage System

### `applyDamage(damage: int, state: GameState) → DamageResult`

Apply structural damage and cascade to sub-components. Called after any damage event.

**Cascade rules:**

| Step | Rule |
|------|------|
| 1 | `structural_integrity -= damage` |
| 2 | If `structural_integrity <= 0` → **drone destroyed** |
| 3 | For every 2 points of total SI damage (max - current) → `sensors_damage + 1` (max 9) |
| 4 | For every 3 points of total SI damage (max - current) → `comms_damage + 1` (max 5) |
| 5 | For every 1 point of new COMMS or Sensors damage → `vis_rcs + 1` |

**Sensors combat effect:** For every 4 points of Sensor Damage → −1 to Drone Attack Roll.

**Returns:**

```
DamageResult {
  newIntegrity: int
  newSensors: int
  newComms: int
  newVis: int
  droneDestroyed: bool
  attackDRMPenalty: int  // from sensors damage
}
```

---

## Fuel System

### `consumeFuel(amount: int, state: GameState) → FuelResult`

Consume fuel and check for forced RTB. Applies total fuel burned at **end of cycle only** (per spec).

**Fuel costs by source (accumulated during cycle):**

| Source | Cost |
|--------|------|
| B2 — Target/Threat phase entry | 1F |
| Altitude change (B1 or B3) | 2F per UP level, 1F per DOWN level |
| Attack CRT result | 1F / 2F / 3F (per cell) |
| Evasion CRT result | 0F / 1F / 2F (per cell) |
| Base burn rate | scenario-defined rate per cycle |
| Loadout with `(+)` marker | +2F per cycle |

**Returns:**

```
FuelResult {
  remainingFuel: int
  forcedRTB: bool  // true if remainingFuel <= 0
}
```

---

## Scoring

### `calculateScore(killRecords: List<KillRecord>) → int`

Sum VP from all target cards captured within the kill records.

- **Maximum Kill scoring**: Game ends when target deck is fully expanded
- **Quick Kill scoring**: Game ends when primary objective is completed

**Returns:** Total VP (integer).

---

## Loadout Validation

### `validateLoadout(drone: Drone, weapons: List<Weapon>, scenario: Scenario) → ValidationResult`

Validate a loadout configuration before game start.

**Rules:**
- Weapons with `(*A)` → only on Class A drones
- Weapons with `(*B)` → only on Class B+ drones
- Weapons with `(*C)` → only on Class C+ drones
- Weapons with `(*D)` → only on Class D+ drones
- Weapons with `(%)` → exclusive (no other weapon/KIT can be carried)
- Weapons with `(+)` → add +2F fuel burn per cycle

**Returns:**

```
ValidationResult {
  valid: bool
  errors: List<String>    // e.g. "Weapon X requires Class B+ drone"
  extraFuelPerCycle: int  // from (+) markers
}
```

---

## Card Deck Management

### `shuffleDeck(cards: List<Card>) → Stack<Card>`

Shuffle a list of cards into a randomized stack.

### `drawCard(deck: Stack<Card>) → Card?`

Draw the top card from a deck.

- If deck is empty:
  - **Combat cards:** Reshuffle discard pile, place back face-up → draw from top
  - **Target cards:** If all drawn → game ends (all targets expanded)
  - **Threat cards:** If all drawn but targets remain → reshuffle and place back into play

---

*API Reference version: 0.1.0 — Phase 0 (Foundation)*
*Last updated: 2026-03-10*
