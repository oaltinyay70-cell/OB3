# Drone Commander — Functional Specification
**Agent**: OB3-ProjectManager | **Version**: 1.0 | **Date**: 2026-03-10
**Status**: DRAFT — Pending COMMANDER review

---

## 1. Project Overview

**Product**: Drone Commander — iOS mobile game (Flutter)
**Goal**: Digitize the Drone Commander board game as a single-player iOS game
**Scope (v1.0)**: Quick Game mode only (Campaign deferred to v1.1)
**Theme**: Military / MILSTD dark intelligence dashboard

---

## 2. Game Structure

### 2.1 Hierarchy
```
Quick Game
└── Scenario (1 per session)
    └── Cycles (unlimited until end condition)
        └── B0 → B1 → B2 → B3 → B4 → B5 → (back to B0)
```

### 2.2 Scenario End Conditions
A scenario ends when ANY of these occur:
1. **Drone destroyed** — SI reaches 0
2. **Primary objectives completed** — game prompts "RTB?"
3. **Player voluntarily RTBs** — at B2/B5 decision point
4. **Fuel exhausted** — forced RTB
After any end condition → **Post-Scenario Briefing screen** is displayed.

### 2.3 Campaign Rules (v1.1 only — out of scope)
- Scenarios play in sequential order, no skipping

### 2.4 Deck Composition
- **Triple-Deck System**: Each scenario uses three independent card pools: Combat, Target, and Threat.
- **DB-Driven**: Composition (IDs and counts) is stored in the database per scenario.
- **Duplicate Support**: Designers can include multiple copies of any card in a deck.
- **Randomization**: Independent shuffling of each deck occurs at scenario initialization.

---

## 3. Screens (Required for v1.0)

| # | Screen | Trigger |
|---|--------|---------|
| 1 | Main Menu | App launch |
| 2 | Drone Selection | New game |
| 3 | Loadout Selection | After drone picked |
| 4 | Game Screen | After loadout confirmed |
| 5 | Post-Scenario Briefing | After scenario ends |
| 6 | Settings | Menu |

---

## 4. Drone Selection Screen

### 4.1 Data Source
SQLite: `ob3.db`, table: `drones` (28 rows)

### 4.2 Per-Drone Display
- Name, country flag, drone class
- Altitude range (e.g., LOW/MEDIUM/HIGH)
- Endurance hours (= starting fuel)
- Structural Integrity value
- Special abilities (AEASA Radar, SATCOM, Autonomous AI, built-in FO/Laze)

### 4.3 All 28 Drones
| ID | Name | Endurance (h) | SI |
|----|------|:---:|:---:|
| 1 | Bayraktar TB2 | 27 | 80 |
| 2 | Bayraktar Akıncı | 24 | 225 |
| 3 | Aksungur | 50 | 175 |
| 4 | Anka-S | 30 | 125 |
| 5 | Wing Loong II | 20 | 195 |
| 6 | Wing Loong-3 | 40 | 240 |
| 7 | CH-4B | 40 | 110 |
| 8 | CH-5 | 60 | 175 |
| 9 | TB-001 Scorpion | 35 | 160 |
| 10 | MQ-9 Reaper | 27 | 210 |
| 11 | MQ-9B Protector | 40 | 225 |
| 12 | Avenger (Predator C) | 20 | 275 |
| 13 | MQ-1C Gray Eagle | 40 | 120 |
| 14 | Heron TP | 40 | 220 |
| 15 | Hermes 450 | 20 | 70 |
| 16 | Hermes 900 | 36 | 105 |
| 17 | Orion (Inokhodets) | 24 | 95 |
| 18 | S-70 Okhotnik-B | 20 | 425 |
| 19 | Altius-RU | 48 | 235 |
| 20 | Mohajer-6 | 12 | 75 |
| 21 | Mohajer-10 | 24 | 140 |
| 22 | Shahed-129 | 24 | 100 |
| 23 | Burraq | 10 | 65 |
| 24 | nEUROn | 3 | 250 |
| 25 | Taranis | 5 | 270 |
| 26 | Ghatak | 12 | 370 |
| 27 | Eurodrone | 40 | 315 |
| 28 | Falco Xplorer | 24 | 110 |

---

## 5. Loadout Selection Screen

### 5.1 Rules
- Player selects weapons AND optional sensor kits to fill available loadout slots
- Sensor kits occupy loadout slots (same as weapons — compete for space)
- Loadout choices affect DRM modifiers in game

### 5.2 Data Source
SQLite: `loadouts` table, linked to `drones` by drone_id

---

## 6. Game Screen

