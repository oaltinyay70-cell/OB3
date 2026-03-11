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
SQLite: `drone_commander_cards.db`, table: `drones` (28 rows)

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

#### B0 — In Transit
- COMMS check if damage > 2 (uncontrollable = destroyed)
- No decisions

#### B1 — Search
- Optional: change height (free action)
- No card draws at B1

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
- Select height, attack mode (Stand-Off / Close-In / FO-Laze), weapon
- Roll 1D6 + DRM → consult Attack CRT → VP banked if hit
- SAM counterfire check if target was SAM

#### B5 — Evasive Action
- Resolve Threat Card drawn at B2
- Evasion roll 1D6 + DRM
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
| Mode | Fuel Cost | Notes |
|------|-----------|-------|
| Stand-Off | 1F | Lowest risk |
| Close-In | 1F | Higher risk, higher damage |
| FO/Laze | 3F | Calls external fire support |

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
| Database | SQLite (`drone_commander_cards.db`) |
| State Mgmt | TBD (UXArchitect to specify) |
| Theme | MILSTD dark military dashboard |

---

*Produced by OB3-ProjectManager | To be reviewed by COMMANDER before UX phase starts*
