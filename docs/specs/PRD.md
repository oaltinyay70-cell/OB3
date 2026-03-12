# OB3 Drone Commander — Product Requirements Document

> **Version**: 1.0  
> **Date**: 2026-03-12  
> **Author**: OB3-TechWriter  
> **Audience**: AI Developer / Senior Flutter Developer  
> **Status**: APPROVED FOR IMPLEMENTATION

> [!IMPORTANT]
> This document is the **single source of truth** for building the Drone Commander mobile app. It consolidates every specification, database schema, visual design token, game mechanic, and scenario editor rule into one reference. If this document contradicts any other file, **this document wins**.

---

## Table of Contents

1. [Product Overview](#1-product-overview)
2. [Game Hierarchy & End Conditions](#2-game-hierarchy--end-conditions)
3. [Game Setup Flow](#3-game-setup-flow)
4. [Core Game Loop (B0–B5)](#4-core-game-loop-b0b5)
5. [Damage Cascade System](#5-damage-cascade-system)
6. [Fuel / Endurance System](#6-fuel--endurance-system)
7. [Scoring System](#7-scoring-system)
8. [Card Mechanics](#8-card-mechanics)
9. [Combat Resolution Tables (CRT)](#9-combat-resolution-tables-crt)
10. [Drone Data & Capabilities](#10-drone-data--capabilities)
11. [Weapons & Loadout System](#11-weapons--loadout-system)
12. [Scenario System & Editor](#12-scenario-system--editor)
13. [Screen Inventory & Navigation](#13-screen-inventory--navigation)
14. [Screen-by-Screen Specifications](#14-screen-by-screen-specifications)
15. [Game State Data Model](#15-game-state-data-model)
16. [State Machine Transitions](#16-state-machine-transitions)
17. [Design System](#17-design-system)
18. [Database Schema & Contents](#18-database-schema--contents)
19. [File Structure & Architecture](#19-file-structure--architecture)
20. [Known Data Gaps & Blockers](#20-known-data-gaps--blockers)
21. [Reference Documents](#21-reference-documents)

---

## 1. Product Overview

**Product**: Drone Commander — iOS mobile game (Flutter/Dart)  
**Genre**: Solo tactical board-game adaptation  
**Theme**: Military MILSTD dark intelligence dashboard  
**Goal**: Digitize the "Obscure Battles 3: Drone Commander" board game as a single-player iOS game  

### 1.1 v1.0 Scope

| In Scope | Out of Scope (v1.1+) |
|----------|-----------------------|
| Solitaire Quick Game mode | Campaign mode (territory) |
| Scenario Game mode (load from DB) | 2+ Player competitive mode |
| Scenario Editor (survey-form) | Campaign map rendering |
| Full B0→B5 game loop | |
| All 28 drones with loadout config | |
| All card types: 37 combat, 111 target, 36 threat | |
| 4 altitude levels (VLOW, LOW, MEDIUM, HIGH) | |
| Fuel as color bar (green→blue→orange→red) | |
| Post-scenario briefing with VP scoring | |

### 1.2 Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Flutter (Dart) |
| Platform | iOS first, Android later |
| Database | SQLite via `sqflite` — bundled `ob3.db` |
| State Management | BLoC + Freezed |
| Navigation | go_router |
| Theme | MILSTD dark military dashboard |

### 1.3 Critical Development Rule

> **ASK about anything that is not clear. NEVER ASSUME ANYTHING.**  
> The rulebook is the source of truth. If something is ambiguous, unclear, or contradictory — STOP and ask.

---

## 2. Game Hierarchy & End Conditions

### 2.1 Hierarchy

```
Campaign (v1.1 — out of scope)
  └── Scenario (a mission with objectives, card decks, and rules)
        └── Cycle (one complete loop: B0 → B5 and back to B0)
```

- A **Scenario** contains one or more **Cycles**
- A **Cycle** = one traversal from B0 (In Transit) → B5 (Evasive Action)

### 2.2 Scenario End Conditions

A scenario ends when **ANY** of these occur:

| # | Condition | Description |
|---|-----------|-------------|
| 1 | Drone destroyed | SI reaches 0, or COMMS check ≥ 6 |
| 2 | Primary objectives completed | Game prompts "RTB?" |
| 3 | Player voluntarily RTBs | At B5 decision point |
| 4 | Fuel exhausted | Forced RTB |
| 5 | All target cards expanded | Solitaire only — deck empty |
| 6 | No munitions + no FO/Laze | Cannot attack at all |

After **any** end condition → display **Post-Scenario Briefing screen** (no code path skips it).

---

## 3. Game Setup Flow

### 3.1 Pre-Game Sequence

```
Select Play Mode → Select Drone → Configure Loadout → Mission Briefing → Launch
```

### 3.2 Initial Drone State

| Property | Starting Value |
|----------|---------------|
| Position | B0 |
| Altitude | MEDIUM |
| Structural Integrity | Drone's max SI value |
| Sensors Damage | 0 |
| COMMS Damage | 0 |
| VIS/RCS | 0 |
| Fuel | Drone's endurance_hours value |

### 3.3 Deck Initialization

| Mode | Target Deck | Threat Deck | Combat Deck |
|------|------------|-------------|-------------|
| Solitaire Quick Game | All 111 target cards | All 36 threat cards | Per scenario config |
| Scenario Game | Scenario-specific from DB | Scenario-specific from DB | Per scenario config |

All three decks are **independently shuffled** at scenario initialization. Duplicate cards (same card appearing multiple times) are supported.

---

## 4. Core Game Loop (B0–B5)

```
B0 (In Transit) → B1 (Search) → B2 (Target/Threat) → B3 (Positioning) → B4 (Attack) → B5 (Evasion)
     ↑                                                                                      │
     └──────────────────────────── continue / RTB / destroyed ──────────────────────────────┘
```

### 4.1 B0 — In Transit

| Action | Type | Details |
|--------|------|---------|
| COMMS check | CONDITIONAL | Only if returning from B5 AND COMMS damage > 2 |

**COMMS Check procedure:**
1. Roll 1D6
2. Apply DRM: −1 if SATCOM, −1 if Comms Redundancy, −1 if Autonomous AI (cumulative)
3. Consult table:

| Final DRM | Result |
|-----------|--------|
| ≤ 2 | All OK — continue normally |
| 3, 4, 5 | Degraded — −1 to Attack DRM this cycle |
| ≥ 6 | **UNCONTROLLABLE — drone destroyed, game ends** |

### 4.2 B1 — Search

| # | Action | Type | Details |
|---|--------|------|---------|
| 1 | Change altitude | OPTIONAL | 2F per level UP, 1F per level DOWN |
| 2 | Draw combat card | REQUIRED | Execute instructions immediately |

- If combat deck empty → reshuffle discard pile, place face-up
- After completing → move to B2
- If fuel = 0 after resolution → forced RTB

### 4.3 B2 — Target Acquisition & Threat Determination

| # | Action | Type | Details |
|---|--------|------|---------|
| 1 | Spend 1F | REQUIRED | Deduct 1 fuel |
| 2 | Target acquisition | REQUIRED | Roll 2D10 + DRM → table → draw card |
| 3 | Threat determination | REQUIRED | Roll 2D10 + DRM → table → draw card |

**Target Acquisition DRM:**
- +10 if drone has AEASA Radar
- +10 if COMMS damage = 0
- −10 per point of COMMS damage

**Default Target Acquisition Table:**

| Roll Range | Target Type |
|------------|-------------|
| ≤ 18 | TRUCK |
| 19–34 | PERSONNEL |
| 35–45 | AFV |
| 46–55 | SAM |
| 56–70 | TANK |
| 71–79 | ARTILLERY |
| 80–90 | HQ/BUNKER |
| 91–99 | VIP |
| ≥ 100 | AERIAL TARGET |

> Boundaries are **exclusive** — each value belongs to exactly one range. 35 → AFV, 91 → VIP.

**ENGINEER sub-category = PERSONNEL class** — same range, same weapon rules, different flavour name.

**Fallback rule:** If no card of rolled type exists → try next **lower** range first, then **higher**.

**Threat Determination DRM:**
- +10 for each 2 points of VIS/RCS: `+10 * floor(VIS / 2)`

**Default Threat Determination Table:**

| Roll Range | Threat Type |
|------------|-------------|
| ≤ 19 | Small Arms |
| 20–65 | AAA |
| 66–85 | SAM |
| 86–95 | CAP |
| ≥ 96 | Anti-Drone Weapon |

> **DRONE GUN** in the DB = **Anti-Drone Weapon** in the rulebook. Map `sub_category = 'DRONE GUN'` to the ≥96 range.

**Threat deck reshuffle:** If all threat cards used but target cards remain + primary not done → reshuffle used threats back into deck.

**Commander's Decision (after both cards revealed):**
- **ENGAGE** → continue to B3
- **DISENGAGE** → discard both cards to Discarded pile → return to **B1** (NOT B0)

### 4.4 B3 — Positioning

| # | Action | Type | Details |
|---|--------|------|---------|
| 1 | Change altitude | OPTIONAL | 2F per level UP, 1F per level DOWN |
| 2 | Draw combat card | REQUIRED | Execute instructions immediately |

### 4.5 B4 — Drone Attack

**Procedure:**
1. **Select attack mode**: Stand-Off, Close-In, or FO/Laze
   - AA missiles → Stand-Off only, MEDIUM or HIGH altitude only
   - Torpedoes/Sonobuoys → Close-In only
   - Anti-shipping missiles → Stand-Off only
   - FO/Laze requires built-in capability or FO/Laze Kit
2. **Select weapon** — must be compatible with target type and attack mode
3. **Select altitude** — must be in drone's supported range and weapon's fire_altitude
4. **Roll 1D6** + sum all DRM:
   - Weapon DRM (per-target-type from `weapons` table `drm_*` columns)
   - Combat card DRM (if active)
   - Target card DRM (from `instruction` field, e.g. "+1L Column Shift")
   - Sensor damage penalty: −1 per 4 sensor damage points
   - Scenario-specific DRM (if any)
5. **Consult Drone Attack CRT**: intersection of (mode × altitude × final DRM column)
6. **Apply column shifts**: +1 RIGHT per 2 points of Sensor Damage
7. **Clamp** final DRM column to [1, 6]
8. **Read result**: HIT → destroy target → VP. Miss → discard target.
9. **Consume**: deduct fuel per CRT cell, remove used weapon marker

**Post-attack SAM reaction (optional rule):**
If target was SAM AND attack **missed**:
1. Roll 1D6 + VIS as DRM
2. If final ≥ 6 → SAM fires reaction shot
3. Consult SAM Special Counterfire Table
4. Player must survive both this AND normal B5 counterfire

### 4.6 B5 — Evasive Action

**Procedure:**
1. Roll 1D6 + DRM: threat card modifiers, combat card, scenario
2. Apply column shifts: −1 LEFT per 2 points of VIS/RCS
3. Clamp DRM column to [1, 6]
4. Consult Counterfire & Evasion CRT
5. Apply damage cascade (see §5)
6. Consume fuel per CRT cell
7. Discard threat card

**If drone survives:**
- **Continue mission** → move to B0 (requires fuel AND ammo)
- **RTB** → end scenario → Post-Scenario Briefing

### 4.7 End-of-Cycle (after B5, strict order)

1. Drone destroyed? → Post-scenario briefing
2. Fuel exhausted? → Forced RTB → Post-scenario briefing
3. Player RTB? → Post-scenario briefing
4. All clear → Deduct end-of-cycle fuel, clear cycle-scoped combat card effects, increment cycle → B0

---

## 5. Damage Cascade System

Damage flows through a cascading chain:

```
Structural Integrity (SI) damage
    ├── Sensors Damage: min(floor(totalSIDamage / 2), 9)
    ├── COMMS Damage:   min(floor(totalSIDamage / 3), 5)
    └── VIS/RCS:        commsDamage + sensorsDamage + adjustments
```

| Subsystem | Starts | Max | Formula | Game Effect |
|-----------|--------|-----|---------|-------------|
| **SI** | Drone max | 0 = destroyed | `SI -= damage` | 0 → drone destroyed |
| **Sensors** | 0 | 9 | `min(floor((maxSI - currentSI) / 2), 9)` | Every 4 pts → −1 Attack DRM |
| **COMMS** | 0 | 5 | `min(floor((maxSI - currentSI) / 3), 5)` | > 2 → COMMS check at B0 |
| **VIS/RCS** | 0 | — | `commsDamage + sensorsDamage` | +10 Threat DRM per 2 VIS |

> **Sensor kits do NOT take damage** — they are external equipment.

**Special threat card damage rules** (parsed from `instruction` column):
- "Any 1D hit is DOUBLED" — multiply damage by 2
- "+5D extra" — add 5 to damage
- "INSTANT KILL" — drone destroyed regardless of SI

---

## 6. Fuel / Endurance System

### 6.1 Display

Fuel is displayed as a **color bar** — NO numeric value shown to the player.

| Band | Range | Color | Hex |
|------|-------|-------|-----|
| Full | 75–100% | Green | `#00E676` |
| Good | 40–75% | Blue | `#40C4FF` |
| Warning | 10–40% | Orange | `#FF9100` |
| Critical | 0–10% | Red | `#FF1744` |

- Smooth color interpolation between thresholds
- At ≤15%: bar pulses gently (opacity 0.7 ↔ 1.0, 1.5s cycle)
- Long-press tooltip shows percentage (optional)

### 6.2 Consumption Rules

Fuel costs are **accumulated during the cycle** and **deducted at the end of each cycle**.

| Source | Cost |
|--------|------|
| B2 — Target/Threat phase entry | 1F |
| Altitude change UP (B1 or B3) | 2F per level raised |
| Altitude change DOWN (B1 or B3) | 1F per level lowered |
| Attack CRT result (B4) | 1F / 2F / 3F (per cell) |
| Evasion CRT result (B5) | 0F / 1F / 2F (per cell) |
| Base depletion rate | scenario-defined rate per cycle |
| Loadout with `(+)` marker | +2F per cycle |

### 6.3 Key Rules

- **1F = 1 endurance unit** (confirmed by designer)
- Remaining fuel at RTB has **zero impact on VP** (no score bonus)
- If fuel = 0 at any fuel check → **forced RTB**

---

## 7. Scoring System

### 7.1 Methods

| Method | When Game Ends | Used For |
|--------|---------------|----------|
| **Maximum Kill** | All target cards drawn | Solitaire Quick Game |
| **Quick Kill** | Primary objective completed | Scenario Game |

### 7.2 Formula

```
Final Score = Sum(destroyed target VP) − Drone VP Cost (Solitaire only)
```

- **Drone VP Cost = 5 VP** for all drones (constant, confirmed by designer, no DB column needed)
- VP subtraction applies **only** in Solitaire Quick Game mode
- Secondary objective VP shown as 0 if primary not met

### 7.3 Post-Scenario Briefing (6 mandatory sections)

| Section | Content |
|---------|---------|
| 1. Termination Reason | `Drone Destroyed` / `Fuel Exhausted` / `RTB` |
| 2. Objectives Checklist | Primary + secondary: ACHIEVED or FAILED |
| 3. Kill List | Ordered list of confirmed kills |
| 4. VP Breakdown | VP per kill. Secondary VP flagged |
| 5. Total Scenario VP | Sum of eligible VP |
| 6. Campaign Advancement | ADVANCE or LOCKED (hidden for standalone) |

### 7.4 Progression System

VP accumulates on the player's profile. At certain VP thresholds, the player earns **medals** and **rank-ups**. This is a persistent system across sessions.

---

## 8. Card Mechanics

### 8.1 Combat Cards (37 total in DB — 2 sets)

The DB contains **two sets** of combat cards:

**Original Set (CC001–CC018)** — 18 cards with state-modifying effects:

| Card | Name | Effect |
|------|------|--------|
| CC001 | WORLD IS WATCHING | Close-in only until next B0 |
| CC002 | COMMS PROBLEM | +2 COMMS damage |
| CC003 | JAMMED! | +1 sensor damage (permanent) |
| CC004 | SKILLED OPERATOR | Reset VIS/RCS to 0 |
| CC005 | IONIZING LAYER | Clear all COMMS damage |
| CC006 | ENEMY CAP! | Must fly LOW altitude for rest of mission |
| CC007–CC012 | NO EVENT (×6) | Discard without action |
| CC013 | LOCAL ASSET | Reveal top 3 target cards, pick 1 |
| CC014 | RADIO D/F | +1 DRM if next target is HQ/BUNKER at Stand-Off |
| CC015 | WALKING DEAD | Return last destroyed target to deck |
| CC016 | SMOKING ACES | 1 LEFT shift to attack this cycle |
| CC017 | INTRUDER'S FLIGHT | Skip next counterfire this cycle |
| CC018 | RADIO CHATTER | 1 LEFT shift to counterfire if CAP/SAM threat |

**Revised Set (NEW_CC_01–NEW_CC_19)** — 19 cards with attack DRM and altitude effects:

| Card | Name | Type | Effect |
|------|------|------|--------|
| NEW_CC_01 | AGGRESSIVE STRIKE PROFILE | Attack DRM | +2 to all attack rolls |
| NEW_CC_02 | WHITEOUT | Attack DRM | −2 to all attack rolls |
| NEW_CC_03 | TAILWIND | Attack DRM | +1 to all attack rolls |
| NEW_CC_04 | STATIC | Attack DRM | −1 to all attack rolls |
| NEW_CC_05 | LOST SIGNAL | Attack DRM | −2 to all attack rolls |
| NEW_CC_06 | CLEAR SKIES | Attack DRM | +2 to all attack rolls |
| NEW_CC_07 | GROUND HUGGING | Attack DRM | +1 at VLOW or LOW altitude only |
| NEW_CC_08 | UPDRAFT | Attack DRM | −1 to all attack rolls |
| NEW_CC_09 | GHOST SIGNAL | Attack DRM | −1 to all attacks, FO/Laze unaffected |
| NEW_CC_10 | BURST TRANSMISSION | Attack DRM | +1 to all attack rolls |
| NEW_CC_11 | FOG OF WAR | Attack DRM | −2 to all attack rolls |
| NEW_CC_12 | THERMAL SPIKE | Altitude | +1 altitude level |
| NEW_CC_13 | DIVE DIVE DIVE | Altitude | −1 altitude level |
| NEW_CC_14 | DEAD DROP | Altitude | −1 altitude level |
| NEW_CC_15 | STRATOSPHERIC | Altitude | +2 altitude levels |
| NEW_CC_16 | NOSEDIVE | Altitude | −2 altitude levels |
| NEW_CC_17 | DECK LEVEL | Altitude | Forced to VERY LOW |
| NEW_CC_18 | TOP GUN | Altitude | Forced to HIGH |
| NEW_CC_19 | NO EVENT | — | Discard without action |

> [!IMPORTANT]
> The scenario designer selects which combat card set to use and the deck composition (event count + no-event count). The `attribute_effect` column in DB contains parseable effect strings.

**Reshuffle rule:** When depleted → reshuffle discard pile, place back **face-up**.

### 8.2 Target Cards (111 total, 10 sub-categories)

| Sub-Category | Count | VP Range | Notes |
|-------------|-------|----------|-------|
| AFV | 18 | 0.5–3.5 | |
| AIR | 6 | 2.0–6.0 | |
| ARTILLERY | 18 | 0.5–4.0 | |
| ENGINEER | 6 | 2.0–6.0 | Treated as PERSONNEL for all mechanics |
| HQ-BUNKER | 6 | 2.0–5.0 | |
| PERSONNEL | 12 | 0.5–2.0 | |
| SAM | 18 | 0.5–5.0 | Triggers SAM Reaction on miss |
| TANK | 15 | 0.5–3.5 | |
| TRUCK | 6 | 0.5–5.0 | |
| VIP | 6 | 3.0–10.0 | Highest VP value targets |

**Target card special rules:** The `instruction` column may contain combat modifier strings that the engine **MUST** parse at attack resolution. Example: `"+1 Left Column Shift in Attack"`.

### 8.3 Threat Cards (36 total, 5 sub-categories)

| Sub-Category | Count | DB Value | Rulebook Name |
|-------------|-------|----------|---------------|
| AAA | 6 | AAA | AAA |
| CAP | 12 | CAP | CAP |
| DRONE GUN | 6 | DRONE GUN | Anti-Drone Weapon (≥96 range) |
| SAM | 6 | SAM | SAM |
| SMALL ARMS | 6 | SMALL ARMS | Small Arms |

**Threat card special rules** (from `instruction` column):

| Rule Text | Meaning |
|-----------|---------|
| "+Only Low Altitudes" | Threat only fires at LOW altitude |
| "+Only Low and Medium Altitudes" | Threat fires at LOW and MEDIUM |
| "+Only High Altitudes" | Threat fires only at HIGH |
| "+Any 1D Hit is Doubled" | Multiply damage by 2 |
| "+Any hit is INSTANT KILL" | Drone destroyed if hit |
| "+Any hit +5D extra" | Add 5 to damage result |
| "+Can't Fire if VIS<2" | Skip if drone VIS < 2 |
| "+X Right Column Shift" | Shift X columns right in CRT |

### 8.4 Card Flow Diagram

```
[Target Deck] ──draw──► [Active Target]
                              │
            ┌─────────────────┴─────────────────┐
        (HIT at B4)                    (MISS or disengage)
            │                                   │
    [Destroyed Pile]                    [Discarded Pile]
     (counts for VP)

[Threat Deck] ──draw──► [Active Threat]
                              │
                     (after B5 resolution)
                              │
                      [Discarded Pile]
                    (reshuffle if needed)

[Combat Deck] ──draw──► [Execute] ──► [Discard Pile]
                                       (reshuffle when empty, face-up)
```

---

## 9. Combat Resolution Tables (CRT)

Three CRT tables, each indexed by **attack mode × altitude × DRM column (1–6)**.

### 9.1 Dice Rules

| Die | Range | Clamping |
|-----|-------|----------|
| 1D6 | 1–6 | DR cannot exceed 6 or be less than 1 |
| 2D10 | 0–99 | DRM result CAN exceed 100 or go below 0 |

### 9.2 Drone Attack CRT

Result: fuel cost + optional HIT. Column shift: **+1 RIGHT per 2 Sensor Damage**.

|  | Stand-Off ||||||  Close-In ||||||  FO/Laze ||||||
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| **ALT\DRM** | **1** | **2** | **3** | **4** | **5** | **6** | **1** | **2** | **3** | **4** | **5** | **6** | **1** | **2** | **3** | **4** | **5** | **6** |
| **VLOW** | N/A | N/A | N/A | N/A | N/A | N/A | 2F | 2F+H | 2F+H | 2F+H | 2F+H | 2F+H | 3F | 3F | 3F+H | 3F+H | 3F+H | 3F+H |
| **LOW** | 1F | 1F | 1F | 1F | 1F | 1F | 2F | 2F | 2F | 2F | 2F | 2F+H | 3F | 3F | 3F | 3F | 3F | 3F+H |
| **MED** | 1F | 1F | 1F | 1F | 1F | 1F+H | 2F | 2F | 2F | 2F | 2F+H | 2F+H | 3F | 3F | 3F+H | 3F+H | 3F+H | 3F+H |
| **HIGH** | 1F | 1F | 1F | 1F | 1F+H | 1F+H | 2F | 2F | 2F | 2F+H | 2F+H | 2F+H | 3F | 3F | 3F | 3F+H | 3F+H | 3F+H |

> N/A = Stand-Off is NOT available at VLOW altitude. H = HIT.

### 9.3 Counterfire & Evasion CRT

Result: damage + fuel cost. Column shift: **−1 LEFT per 2 VIS/RCS**.

|  | Stand-Off |||||| Close-In |||||| FO/Laze ||||||
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| **ALT\DRM** | **1** | **2** | **3** | **4** | **5** | **6** | **1** | **2** | **3** | **4** | **5** | **6** | **1** | **2** | **3** | **4** | **5** | **6** |
| **VLOW** | N/A | N/A | N/A | N/A | N/A | N/A | — | — | — | 3D+2F | 3D+2F | 3D+2F | — | — | — | — | — | 1D+1F |
| **LOW** | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| **MED** | — | — | — | — | — | 1D+1F | — | — | — | — | 1D+1F | 2D+F | — | — | 1D+1F | 1D+1F | 1D+1F | 1D+1F |
| **HIGH** | — | — | — | — | 1D+2F | 1D+2F | — | — | — | 1D+1F | 1D+1F | 1D+1F | — | — | — | 1D+1F | 1D+1F | 1D+1F |

> ⬜ = LOW row values **pending DILEK clearance** — use interpolated values as fallback.

### 9.4 SAM Special Counterfire CRT

Same column shift rules. Only applies when attack misses a SAM target.

|  | Stand-Off |||||| Close-In |||||| FO/Laze ||||||
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| **ALT\DRM** | **1** | **2** | **3** | **4** | **5** | **6** | **1** | **2** | **3** | **4** | **5** | **6** | **1** | **2** | **3** | **4** | **5** | **6** |
| **VLOW** | = LOW row values for SAMs | | | | | | | | | | | | | | | | | |
| **LOW** | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| **MED** | — | — | — | — | — | — | — | — | — | — | — | 1D+1F | — | — | — | — | 1D+1F | 1D+1F |
| **HIGH** | — | — | — | — | — | 1D+2F | — | — | — | — | 1D+1F | 1D+1F | — | — | — | — | 1D+1F | 1D+1F |

---

## 10. Drone Data & Capabilities

### 10.1 All 28 Drones

| ID | Name | Country | Class | Altitude | Endurance (h) | Max SI | AEASA | SATCOM | CommsRed | AutoAI | FO/Laze |
|----|------|---------|-------|----------|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| 1 | BAYRAKTAR TB2 | Turkey | B | LOW, MED | 27 | 80 | — | — | — | — | ✓ |
| 2 | BAYRAKTAR AKINCI | Turkey | B | LOW, MED, HIGH | 24 | 225 | ✓ | — | — | — | ✓ |
| 3 | AKSUNGUR | Turkey | B | LOW, MED | 50 | 175 | — | — | — | — | ✓ |
| 4 | ANKA-S | Turkey | B | LOW, MED | 30 | 125 | — | — | — | — | ✓ |
| 5 | WING LOONG II | China | B | LOW, MED | 20 | 195 | — | — | — | — | ✓ |
| 6 | WING LOONG-3 | China | B | LOW, MED, HIGH | 40 | 240 | — | — | — | — | ✓ |
| 7 | CH-4B | China | B | LOW, MED | 40 | 110 | — | — | — | — | ✓ |
| 8 | CH-5 | China | B | LOW, MED, HIGH | 60 | 175 | — | — | — | — | ✓ |
| 9 | TB-001 SCORPION | China | B | LOW, MED | 35 | 160 | — | — | — | — | ✓ |
| 10 | MQ-9 REAPER | USA | B | LOW, MED | 27 | 210 | ✓ | ✓ | ✓ | ✓ | ✓ |
| 11 | MQ-9B PROTECTOR | USA/UK | B | LOW, MED, HIGH | 40 | 225 | ✓ | ✓ | ✓ | ✓ | ✓ |
| 12 | AVENGER | USA | B | ⚠️ EMPTY | 20 | 275 | ✓ | ✓ | ✓ | ✓ | ✓ |
| 13 | GRAY EAGLE | USA | B | LOW, MED | 40 | 120 | ✓ | ✓ | ✓ | ✓ | ✓ |
| 14 | HERON TP | Israel | B | LOW, MED, HIGH | 40 | 220 | — | — | — | — | ✓ |
| 15 | HERMES 450 | Israel | B | ⚠️ EMPTY | 20 | 70 | — | — | — | — | ✓ |
| 16 | HERMES 900 | Israel | B | LOW, MED | 36 | 105 | — | — | — | — | ✓ |
| 17 | ORION | Russia | B | LOW, MED | 24 | 95 | — | — | — | — | — |
| 18 | S-70 OKHOTNIK-B | Russia | B | ⚠️ EMPTY | 20 | 425 | — | — | — | — | — |
| 19 | ALTIUS-RU | Russia | B | LOW, MED | 48 | 235 | — | — | — | — | — |
| 20 | MOHAJER-6 | Iran | B | LOW, MED | 12 | 75 | — | — | — | — | ✓ |
| 21 | MOHAJER-10 | Iran | B | LOW, MED | 24 | 140 | — | — | — | — | ✓ |
| 22 | SHAHED-129 | Iran | B | LOW, MED | 24 | 100 | — | — | — | — | ✓ |
| 23 | BURRAQ | Pakistan | B | LOW, MED | 10 | 65 | — | — | — | — | ✓ |
| 24 | NEURON | France | B | ⚠️ EMPTY | 3 | 250 | — | — | — | — | ✓ |
| 25 | TARANIS | UK | B | ⚠️ EMPTY | 5 | 270 | — | — | — | — | ✓ |
| 26 | GHATAK | India | B | ⚠️ EMPTY | 12 | 370 | — | — | — | — | ✓ |
| 27 | EURODRONE | EU | B | LOW, MED | 40 | 315 | — | — | — | — | ✓ |
| 28 | FALCO XPLORER | Italy | B | LOW, MED | 24 | 110 | — | — | — | — | ✓ |

### 10.2 Drone Special Abilities

| Ability | Effect | No Other Effect |
|---------|--------|-----------------|
| AEASA Radar | +10 DRM on Target Acquisition | Confirmed: no other effect |
| SATCOM | −1 to COMMS Check DRM | Confirmed: no other effect |
| COMMS Redundancy | −1 to COMMS Check DRM | Confirmed: no other effect |
| Autonomous DM AI | −1 to COMMS Check DRM | Confirmed: no other effect |
| Built-in FO/Laze | Can use FO/Laze without kit | 22 of 28 drones have this |

### 10.3 FO/Laze Kit Requirement

6 drones that **DO NOT** have built-in FO/Laze and MUST load a kit:
- TB-001 SCORPION (ID 9) — ⚠️ DB shows `has_builtin_fo_laze=1`, discrepancy
- ORION (ID 17)
- S-70 OKHOTNIK-B (ID 18)
- ALTIUS-RU (ID 19)

> [!WARNING]
> The `has_builtin_fo_laze` column in the DB does not match the designer's confirmed list from `rulebook_gaps.md`. Reconciliation needed.

---

## 11. Weapons & Loadout System

### 11.1 All 32 Weapons

| ID | Type | Name | Targets | Fire Range | Fire Altitude |
|----|------|------|---------|------------|---------------|
| 1 | ATGM | MAM-L | armored vehicles, fortifications | medium | LOW, MED |
| 2 | ATGM | MAM-C | light vehicles, soft targets | medium | LOW |
| 3 | Cruise Missile | SOM | strategic targets, air defenses | far | MED, HIGH |
| 4 | ATGM | UMTAS | armored vehicles | medium | LOW |
| 5 | ATGM | BA-7 | tanks, armored vehicles | medium | LOW |
| 6 | Guided Bomb | FT-9 | ground targets | medium | MED |
| 7 | ATGM | AR-1 | vehicles and armor | medium | LOW |
| 8 | Guided Bomb | FT-12 | fixed ground targets | far | MED, HIGH |
| 9 | Missile | AR-2 | vehicles, personnel | close-medium | LOW |
| 10 | ATGM | AGM-114 Hellfire | armor, vehicles | medium | LOW |
| 11 | Guided Bomb | GBU-12 Paveway II | ground targets | medium | MED |
| 12 | Guided Bomb | GBU-38 JDAM | fixed targets | far | HIGH |
| 13 | Missile | Brimstone | moving armor | medium | LOW |
| 14 | Guided Bomb | GBU-31 JDAM | hardened targets | far | HIGH |
| 15 | ATGM | Spike | armor, vehicles | medium | LOW |
| 16 | Guided Bomb | SPICE-250 | precision strike | far | MED, HIGH |
| 17 | Guided Bomb | KAB-20 | light targets | close-medium | LOW |
| 18 | Guided Bomb | KAB-250 | vehicles, structures | medium | MED |
| 19 | Guided Bomb | KAB-500 | fortifications | far | MED, HIGH |
| 20 | ATGM | Almas | tanks | medium | LOW |
| 21 | Guided Bomb | Qaem-5 | vehicles | medium | LOW |
| 22 | Guided Bomb | Qaem-9 | ground targets | medium | MED |
| 23 | Missile | Sadid-345 | armor and vehicles | medium | LOW |
| 24 | ATGM | Barq | armor | medium | LOW |
| 25 | Guided Bomb | H-2 | fixed ground targets | far | MED, HIGH |
| 26 | Guided Bomb | AASM Hammer | various ground targets | far | MED, HIGH |
| 27 | Guided Bomb | Paveway IV | vehicles, infrastructure | medium | MED |
| 28 | Guided Bomb | SAAW | runways, structures | far | MED, HIGH |
| 29 | KIT | FO/LAZE KIT | ALL (designator) | medium | LOW, MED, HIGH |
| 30 | ATGM | HJ-10 | AFV, TANK | medium | LOW, MED |
| 31 | Guided Bomb | FT-7 | ALL | close-medium | LOW, MED, HIGH |
| 32 | Guided Bomb | FT-10 | HQ/BUNKER, PERSONNEL, AFV | close-medium | MED, HIGH |

### 11.2 Weapon DRM Values

> [!CAUTION]
> **ALL weapon DRM columns (`drm_afv`, `drm_tank`, etc.) in the current DB are 0** except for two weapons:
> - HJ-10 (ID 30): drm_afv = −1, drm_tank = −1
> - FT-10 (ID 32): drm_artillery = 1
>
> This is likely incomplete data. The developer must handle gracefully.

### 11.3 Loadout Selection Rules

Each drone has up to 5 loadout option pairs (`opt1`–`opt5`), each with weapon name + quantity.

**Class restrictions:**

| Marker | Rule |
|--------|------|
| `(*A)` | A-class drones only |
| `(*B)` | B-class or bigger |
| `(*C)` | C-class or bigger |
| `(*D)` | D-class or bigger |
| `(%)` | Exclusive — no other weapon OR kit if carried |
| `(+)` | +2F fuel per cycle if carried |

> All 28 drones are currently class B. No A/C/D class drones exist in v1.0 (confirmed).

### 11.4 Weapon → Target Type Compatibility

| Loadout Type | Valid Target Types |
|--------------|-------------------|
| Armor Piercing/ATGW | AFV, TANK, TRUCK |
| Thermobaric | PERSONNEL, TRUCK, AFV (penalty) |
| AA Warfare | AIR only |
| Anti-Personnel | PERSONNEL only |
| Bunker Buster | HQ-BUNKER |
| Multi-Purpose | All types |
| Anti-Shipping | Naval targets only |
| KIT | Special (scenario-defined) |

### 11.5 Attack Mode Restrictions

| Restriction | Meaning |
|-------------|---------|
| Close-In only | Cannot be used in Stand-Off or FO/Laze |
| Stand-Off only | Cannot be used in Close-In or FO/Laze |
| AA only | Can only target AIR sub-category |

---

## 12. Scenario System & Editor

### 12.1 Scenario Data (from DB)

| Field | DB Column | Description |
|-------|-----------|-------------|
| Name | `scenarios.name` | Scenario title |
| Campaign | `scenarios.campaign_name` | Parent campaign (v1.1) |
| Description | `scenarios.description` | Short description |
| Narrative | `scenarios.narrative` | Story/briefing text |
| Drone | `scenarios.drone_id` | Forced drone (FK → drones) |
| Primary Objective | `scenarios.primary_objective` | Mission goal |
| Primary Zone | `scenarios.primary_objective_zone` | Zone # for completion |
| Primary Target | `scenarios.primary_objective_card_name` | Target card name |
| Weapon Requirement | `scenarios.primary_objective_weapon_req` | e.g. THERMOBARIC |
| Scoring Mode | `scenarios.scoring_mode` | MAXIMUM_KILL or QUICK_KILL |
| Event Cards | `scenarios.combat_event_count` | # event combat cards |
| No-Event Cards | `scenarios.combat_no_event_count` | # no-event combat cards |
| Reinforcement | `scenarios.reinforcement_rule` | Campaign feature |
| Special Rules | `scenarios.special_rules` | Free-text overrides |

### 12.2 Per-Zone Configuration

| Table | Key Data |
|-------|----------|
| `scenario_zones` | zone_number, terrain description |
| `scenario_target_deck` | target cards + quantities per zone |
| `scenario_threat_deck` | threat cards + quantities + special rules per zone |
| `scenario_target_ranges` | custom probability ranges per target type per zone |
| `scenario_threat_ranges` | custom probability ranges per threat type per zone |
| `scenario_loadouts` | available loadout options per scenario |

### 12.3 Scenario Editor (Survey-Form)

The Scenario Editor is a **7-step wizard form**:

**Step 1: Setting & Narrative**
- Scenario Name (required, max 50 chars) → `scenarios.name`
- Brief Description (required, max 100 chars) → `scenarios.description`
- Narrative Briefing (optional, max 1000 chars) → `scenarios.narrative`
- Campaign Assignment (dropdown, optional) → `scenarios.campaign_name`

**Step 2: Drone & Rules**
- Allowed Drones (multi-select, default: all 28) → app logic
- Hardcoded Drone (toggle + dropdown) → `scenarios.drone_id`
- Scoring Mode (radio: MAXIMUM_KILL / QUICK_KILL) → `scenarios.scoring_mode`
- Special Global Rules (text area) → `scenarios.special_rules`

**Step 3: Primary Objective**
- Objective Description (required) → `scenarios.primary_objective`
- Target Card Name (dropdown from target cards) → `scenarios.primary_objective_card_name`
- Required Weapon Type (dropdown) → `scenarios.primary_objective_weapon_req`
- Completion Zone (dropdown: 1–9) → `scenarios.primary_objective_zone`

**Step 4: Environment & Zoning**
- Number of Zones (stepper: 1–9) → generates `scenario_zones` rows
- Per zone: Title (text) + Narrative (text area)

**Step 5: Card Pool Building** (repeats per zone)
- Target Deck: 10 sub-category rows with quantity spinners → `scenario_target_deck`
- Threat Deck: 5 sub-category rows with quantity spinners + optional special rule text → `scenario_threat_deck`

**Step 6: Acquisition Probability Ranges** (overrides defaults)
- Target Ranges: 10 dual-thumb sliders (0–100), must be exclusive + contiguous → `scenario_target_ranges`
- Threat Ranges: 5 dual-thumb sliders → `scenario_threat_ranges`

**Step 7: Combat Event Volatility**
- Event card count (stepper: 0–12) → `scenarios.combat_event_count`
- No-Event card count (stepper: 0–6) → `scenarios.combat_no_event_count`

**Validation before save:**
1. Primary objective target card must exist in Step 5 deck build
2. Acquisition ranges must be gap-free and overlap-free (0–100%)
3. Cannot have 0 target cards total
4. On success: batched SQLite INSERT across 7 scenario tables

---

## 13. Screen Inventory & Navigation

### 13.1 Screens

| ID | Screen | Entry Points |
|----|--------|-------------|
| S00 | Splash / Boot | App cold start |
| S01 | Main Menu | After splash, after game-end |
| S02 | Drone Selection | Quick Game or Scenario flow |
| S03 | Loadout Configuration | After drone selected |
| S04 | Mission Briefing | After loadout confirmed |
| S05 | Game Board | After mission launch |
| S06 | Post-Scenario Briefing | After game ends |
| S07 | Scenario Browser | Main Menu → Scenarios |
| S08 | Scenario Editor | Main Menu → Editor |
| S09 | Settings | Main Menu → Settings |
| S10 | About / Credits | Main Menu → About |
| — | Call Sign (first launch) | After splash |

### 13.2 Navigation Rules

1. No deep-linking within the game loop — once in S05, navigation is state-driven
2. Back navigation: S02→S01, S03→S02, S04→S03 — but NOT from S05
3. Settings accessible from Main Menu only (not mid-game in v1.0)
4. Replay from Post-Scenario re-enters S04 with same drone/loadout

### 13.3 Navigation Flow

```
Splash → Call Sign (first launch) → Main Menu
                                       ├── Quick Game → Drone Select → Loadout → Briefing → Game
                                       ├── Scenario → Scenario Browser → Drone Select → …
                                       ├── Campaign → (disabled, toast "Coming in v1.1")
                                       ├── Editor → Scenario Editor Wizard
                                       ├── Settings
                                       └── About
```

### 13.4 Router Configuration

```dart
final router = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(path: '/splash',    builder: (_, __) => SplashScreen()),
    GoRoute(path: '/menu',      builder: (_, __) => MainMenuScreen()),
    GoRoute(path: '/drones',    builder: (_, __) => DroneSelectionScreen()),
    GoRoute(path: '/loadout',   builder: (_, __) => LoadoutConfigScreen()),
    GoRoute(path: '/briefing',  builder: (_, __) => MissionBriefingScreen()),
    GoRoute(path: '/game',      builder: (_, __) => GameBoardScreen()),
    GoRoute(path: '/debrief',   builder: (_, __) => PostScenarioScreen()),
    GoRoute(path: '/scenarios', builder: (_, __) => ScenarioBrowserScreen()),
    GoRoute(path: '/editor',    builder: (_, __) => ScenarioEditorScreen()),
    GoRoute(path: '/settings',  builder: (_, __) => SettingsScreen()),
    GoRoute(path: '/about',     builder: (_, __) => AboutScreen()),
  ],
);
```

**Route guards:**
- `/game` requires valid `GameState` in BLoC
- `/loadout` requires a selected drone ID
- Back navigation from `/game` is disabled

---

## 14. Screen-by-Screen Specifications

### S00 — Splash / Boot

- Duration: 2–3 seconds (or until DB loaded)
- Background: `#0A0E14` with faint topographic grid
- Radar sweep animation: 240pt circle, rotating arm, 3s cycle
- Title "DRONE COMMANDER" types in letter-by-letter
- Loading bar: "INITIALIZING SYSTEMS…" → "LOADING DATABASE…" → "CALIBRATING SENSORS…"
- Error state: DB fail → error overlay with retry button

### S01 — Main Menu

- Layout: Centered vertical list of card-style action buttons
- Buttons: Quick Game (green), Scenario (cyan), Campaign (amber, disabled "SOON"), Load Game (gray)
- Bottom: Settings (⚙), How To Play (?)
- Call sign display: `CALL SIGN: {NAME}` with edit icon (✎)
- Version display: `v3.1-D10` caption

### Call Sign Screen (first launch only)

- Input: 3–12 chars, alphanumeric + hyphen, auto-uppercase
- Font: Share Tech Mono, 28pt, green text
- Recent call signs: pill chips (if history exists)
- Skip option: "Continue as UNKNOWN"

### S02 — Drone Selection

- Layout: Scrollable grid/list of drone cards
- Filtering: By class, by country
- Card: Name, country flag, class badge, altitude range, capability icons, fuel mini-bar
- Tap to select → S03

### S03 — Loadout Configuration

- Top: Selected drone info panel
- Below: Hardpoint stations with tap-to-select
- Weapon selector: weapon name, type, compatible targets, DRM, restrictions
- Grey out incompatible weapons
- Validation: at least one weapon or kit, exclusivity rules, quantity limits
- "Ready for Launch" → S04

### S04 — Mission Briefing

- Split layout: scenario info top, drone+loadout summary bottom
- Scenario name, description, narrative, primary objective
- "Launch Mission" → S05

### S05 — Game Board (Primary Game Screen)

**Layout zones:**

```
┌─────────────────────────────┐
│  TOP BAR                    │  ← Drone name, cycle#, score
├─────────────────────────────┤
│  STATUS STRIP               │  ← Fuel bar, SI bar, Sensors,
│                             │     COMMS, VIS/RCS, Altitude
├─────────────────────────────┤
│  MAIN ACTION AREA           │  ← Cards, dice, decisions
│  (varies by current box)    │
├─────────────────────────────┤
│  BOX PROGRESS INDICATOR     │  ← B0 ● B1 ● B2 ● B3 ● B4 ● B5
├─────────────────────────────┤
│  ACTION LOG (last 3 lines)  │
└─────────────────────────────┘
```

**Status strip (6 indicators):**

| Indicator | Display | Behavior |
|-----------|---------|----------|
| Fuel | Color bar (4-band) | Width decreases |
| SI | Numeric + bar | Red pulse when damaged |
| Sensors | Numeric + icon (0–9) | Amber when degraded |
| COMMS | Numeric + icon (0–5) | Warning when > 2 |
| VIS/RCS | Numeric + icon | Danger at high values |
| Altitude | Text badge: VLOW/LOW/MED/HIGH | Tappable in B1/B3 |

**Box progress indicator colors:**

| Box | Color | Hex |
|-----|-------|-----|
| B0 | Cyan | `#06B6D4` |
| B1 | Blue | `#3B82F6` |
| B2 | Purple | `#8B5CF6` |
| B3 | Pink | `#EC4899` |
| B4 | Red | `#EF4444` |
| B5 | Orange | `#F97316` |

### S06 — Post-Scenario Briefing

- Outcome header: "MISSION COMPLETE" (green) / "DRONE DESTROYED" (red) / "FORCED RTB" (amber)
- 6 mandatory sections (see §7.3)
- Actions: "Return to Menu" / "Replay Mission"

### S07 — Scenario Browser

- Scrollable list of scenario cards
- Card: Name, description, campaign, assigned drone
- Filter by campaign name
- Tap → S02

### S08 — Scenario Editor

- 7-step wizard (see §12.3)

### S09 — Settings

- Theme toggle (MILSTD dark / Standard)
- Sound on/off

### S10 — About / Credits

- Version, game designer credit, app developer credit

---

## 15. Game State Data Model

```
GameState {
  currentBox: enum (B0, B1, B2, B3, B4, B5)
  cycleCount: int
  drone: DroneState {
    droneId: int
    droneName: String
    droneClass: enum (A, B, C, D)
    maxAltitudes: List<Altitude>
    altitude: enum (VLOW, LOW, MEDIUM, HIGH)
    fuel: int
    structuralIntegrity: int
    maxStructuralIntegrity: int
    sensorsDamage: int (max 9)
    commsDamage: int (max 5)
    visRcs: int
    capabilities: DroneCapabilities {
      hasAeasa: bool
      hasSatcom: bool
      hasCommsRedundancy: bool
      hasAutonomousAI: bool
      hasBuiltinFoLaze: bool
    }
  }
  loadout: List<LoadoutSlot> {
    weaponName: String
    weaponType: String
    quantity: int
    remainingQty: int
    fireRange: String
    fireAltitude: List<Altitude>
    drmByTarget: Map<TargetType, int>
  }
  currentTarget: TargetCard?
  currentThreat: ThreatCard?
  currentCombatCard: CombatCard?
  attackMode: enum (STANDOFF, CLOSE_IN, FO_LAZE)?
  decks: DeckState {
    targetDeck: List<TargetCard>
    targetDiscard: List<TargetCard>
    targetDestroyed: List<TargetCard>
    threatDeck: List<ThreatCard>
    threatDiscard: List<ThreatCard>
    combatDeck: List<CombatCard>
    combatDiscard: List<CombatCard>
  }
  score: int
  actionLog: List<LogEntry>
  commsCheckPenalty: int (0 or -1, resets each cycle)
  gameEndReason: enum? (
    DESTROYED, UNCONTROLLABLE, NO_FUEL,
    TARGETS_EXHAUSTED, VOLUNTARY_RTB, OBJECTIVES_COMPLETE,
    NO_MUNITIONS
  )
}
```

---

## 16. State Machine Transitions

| From | To | Trigger | Side Effects |
|------|----|---------|-------------|
| `B0` | `B1` | COMMS check passed | Set commsCheckPenalty if degraded |
| `B0` | `GAME_OVER` | COMMS check ≥ 6 | gameEndReason = UNCONTROLLABLE |
| `B1` | `B2` | Combat card resolved, fuel > 0 | Altitude may change |
| `B1` | `FORCED_RTB` | fuel = 0 | gameEndReason = NO_FUEL |
| `B2` | `B1` | Player retreats | Discard target + threat |
| `B2` | `B3` | Player engages | Keep cards for B4/B5 |
| `B2` | `TARGETS_EXHAUSTED` | No target cards left | gameEndReason = TARGETS_EXHAUSTED |
| `B3` | `B4` | Combat card resolved | Altitude may change |
| `B4` | `B5` | Attack resolved | Fuel cost, weapon consumed |
| `B4` | `GAME_OVER` | SAM reaction destroys drone | gameEndReason = DESTROYED |
| `B5` | `B0` | Continue (fuel + ammo) | cycleCount++, apply fuel/damage |
| `B5` | `RTB` | Player chooses | gameEndReason = VOLUNTARY_RTB |
| `B5` | `GAME_OVER` | Evasion damage ≥ SI | gameEndReason = DESTROYED |

---

## 17. Design System

### 17.1 Color Palette

| Token | Hex | Usage |
|-------|-----|-------|
| `bg-primary` | `#0A0E14` | Main app background |
| `bg-secondary` | `#111927` | Panel backgrounds |
| `bg-tertiary` | `#1A2332` | Card surfaces |
| `surface` | `#1E293B` | Input/card backgrounds |
| `accent-primary` | `#00E676` | Active HUD, success |
| `accent-secondary` | `#40C4FF` | Links, info |
| `accent-warm` | `#FFB300` | Warnings |
| `accent-danger` | `#FF1744` | Damage, errors |
| `text-primary` | `#E0E7EF` | Main text |
| `text-secondary` | `#8B9BB4` | Secondary labels |
| `text-muted` | `#4A5568` | Disabled text |
| `text-hud` | `#00E676` | HUD overlays |
| `border-default` | `#2D3F56` | Default borders |
| `border-active` | `#00E676` | Active focus |

### 17.2 Typography

| Token | Font | Size | Weight |
|-------|------|------|--------|
| Display titles | Rajdhani | 32pt | 700 |
| Section headers | Rajdhani | 24pt | 600 |
| Card titles | Rajdhani | 20pt | 600 |
| Body text | IBM Plex Sans | 16pt | 400 |
| Numeric readouts | IBM Plex Mono | 28pt | 700 |
| HUD overlays | Share Tech Mono | 14pt | 500 |
| Uppercase labels | IBM Plex Sans | 10pt | 600 |

### 17.3 Spacing (4pt grid)

| Token | Value |
|-------|-------|
| `space-1` | 4pt |
| `space-2` | 8pt |
| `space-3` | 12pt |
| `space-4` | 16pt |
| `space-6` | 24pt |
| `space-8` | 32pt |
| `space-12` | 48pt |

### 17.4 Border Radius

| Token | Value | Usage |
|-------|-------|-------|
| `radius-xs` | 2pt | Badges |
| `radius-sm` | 4pt | Buttons |
| `radius-md` | 6pt | Cards |
| `radius-lg` | 8pt | Modals |

> Small radii reinforce the MILSTD aesthetic — no pill shapes.

### 17.5 Animation Specs

| Animation | Duration | Type |
|-----------|----------|------|
| Card flip | 600ms | 3D Y-axis rotation |
| Dice roll | 1200ms | Bounce physics |
| Box transition | 400ms | Slide + fade |
| Damage pulse | 300ms × 3 | Red glow |
| Fuel decrease | 500ms | Width + color shift |
| HIT result | 800ms | Scale + particle burst |
| MISS result | 500ms | Shake + fade |
| VP increment | 400ms | Counter roll-up |
| Drone destroyed | 2000ms | Full-screen overlay |

### 17.6 Card Display Specs

| Card Type | Border Color | Header BG |
|-----------|-------------|-----------|
| Target | `#40C4FF` (blue) | `#40C4FF15` |
| Threat | `#FF1744` (red) | `#FF174415` |
| Combat | `#FFB300` (amber) | `#FFB30015` |

Card dimensions: 280pt × 380pt, 6pt radius, 2px border.

---

## 18. Database Schema & Contents

### 18.1 Database File

- **Path**: `assets/db/ob3.db`
- **Engine**: SQLite 3
- **Tables**: 12

### 18.2 Complete Schema

```sql
-- 1. DRONES (28 rows)
CREATE TABLE drones (
  id INT,
  category TEXT,
  name TEXT,
  country TEXT,
  "range" TEXT,
  stations INT,
  max_payload TEXT,
  station_weight_limits TEXT,
  altitude TEXT,                    -- CSV: "LOW, MEDIUM, HIGH"
  opt1_wpn1_name TEXT, opt1_wpn1_qty INT,
  opt1_wpn2_name TEXT, opt1_wpn2_qty INT,
  opt2_wpn1_name TEXT, opt2_wpn1_qty INT,
  opt2_wpn2_name TEXT, opt2_wpn2_qty INT,
  opt3_wpn1_name TEXT, opt3_wpn1_qty INT,
  opt3_wpn2_name TEXT, opt3_wpn2_qty INT,
  opt4_wpn1_name TEXT, opt4_wpn1_qty INTEGER,
  opt4_wpn2_name TEXT, opt4_wpn2_qty INTEGER,
  opt5_wpn1_name TEXT, opt5_wpn1_qty INTEGER,
  opt5_wpn2_name TEXT, opt5_wpn2_qty INTEGER,
  max_structural_integrity INTEGER DEFAULT 1000,
  has_builtin_fo_laze INTEGER NOT NULL DEFAULT 1,
  drone_class TEXT NOT NULL DEFAULT 'B',
  has_aeasa_radar INTEGER NOT NULL DEFAULT 0,
  has_satcom INTEGER NOT NULL DEFAULT 0,
  has_comms_redundancy INTEGER NOT NULL DEFAULT 0,
  has_autonomous_ai INTEGER NOT NULL DEFAULT 0,
  description TEXT
  -- MISSING: endurance_hours column (must be added via migration)
);

-- 2. WEAPONS (32 rows)
CREATE TABLE weapons (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  wpn_type TEXT,
  name TEXT,
  description TEXT,
  targets TEXT,
  fire_range TEXT,
  fire_altitude TEXT,
  drm_truck INTEGER NOT NULL DEFAULT 0,
  drm_personnel INTEGER NOT NULL DEFAULT 0,
  drm_afv INTEGER NOT NULL DEFAULT 0,
  drm_sam INTEGER NOT NULL DEFAULT 0,
  drm_tank INTEGER NOT NULL DEFAULT 0,
  drm_artillery INTEGER NOT NULL DEFAULT 0,
  drm_hq_bunker INTEGER NOT NULL DEFAULT 0,
  drm_vip INTEGER NOT NULL DEFAULT 0,
  drm_air INTEGER NOT NULL DEFAULT 0
);

-- 3. COMBAT_CARDS (37 rows)
CREATE TABLE combat_cards (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  card_number TEXT UNIQUE NOT NULL,
  card_type TEXT NOT NULL,
  card_name TEXT NOT NULL,
  instruction TEXT NOT NULL,
  image BLOB,
  back_image BLOB,
  instructions TEXT,
  attribute_effect TEXT                -- Parseable: "Attack DRM: +2\nApply +2..."
);

-- 4. TARGET_CARDS (111 rows)
CREATE TABLE target_cards (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  card_number TEXT UNIQUE NOT NULL,
  card_type TEXT NOT NULL,
  sub_category TEXT NOT NULL,          -- AFV, AIR, ARTILLERY, etc.
  card_name TEXT NOT NULL,
  vp REAL NOT NULL,
  instruction TEXT,                    -- May contain column shift rules
  image BLOB,
  back_image BLOB,
  instructions TEXT,
  altitude_restriction TEXT,
  weapon_type TEXT
);

-- 5. THREAT_CARDS (36 rows)
CREATE TABLE threat_cards (
  card_number TEXT PRIMARY KEY,
  card_type TEXT,
  sub_category TEXT,                   -- AAA, CAP, DRONE GUN, SAM, SMALL ARMS
  card_name TEXT,
  instruction TEXT,                    -- Parsed for altitude/damage rules
  image BLOB,
  back_image BLOB,
  instructions TEXT,
  altitude_restriction TEXT,
  column_shift TEXT,                   -- LEFT or RIGHT
  cshift_by INTEGER                    -- Number of shifts
);

-- 6. SCENARIOS
CREATE TABLE scenarios (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  campaign_name TEXT,
  description TEXT,
  narrative TEXT,
  drone_id INTEGER REFERENCES drones(id),
  primary_objective TEXT,
  primary_objective_zone INTEGER,
  primary_objective_card_name TEXT,
  primary_objective_weapon_req TEXT,
  scoring_mode TEXT DEFAULT 'MAXIMUM_KILL',
  combat_no_event_count INTEGER DEFAULT 42,
  combat_event_count INTEGER DEFAULT 8,
  reinforcement_rule TEXT,
  special_rules TEXT
);

-- 7-12. SCENARIO SUB-TABLES
CREATE TABLE scenario_zones (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  scenario_id INTEGER NOT NULL REFERENCES scenarios(id),
  zone_number INTEGER NOT NULL,
  has_star INTEGER NOT NULL DEFAULT 0,
  terrain_desc TEXT
);

CREATE TABLE scenario_target_deck (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  scenario_id INTEGER NOT NULL REFERENCES scenarios(id),
  zone_number INTEGER NOT NULL,
  target_card_name TEXT NOT NULL,
  target_type TEXT NOT NULL,
  vp REAL NOT NULL DEFAULT 0,
  quantity INTEGER NOT NULL DEFAULT 0,
  special_rules TEXT
);

CREATE TABLE scenario_threat_deck (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  scenario_id INTEGER NOT NULL REFERENCES scenarios(id),
  zone_number INTEGER NOT NULL,
  threat_card_name TEXT NOT NULL,
  threat_type TEXT NOT NULL,
  quantity INTEGER NOT NULL DEFAULT 0,
  special_rules TEXT
);

CREATE TABLE scenario_target_ranges (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  scenario_id INTEGER NOT NULL REFERENCES scenarios(id),
  zone_number INTEGER NOT NULL,
  target_type TEXT NOT NULL,
  range_min INTEGER,
  range_max INTEGER,
  is_na INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE scenario_threat_ranges (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  scenario_id INTEGER NOT NULL REFERENCES scenarios(id),
  zone_number INTEGER NOT NULL,
  threat_type TEXT NOT NULL,
  range_min INTEGER,
  range_max INTEGER,
  is_na INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE scenario_loadouts (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  scenario_id INTEGER NOT NULL REFERENCES scenarios(id),
  loadout_number INTEGER NOT NULL,
  weapon_name TEXT NOT NULL,
  quantity INTEGER NOT NULL,
  constraints TEXT,
  notes TEXT
);
```

---

## 19. File Structure & Architecture

### 19.1 Architecture Pattern: BLoC + Freezed

| Layer | Responsibility |
|-------|---------------|
| UI Layer | Stateless widgets rendering BLoC state |
| BLoC Layer | Game logic, box transitions, dice, CRT lookups |
| Repository Layer | DB access (sqflite), deck management |
| Model Layer | Freezed immutable data classes |

### 19.2 BLoC Organization

| BLoC | Responsibility |
|------|---------------|
| `GameBloc` | Master game loop (B0–B5 transitions) |
| `DroneSelectionBloc` | Drone browsing, filtering |
| `LoadoutBloc` | Weapon config, validation |
| `ScenarioBloc` | Scenario browsing, loading, editing |
| `SettingsBloc` | Theme, sound preferences |

### 19.3 Recommended File Structure

```
lib/
├── main.dart
├── app.dart
├── core/
│   ├── theme/
│   │   ├── ob3_colors.dart
│   │   ├── ob3_typography.dart
│   │   ├── ob3_spacing.dart
│   │   ├── ob3_shapes.dart
│   │   └── ob3_theme.dart
│   ├── constants/
│   │   ├── game_constants.dart
│   │   └── crt_tables.dart
│   └── utils/
│       ├── dice.dart
│       └── drm_calculator.dart
├── data/
│   ├── database/
│   │   ├── db_provider.dart
│   │   └── db_constants.dart
│   ├── models/
│   │   ├── drone.dart
│   │   ├── weapon.dart
│   │   ├── target_card.dart
│   │   ├── threat_card.dart
│   │   ├── combat_card.dart
│   │   ├── scenario.dart
│   │   ├── game_state.dart
│   │   └── loadout_slot.dart
│   └── repositories/
│       ├── drone_repository.dart
│       ├── weapon_repository.dart
│       ├── card_repository.dart
│       └── scenario_repository.dart
├── game/
│   ├── bloc/
│   │   ├── game_bloc.dart
│   │   ├── game_event.dart
│   │   └── game_state.dart
│   ├── engine/
│   │   ├── game_engine.dart
│   │   ├── deck_manager.dart
│   │   └── damage_calculator.dart
│   └── widgets/
│       ├── status_strip.dart
│       ├── fuel_bar.dart
│       ├── box_progress_indicator.dart
│       ├── dice_roll_animation.dart
│       ├── card_display.dart
│       ├── decision_panel.dart
│       ├── altitude_selector.dart
│       ├── attack_mode_selector.dart
│       ├── weapon_selector.dart
│       ├── drm_breakdown.dart
│       ├── damage_cascade_display.dart
│       └── action_log.dart
├── screens/
│   ├── splash_screen.dart
│   ├── main_menu_screen.dart
│   ├── drone_selection_screen.dart
│   ├── loadout_config_screen.dart
│   ├── mission_briefing_screen.dart
│   ├── game_board_screen.dart
│   ├── post_scenario_screen.dart
│   ├── scenario_browser_screen.dart
│   ├── scenario_editor_screen.dart
│   ├── settings_screen.dart
│   └── about_screen.dart
└── shared/
    └── widgets/
        ├── action_button.dart
        ├── game_card.dart
        ├── stat_indicator.dart
        └── section_header.dart
```

---

## 20. Known Data Gaps & Blockers

> [!CAUTION]
> These issues MUST be resolved before affected features can ship.

### 20.1 Database Issues

| # | Issue | Severity | Status |
|---|-------|----------|--------|
| 1 | `endurance_hours` column **missing** from `drones` table | 🔴 BLOCKER | Migration needed |
| 2 | `max_structural_integrity` = 1000 for **all** drones (placeholder) | 🔴 BLOCKER | Correct values in §10.1 |
| 3 | 6 drones have **empty** `altitude` field (IDs 12,15,18,24,25,26) | 🔴 BLOCKER | Need designer input |
| 4 | Weapon DRM columns **all zeros** (except 2 weapons) | 🟡 HIGH | May be intentional or missing |
| 5 | `has_builtin_fo_laze` discrepancy vs designer's confirmed list | 🟡 HIGH | Reconcile |
| 6 | 37 combat cards (2 overlapping sets) — which set to use? | 🟡 HIGH | Clarify with designer |

### 20.2 CRT Table Gaps

| # | Issue | Status |
|---|-------|--------|
| 7 | Counterfire LOW row — **all cells empty** | ⬜ OPEN |
| 8 | SAM Counterfire LOW row — **all cells empty** | ⬜ OPEN |
| 9 | VLOW rows — resolved for Attack & Counterfire CRTs | ✅ RESOLVED |

### 20.3 Open Design Questions

| # | Question | Status |
|---|----------|--------|
| 10 | Fuel base depletion rate per cycle (scenario-defined) | ❌ OPEN |
| 11 | Height modifier values (hit%, evasion%, dmg multiplier) | ❌ OPEN |
| 12 | VP values — on cards or chart? | ✅ On individual cards |
| 13 | Re-arm mid-scenario | ✅ No |
| 14 | Rank/rating thresholds | ❌ Progression system defined, thresholds TBD |

---

## 21. Reference Documents

| Document | Path | Purpose |
|----------|------|---------|
| Rulebook | `docs/game-rules/rulebook.md` | Source of truth for all game rules |
| Game Loop Diagram | `docs/game-rules/game_loop_diagram.md` | Mermaid B0–B5 flowchart |
| Rulebook Gaps | `docs/game-rules/rulebook_gaps.md` | All Q&A with designer answers |
| Functional Spec | `docs/specs/functional-spec.md` | Box-by-box mechanics, data |
| Functional Spec (v2) | `project-specs/functional-spec.md` | Alternate location |
| UX Architecture | `docs/specs/ux-architecture.md` | Screens, components, state |
| Design System | `docs/specs/design-system.md` | Colors, typography, widgets |
| Game Engine API | `docs/specs/game-engine-api.md` | Callable interface reference |
| Scenario Editor | `docs/specs/scenario-editor-survey.md` | 7-step wizard spec |
| Agent Work Orders | `docs/specs/agent-work-orders.md` | Per-agent task assignments |
| Task Breakdown | `project-tasks/task-breakdown.md` | 27-task implementation plan |
| Architecture | `ARCHITECTURE.md` | System design overview |
| Contributing | `CONTRIBUTING.md` | Conventions and standards |
| Agent Roster | `project-specs/agent-roster.md` | 8-agent pipeline |

### Database Files

| File | Path | Contents |
|------|------|----------|
| Main DB | `assets/db/ob3.db` | 12 tables, all game data |
| Secondary DB | `assets/db/ob3.db` | Empty (unused) |

---

*PRD Version 1.0 — 2026-03-12*
*Author: OB3-TechWriter*
*This document supersedes all prior specifications for implementation purposes.*