### 6.1 Starting State
- Drone starts at **MEDIUM altitude**
- Fuel = starting endurance hours value (e.g., TB2 = 27)
- SI = drone's max SI value (e.g., TB2 = 80)
- Sensor damage = 0, COMMS damage = 0, VIS/RCS = starting value per drone

### 6.2 Game Cycle (B0 → B5 → End-of-Loop)

> [!IMPORTANT]
> **UX Display Names:** The mobile app UI displays military phase names instead of B0–B5. Docs and code use B0–B5 internally.

| Internal | App Display Name | Military Meaning |
|:--------:|:----------------|:-----------------|
| B0 | **INGRESS** | Approach to target area |
| B1 | **RECON** | Reconnaissance / sensor sweep |
| B2 | **CONTACT** | Enemy detected |
| B3 | **IP** | Initial Point — attack run begins |
| B4 | **WEAPONS HOT** | Weapons release authorized |
| B5 | **EGRESS** | Departing target area / evasion |

#### B0 — In Transit
- COMMS check if damage > 2 (uncontrollable = destroyed)
- No decisions

#### B1 — Search
- Optional: change height (free action)
- **Draw Combat Card**: This is the **only time and place** a combat card is mandatorily drawn from its deck. One per cycle. Executes immediately. Does not redraw if returning via Retreat.

#### B2 — Target Acquisition / Threat Determination
- Spend 1F
- Draw **Target Card** + **Threat Card** together from DB
- Target kill resolution: dice roll displayed (e.g. `Roll: 14 — Hit!`)
- On kill: VP banked immediately, kill list appended
- On miss: continue to threat
- Objectives checked after every kill
- **Primary complete prompt**: RTB or Continue (shown once)
- **Commander decision**: Engage or retreat (discard both → back to B1)

#### B3 — Positioning
- Optional: change height (free action)

#### B4 — Drone Attack
- **Step 1**: Select height — altitude bar unlocked, player can change altitude (2F↑ / 1F↓)
- **Step 2**: Select weapon — filtered by altitude compatibility AND weapon type vs target type engagement matrix:
  - **ATGM**: TRUCK, AFV, TANK, VIP only
  - **Guided Bomb**: all ground targets (not AIR)
  - **Cruise Missile**: SAM, HQ/BUNKER only
  - **Missile**: TRUCK, PERSONNEL, AFV, TANK, VIP only
  - **KIT (FO/Laze)**: all ground targets (not AIR)
  - Incompatible weapons greyed out (35% opacity)
- **Step 3**: Select attack mode — buttons highlighted green if available at current altitude:
  - **Stand-Off**: MEDIUM, HIGH only
  - **Close-In**: VLOW, LOW only
  - **FO/Laze**: any altitude
  - `fire_range` field determines weapon-mode compatibility: `close` → Close-In, `medium`/`far` → Stand-Off, `close-medium` → both
- **Weapon enforcement:** if target is an objective target with `weapon_required`, only show matching weapons; warn if not loaded
- Roll 1D6 + DRM → consult Attack CRT → VP banked if hit
- **Target Card DRM**: effective only for attacking that specific target (applied at B4 resolution only)
- **After kill:** `ObjectiveEvaluator.evaluate()` called immediately → update `objectiveStatus`
- If primary objective transitions to COMPLETE → mission success sequence
- SAM counterfire check if target was SAM

#### B5 — Evasive Action (EGRESS)
- **Attack result display**: show HIT/MISS result from B4 before evasion
- Resolve Threat Card drawn at B2 — **unless otherwise stated, threat card effects are effective only for the counterfire in the current cycle**
- Evasion roll 1D6 + DRM
- **Counterfire result display**: show damage/no-damage result
- Damage = **combat card modifier × height modifier**
- Drone destroyed (SI=0) → scenario ends immediately

#### End-of-Loop Check (strict order)
1. Drone destroyed? → Post-scenario briefing
2. Fuel exhausted? → Post-scenario briefing
3. Player RTB? → Post-scenario briefing
4. All clear → Deduct fuel, clear combat card modifier, increment cycle, → B0

### 6.3 Damage System

#### Structural Integrity (SI)
- Range: 0 to drone's max SI
- If SI = 0 → drone destroyed → scenario ends

#### Sensor Damage
- For every 2 points of SI damage → raise Sensor damage level by 1
- Max sensor damage: 9 (regardless of SI damage)
- Every 4 points of sensor damage → -1 to Attack Combat Roll
- Optional Sensor Kits DO NOT take damage (external kit, not body)

#### COMMS Damage
- TBD (awaiting rulebook input)

#### VIS/RCS
- Starts at drone's default value (same starting level for all drones in v1.0)
- 4 levels: VLOW, LOW, MEDIUM, HIGH

### 6.4 Altitude Levels
4 levels: **VLOW / LOW / MEDIUM / HIGH**
(Starting altitude: MEDIUM)

### 6.5 Fuel Display (= Endurance)
- Fuel IS endurance. Displayed as **"FUEL"** on screen
- **Color bar** (NO numeric value shown to player):
  - 🟢 Green: 75–100%
  - 🔵 Blue: 40–75%
  - 🟠 Orange: 10–40%
  - 🔴 Red: 0–10%
- **Depletion**: base rate per cycle + height modifier + combat card modifier. Applied at **end of each cycle only**
- **No score value** — remaining fuel at RTB/end has zero impact on VP

### 6.6 Attack Modes
| Mode | Fuel Cost | Allowed Altitudes | Notes |
|------|-----------|-------------------|-------|
| Stand-Off | 1F | **MEDIUM, HIGH** only | Lowest risk |
| Close-In | 2F | **VLOW, LOW** only | Higher risk, higher damage |
| FO/Laze | 3F | Any altitude | Calls external fire support |

### 6.6.1 fire_range = Attack Mode Indicator

The `fire_range` DB field determines which attack modes a weapon supports:

| fire_range value | Allowed Attack Modes |
|------------------|---------------------|
| `close` | Close-In only |
| `medium` or `far` | Stand-Off only |
| `close-medium` | **Both** Close-In and Stand-Off |

### 6.6.2 Weapon Type vs Target Type Matrix

| Weapon Type | TRUCK | PERS | AFV | SAM | TANK | ARTY | HQ/BKR | VIP | AIR | ENGR |
|-------------|:-----:|:----:|:---:|:---:|:----:|:----:|:------:|:---:|:---:|:----:|
| **ATGM** | ✅ | ❌ | ✅ | ❌ | ✅ | ❌ | ❌ | ✅ | ❌ | ❌ |
| **Guided Bomb** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ | ✅ |
| **Cruise Missile** | ❌ | ❌ | ❌ | ✅ | ❌ | ❌ | ✅ | ❌ | ❌ | ❌ |
| **Missile** | ✅ | ✅ | ✅ | ❌ | ✅ | ❌ | ❌ | ✅ | ❌ | ❌ |
| **KIT** (FO/Laze) | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ | ✅ |

### 6.7 CRT Tables
> [!CAUTION]
> **DILEK CLEARANCE ITEMS (unresolved)**:
> - LOW row: Stand-Off & Close-In counterfire cells are empty — need correct values
> - LOW row: SAM counterfire — some SAMs should hit at LOW (fix needed)
> - VLOW row: Not in original rulebook — values TBD from COMMANDER

---

## 7. Post-Scenario Briefing Screen

Mandatory — displayed after every scenario end (no code path skips it).

| Section | Content |
|---------|---------|
| Termination Reason | `Drone Destroyed` / `Fuel Exhausted` / `RTB` |
| Objectives Checklist | Primary + secondary objectives: ACHIEVED or FAILED |
| Kill List | Ordered list of confirmed kills |
| VP Breakdown | VP per kill. Secondary VP flagged, shown as 0 if primary not met |
| Total Scenario VP | Sum of eligible VP (secondary excluded if primary failed) |
| Campaign Advancement | ADVANCE or LOCKED (hidden for standalone scenarios) |

---

## 8. Special Abilities

| Ability | Effect |
|---------|--------|
| AEASA Radar | +10 DRM on Target Acquisition |
| SATCOM | -1 to COMMS check DRM |
| Autonomous AI | -1 to COMMS check DRM |
| Built-in FO/Laze | Can FO/Laze without special kit (TBD — awaiting G4 answer) |

---

## 9. Open Items

| Ref | Item | Status |
|-----|------|--------|
| A1-A3 | VLOW CRT table values | ⚠️ Deferred (no VLOW drones in v1.0) |
| A4 | Which drones fly VLOW | ✅ None. Reserved for future. |
| B2 | Fuel consumption rate (1F = X hours?) | ❌ Open |
| C1-C3 | Combat card deck contents | ❌ Open |
| D1-D2 | Scenario definitions for v1.0 | ❌ Open |
| E1 | VP values (on target cards or chart?) | ❌ Open |
| E2 | Rank/rating system | ❌ Open |
| E3 | Post-Scenario Briefing content | ✅ 6 sections defined |
| F1-F2 | FO/Laze mechanics | ❌ Open |
| G1-G4 | Drone special abilities details | ❌ Open |
| H1 | Re-arm mid-scenario | ❌ Open |
| H2 | Altitude changes per turn | ❌ Open (height = free action, but limits?) |
| H3 | SI values per drone | ✅ All 28 updated in DB |
| NEW | Height modifier values per level | ❌ Open (hit%, evasion%, dmg multiplier, fuel rate) |
| NEW | Fuel base depletion rate per cycle | ❌ Open (designer-defined in DB) |

---

## 10. Technical Stack

| Layer | Technology |
|-------|-----------|
| Framework | Flutter |
| Platform | iOS (primary), Android (future) |
| Database | SQLite (`ob3.db`) |
| State Mgmt | TBD (UXArchitect to specify) |
| Theme | MILSTD dark military dashboard |

---

## 11. Scenario Editor (Web App)

The **OB3 Scenario Editor** is a standalone Flutter web application for creating, editing, and managing game scenarios.

### 11.1 Wizard Steps (9 total)

| Step | Content |
|------|---------|
| 1 | **Basic Info** — Title, description, briefing visual (file upload), overview, mission briefing, primary/secondary objectives |
| 2 | **Drones** — Multi-select available drones or "ALL" |
| 3 | **Target Cards** — Build deck with `card_id:quantity` pairs |
| 4 | **Threat Cards** — Build deck with `card_number:quantity` pairs |
| 5 | **Combat Cards** — Build deck with `card_id:quantity` pairs |
| 6 | **Modifiers** — 6 gameplay adjustments (fuel cost, attack roll, evasion, altitude cost, target acquisition, threat determination) |
| 7 | **Loadouts** — Exclude specific loadout options per drone |
| 8 | **Metadata** — Difficulty, play time, author, tags |
| 9 | **Review** — Summary + save/publish |

### 11.2 Export / Import

| Action | Format | Behavior |
|--------|--------|----------|
| **Export ⬇** | `.txt` | Downloads via browser. All fields included (filled or empty) with `#` remarks and working `# Example:` blocks. Objectives exported as `OBJECTIVE:` / `IS_PRIMARY:` / `CONDITION:` blocks (pipe-delimited). Available on all 9 wizard steps + list page. |
| **Import** | `.txt` | File picker, reads bytes on web, validates IDs against DB, creates new Draft scenario. |
| **Save Draft** | DB | Saves without validation — WIP scenarios allowed. |
| **Publish** | DB | Pre-validates all required fields; shows clean AlertDialog with bulleted list of missing fields. Writes to `ob3.db`. |

### 11.3 Briefing Visual

| Attribute | Value |
|-----------|-------|
| Position | Between Short Description and Overview fields (Step 1) |
| Input | File upload button (not URL text input) |
| Formats | JPG, PNG |
| Max size | 100 KB |
| Recommended | 16:9 landscape aspect ratio |
| Storage | Base64 data URI in `scenarios.mission_briefing_image_path` |
| Preview | Live preview shown below upload button with Remove option |

### 11.4 Validation (on Publish)

When publishing, all required fields are checked. If issues found, a styled AlertDialog shows:
1. Title is required
2. Short description is required
3. Overview text is required
4. Mission briefing is required
5. At least 1 drone selected
6. At least 5 target, threat, and combat cards each
7. **At least one objective must be marked `is_primary`**
8. NAMED_CARD conditions must reference a card name that exists in `target_cards`

### 11.5 Versioning

- New scenarios: `v1.00`
- Each save: `+0.01`
- Display: `vX.XX` in AppBar and scenario browser

### 11.6 Objective System (Sprint OBJ-1)

Objectives are now stored in a dedicated `scenario_objectives` table (replacing flat `primary_objective_*` columns).

| Concept | Detail |
|---------|--------|
| **Structure** | Both primary and secondary objectives share identical structure — differ only by `is_primary` flag |
| **Condition types** | `NAMED_CARD` (eliminate specific named card) and `KILL_QUOTA` (eliminate N cards of a target sub_category) |
| **Compound objectives** | Multiple conditions under same `objective_id` — ALL must be met |
| **Weapon requirement** | Optional `weapon_required` per condition — kill only counts if correct weapon used |
| **One primary** | Exactly one objective must be `is_primary=1` per scenario |
| **Multiple secondaries** | A scenario can have 1 primary + N secondary objectives |

**Objective Evaluation (game engine):**
- `ObjectiveEvaluator` is a **pure function** — no DB access, no side effects
- Called after every kill at B4
- Inputs: `destroyedCardsWithWeapon[]`, `scenarioObjectives[]`
- Output: `objectiveStatus` map (complete/incomplete per objective_id)
- Primary complete → mission success → AAR screen
- Secondary complete → HUD notification only

**AAR display:**
- Primary shown first with `ACHIEVED`/`FAILED` badge
- Each condition shown: NAMED_CARD → card name + ELIMINATED/NOT ELIMINATED; KILL_QUOTA → type + kills/required
- Mission result determined solely by primary objective status

---

*Produced by OB3-ProjectManager | To be reviewed by COMMANDER before UX phase starts*
