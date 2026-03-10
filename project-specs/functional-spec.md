# OB3 Drone Commander — Functional Specification

> **Author**: OB3-ProjectManager (BA)
> **Date**: 2026-03-10
> **Source**: rulebook.md (V3.1-D10), ob3-setup.md, drone_commander_cards.db
> **Scope**: v1.0 — Solitaire Quick Game + Scenario Game

---

## 1. Executive Summary

Drone Commander is a solitaire board-game adaptation for iOS (Flutter/Dart). The player commands a UCAV through a repeating mission loop (B0→B5) to find, fix, and finish enemy targets while surviving counterfire threats. The v1.0 scope covers full rulebook mechanics in two play modes: **Solitaire Quick Game** and **Scenario Game**. Campaign mode and 2+ Player mode are deferred to v1.1.

---

## 2. Scope Definition (v1.0)

### 2.1. In Scope

| Feature | Rulebook Section |
|---------|-----------------|
| Full B0→B5 game loop | §6.1–6.3 |
| All combat mechanics (attack, evasion, damage) | §6.4 |
| All 28 drones with loadout configuration | §2.6, §6.4.1 |
| All card types: 18 combat, 111 target, 36 threat | §2.3–2.7 |
| Dice rolling (1D6, 2D10) with DRM modifiers | §3 |
| Target Acquisition & Threat Determination | §6.4.2 |
| Drone Attack CRT | §6.4.3 |
| Counterfire & Evasion CRT | §6.4.4 |
| SAM Reaction Shot (optional rule) | §6.4.3.1 |
| Damage cascading (structure → sensors → comms → VIS) | §6.4.5 |
| Scoring (Maximum Kill & Quick Kill) | §7 |
| Solitaire Quick Game mode | §5.1 |
| Scenario Game mode (load from DB) | §5.3 |
| Scenario editor (survey-form input) | §8, Q6 answer |
| 4 altitude levels: VLOW, LOW, MEDIUM, HIGH | Q9 answer |
| Fuel as color-bar UI (green→yellow→red) | Q7 note |

### 2.2. Out of Scope (v1.1+)

| Feature | Reason |
|---------|--------|
| Campaign mode (zone territory) | Q4 — designer deferred |
| 2+ Player competitive mode | Q5 — designer deferred |
| Campaign map rendering | Dependent on campaign mode |

---

## 3. Game Hierarchy

```
Campaign (v1.1)
  └── Scenario (a mission with objectives, card decks, and rules)
        └── Cycle (one complete loop B0 → B5 and back)
```

- A **Scenario** contains one or more **Cycles**
- A **Cycle** = one traversal from B0 (In Transit) → B5 (Evasive Action) and back to B0

---

## 4. Game Setup (§4)

### 4.1. Pre-Game Flow

1. **Select Play Mode** — Solitaire Quick Game _or_ Scenario Game
2. **Select Drone** — from 28 available drones (filtered by scenario if applicable)
3. **Configure Loadout** — choose weapon/kit markers per drone's loadout options
4. **Initialize Drone State:**
   - Position: B0
   - Altitude: HIGH (or drone's highest available)
   - Integrity Damage: 0
   - Sensors Damage: 0
   - VIS/RCS: 0
   - COMMS Damage: 0
   - Fuel: drone's endurance value (see §4.3 below)
5. **Build Card Decks:**
   - Solitaire: use full target/threat/combat card pools
   - Scenario: use scenario-specific deck compositions from DB

### 4.2. Loadout Selection Rules

**Class restrictions** — weapons marked with class codes can only be mounted on drones of that class or higher:

| Marker | Rule |
|--------|------|
| `(*A)` | A-class only |
| `(*B)` | B-class or bigger |
| `(*C)` | C-class or bigger |
| `(*D)` | D-class or bigger |
| `(%)` | Exclusive — no other weapon OR kit loadout if carried |
| `(+)` | +2 fuel per cycle if carried |

**Attack mode restrictions** (from weapon data):

| Restriction | Meaning |
|-------------|---------|
| Close-In only | Cannot be used in Stand-Off or FO/Laze |
| Stand-Off only | Cannot be used in Close-In or FO/Laze |
| AA only | Can only target AIR sub-category |

**Loadout type vs target compatibility** (§6.4.1):

| Loadout Type | Valid Target Types |
|--------------|-------------------|
| Armor Piercing/ATGW | AFV, TANK, TRUCK |
| Thermobaric | PERSONNEL, TRUCK, AFV (penalty vs heavier armor) |
| AA Warfare | AIR only |
| Anti-Personnel | PERSONNEL only |
| Bunker Buster | HQ-BUNKER |
| Multi-Purpose | All types |
| Anti-Shipping | Naval targets only |
| KIT | Special (scenario-defined) |

### 4.3. Fuel

> **Designer Answer (Q7)**: Fuel = endurance in hours per drone.

> [!IMPORTANT]
> The `drones` table currently has NO `endurance_hours` column. This must be added and populated before implementation.
>
> UI: Fuel is displayed as a **color bar** (green → yellow → red), NOT as a numeric value.

---

## 5. Game Loop — Box-by-Box Mechanics

### 5.0. B0 — In Transit

**First cycle of scenario:**
- Place drone at B0, altitude = HIGH (or max available)
- All card decks face-down on board

**Returning from B5 (subsequent cycles):**
- If COMMS Damage > 2 → execute **COMMS Check** (see §5.7.3)

---

### 5.1. B1 — Search

| # | Action | Type | Details |
|---|--------|------|---------|
| 1 | Change altitude | OPTIONAL | ±1 level costs 1F per level changed |
| 2 | Draw combat card | REQUIRED | Execute card instructions immediately |

- If combat card deck empty → reshuffle discard pile, place face-up
- After completing → move to B2

---

### 5.2. B2 — Target Acquisition & Threat Determination

| # | Action | Type | Details |
|---|--------|------|---------|
| 1 | Spend 1F | REQUIRED | Deduct 1 fuel |
| 2 | Target detection | REQUIRED | Roll 2D10 → apply DRM → consult Target Acquisition Table → draw matching card |
| 3 | Threat determination | REQUIRED | Roll 2D10 → apply DRM → consult Threat Determination Table → draw matching card |

**Target Acquisition DRM modifiers:**
- +10 if drone has AEASA Radar
- +10 if COMMS Damage = 0
- −10 per point of COMMS damage (cumulative)

**Target Acquisition Table** (default — scenarios may override via `scenario_target_ranges`):

| Roll Range | Target Type |
|------------|-------------|
| ≤18 | TRUCK |
| 19–35 | PERSONNEL |
| 35–45 | AFV |
| 46–55 | SAM |
| 56–70 | TANK |
| 71–79 | ARTILLERY |
| 80–91 | HQ/BUNKER |
| 91–99 | VIP |
| ≥100 | AERIAL TARGET |

**Fallback rule**: If no card of the rolled type exists → look for next **lower** range type first, then **higher**.

**Threat Determination DRM modifiers:**
- +10 for each 2 points of VIS/RCS (i.e., `+10 * floor(VIS/2)`)

**Threat Determination Table** (default — scenarios may override via `scenario_threat_ranges`):

| Roll Range | Threat Type |
|------------|-------------|
| ≤19 | Small Arms |
| 20–65 | AAA |
| 66–85 | SAM |
| 86–95 | CAP |
| ≥96 | Anti-Drone Weapon |

**Fallback rule**: Same as target acquisition (lower first, then higher).

**Threat card reshuffle**: If all threat cards used but target cards remain and primary mission not done → reshuffle used threat cards back into deck.

#### 5.2.1. Commander's Decision Point

After both cards are revealed:

- **ENGAGE** → continue to B3
- **DISENGAGE** → discard both cards to Discarded pile → return to **B1** (NOT B0)

---

### 5.3. B3 — Positioning

| # | Action | Type | Details |
|---|--------|------|---------|
| 1 | Change altitude | OPTIONAL | ±1 level costs 1F per level changed |
| 2 | Draw combat card | REQUIRED | Execute card instructions immediately |

- If combat card deck empty → reshuffle, place face-up
- After completing → move to B4

---

### 5.4. B4 — Drone Attack

**Procedure:**

1. **Select attack mode**: Stand-Off, Close-In, or FO/Laze
   - Must have appropriate weapon (FO/Laze requires built-in FO/Laze capability or KIT)
   - AA missiles → Stand-Off only
   - Torpedoes/Sonobuoys → Close-In only
   - Anti-shipping missiles → Stand-Off only
2. **Select weapon** — must be compatible with target type and attack mode
3. **Select altitude** — VLOW, LOW, MEDIUM, or HIGH
   - AA missiles → MEDIUM or HIGH only
   - Must be within drone's available altitude range
4. **Roll 1D6** → apply all DRM:
   - Weapon DRM (per-target-type from `weapons` table columns `drm_*`)
   - Combat card DRM (if active)
   - Target card DRM (if any)
   - Scenario-specific DRM (if any)
5. **Consult Drone Attack CRT** — find intersection of (attack mode × altitude × final DRM)
6. **Apply column shifts** — shift 1 RIGHT for each 2 points of Sensor Damage
7. **Read result**:
   - `HIT` → target destroyed → move Target Card to **Destroyed pile** → add VP
   - No HIT → move Target Card to **Discarded pile**
8. **Consume resources**: deduct fuel per cell value, remove used weapon marker

**Drone Attack CRT** (from rulebook — needs VLOW row added):

|  | Stand-Off ||||||| Close-In ||||||| FO/Laze ||||||
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| **ALT/DRM** | **1** | **2** | **3** | **4** | **5** | **6** | **1** | **2** | **3** | **4** | **5** | **6** | **1** | **2** | **3** | **4** | **5** | **6** |
| **VLOW** | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| **LOW** | 1F | 1F | 1F | 1F | 1F | 1F | 2F | 2F | 2F | 2F | 2F | 2F+HIT | 3F | 3F | 3F | 3F | 3F | 3F+HIT |
| **MED** | 1F | 1F | 1F | 1F | 1F | 1F+HIT | 2F | 2F | 2F | 2F | 2F+HIT | 2F+HIT | 3F | 3F | 3F+HIT | 3F+HIT | 3F+HIT | 3F+HIT |
| **HIGH** | 1F | 1F | 1F | 1F | 1F+HIT | 1F+HIT | 2F | 2F | 2F | 2F+HIT | 2F+HIT | 2F+HIT | 3F | 3F | 3F | 3F+HIT | 3F+HIT | 3F+HIT |

> ⬜ = VLOW row values TBD — **DILEK Clearance Item #3**

**Column shift rule**: Shift 1 RIGHT for each 2 points of Sensor Damage.
- DRM is clamped between 1 and 6 after shifting.

---

### 5.5. B5 — Evasive Action / Counterfire

**Procedure:**

1. **Roll 1D6** → apply DRM from:
   - Threat card modifiers (column shift value)
   - Combat card DRM (if active)
   - Scenario-specific DRM (if any)
2. **Consult Counterfire & Evasive Action CRT** (attack mode × altitude × final DRM)
3. **Apply column shifts** — shift 1 LEFT for each 2 points of VIS/RCS
4. **Read result**:
   - `—` = no damage (evaded)
   - `XD+YF` = take X damage, consume Y fuel
5. **Register damage** to Drone Info Card (see §5.7)
6. **Consume fuel** per cell value
7. **Discard Threat Card** to Discarded pile

**Counterfire & Evasive Action CRT** (needs VLOW row + LOW row corrections):

|  | Stand-Off ||||||| Close-In ||||||| FO/Laze ||||||
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| **ALT/DRM** | **1** | **2** | **3** | **4** | **5** | **6** | **1** | **2** | **3** | **4** | **5** | **6** | **1** | **2** | **3** | **4** | **5** | **6** |
| **VLOW** | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| **LOW** | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| **MED** | — | — | — | — | — | 1D+1F | — | — | — | — | 1D+1F | 2D+F | — | — | 1D+1F | 1D+1F | 1D+1F | 1D+1F |
| **HIGH** | — | — | — | — | 1D+2F | 1D+2F | — | — | — | 1D+1F | 1D+1F | 1D+1F | — | — | — | 1D+1F | 1D+1F | 1D+1F |

> ⬜ = VLOW row TBD + LOW row needs correction — **DILEK Clearance Items #1 & #3**

**Column shift rule**: Shift 1 LEFT for each 2 points of VIS/RCS.

---

### 5.6. SAM Reaction Shot (Optional Rule, §6.4.3.1)

**Trigger**: If target is a SAM type AND attack at B4 **misses** (SAM not destroyed).

**Procedure:**
1. Roll 1D6
2. Add current VIS value as DRM
3. If final DRM ≥ 6 → SAM fires reaction shot
4. Consult SAM Special Counterfire Table
5. Player must survive BOTH this AND the normal B5 counterfire

**SAM Target Unit Special Counterfire CRT** (needs VLOW + LOW corrections):

|  | Stand-Off ||||||| Close-In ||||||| FO/Laze ||||||
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| **ALT/DRM** | **1** | **2** | **3** | **4** | **5** | **6** | **1** | **2** | **3** | **4** | **5** | **6** | **1** | **2** | **3** | **4** | **5** | **6** |
| **VLOW** | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| **LOW** | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| **MED** | — | — | — | — | — | — | — | — | — | — | — | 1D+1F | — | — | — | — | 1D+1F | 1D+1F |
| **HIGH** | — | — | — | — | — | 1D+2F | — | — | — | — | 1D+1F | 1D+1F | — | — | — | — | 1D+1F | 1D+1F |

> ⬜ = VLOW + LOW rows TBD — **DILEK Clearance Items #2 & #3**
> Column shift: 1 LEFT for each 2 points of VIS/RCS

---

### 5.7. Damage System (§6.4.5)

Damage cascades through four subsystems:

```
Structural Integrity Damage
    ├── Sensors Damage (every 2 structural → +1 sensor, max 9)
    ├── COMMS Damage (every 3 structural → +1 comms, max 5)
    └── VIS/RCS Increase (every 1 comms or 1 sensor damage → +1 VIS)
```

#### 5.7.1. Structural Integrity

- Each `1D` damage → add 1 to Structural Integrity Damage counter
- If cumulative damage ≥ drone's max structural integrity → **drone destroyed, game ends**

#### 5.7.2. Sensors Damage

- For every **2 points** of total Structural Integrity Damage → +1 Sensors Damage (max: 9)
- Formula: `sensorsDamage = min(floor(structuralDamage / 2), 9)`
- Effect: For every **4 points** of Sensors Damage → −1 to Drone Attack dice roll
- Optional sensor kits do NOT take damage

#### 5.7.3. COMMS Damage

- For every **3 points** of total Structural Integrity Damage → +1 COMMS Damage (max: 5)
- Formula: `commsDamage = min(floor(structuralDamage / 3), 5)`
- If COMMS Damage > 2 → **COMMS Check** at B0 each cycle:

**COMMS Check procedure:**
1. Roll 1D6
2. Apply DRM modifiers:
   - −1 if drone has SATCOM
   - −1 if drone has COMMS Redundancy
   - −1 if drone has Autonomous DM AI
   - (all cumulative)
3. Consult COMMS Check Table:

| Final DRM | Result |
|-----------|--------|
| ≤2 | All OK — continue |
| 3, 4, 5 | Controllable with difficulty: −1 to Drone Attack roll this cycle |
| ≥6 | **Drone uncontrollable — destroyed. GAME ENDS.** |

#### 5.7.4. VIS/RCS Increase

- For every **1 point** of COMMS Damage → +1 VIS
- For every **1 point** of Sensors Damage → +1 VIS
- Formula: `VIS = commsDamage + sensorsDamage` (plus any combat card adjustments)

---

### 5.8. B5 — Post-Evasion Commander's Decision

If drone survives B5:

| Choice | Action |
|--------|--------|
| **Continue mission** | Move to B0, increment cycle counter. Requires fuel AND ammo. |
| **RTB (Return to Base)** | End scenario. Go to Post-Scenario Briefing. |

---

## 6. Scenario End Conditions (§1.2)

A scenario ends when ANY of these occur:

| Condition | Description |
|-----------|-------------|
| Drone destroyed | Structural integrity or COMMS failure |
| Primary objectives completed | Game prompts "RTB?" |
| Player voluntarily RTBs | At B5 decision point |
| Fuel exhausted | Forced RTB |
| All target cards expanded | Solitaire only — deck empty |
| No munitions + no FO/Laze capability | Cannot attack at all |

**Post-Scenario:**
- Display **Post-Scenario Briefing** screen (results, score, damage summary)

---

## 7. Scoring (§7)

### 7.1. Maximum Kill Method

Game ends when target card deck is fully expanded. Score = sum of VP from Destroyed Target Card pile.

### 7.2. Quick Kill Method

Game ends when primary objective is completed (regardless of remaining targets or drone state). Score = sum of VP from Destroyed Target Card pile.

### 7.3. Scoring Formula

```
Final Score = Sum(destroyed target VP) − Drone VP value (Solitaire only)
```

> The drone VP subtraction applies only to Solitaire Quick Game (§5.1).

---

## 8. Card Mechanics

### 8.1. Combat Cards (18 total)

Drawn at B1 and B3. Each has instructions that must be executed immediately.

**Deck composition from DB:**
- 6 × "No Event" (cards CC007–CC012) — discard without action
- 12 × Event cards with effects (CC001–CC006, CC013–CC018)

**Reshuffle rule**: When depleted → reshuffle discard pile and place back **face-up**.

**Effect examples from DB:**
- CC001 "WORLD IS WATCHING" — close-in only until next B0
- CC002 "COMMS PROBLEM" — +2 COMMS damage
- CC003 "JAMMED!" — +1 sensor damage permanently
- CC004 "SKILLED OPERATOR" — reset VIS/RCS to 0
- CC005 "IONIZING LAYER" — clear all COMMS damage
- CC006 "ENEMY CAP!" — must fly LOW altitude rest of mission
- CC013 "LOCAL ASSET" — reveal top 3 target cards, pick one
- CC014 "RADIO D/F" — +1 DRM if next target is HQ/BUNKER at Stand-Off
- CC015 "WALKING DEAD" — return last destroyed target to deck
- CC016 "SMOKING ACES" — 1 LEFT shift to attack this cycle
- CC017 "INTRUDER'S FLIGHT" — skip next counterfire this cycle
- CC018 "RADIO CHATTER" — 1 LEFT shift to counterfire if CAP/SAM threat

### 8.2. Target Cards (111 total, 10 sub-categories)

| Sub-Category | Count | VP Range |
|-------------|-------|----------|
| AFV | 18 | 0.5–3.5 |
| AIR | 6 | 2.0–6.0 |
| ARTILLERY | 18 | 0.5–3.5 |
| ENGINEER | 6 | — |
| HQ-BUNKER | 6 | — |
| PERSONNEL | 12 | — |
| SAM | 18 | — |
| TANK | 15 | — |
| TRUCK | 6 | — |
| VIP | 6 | — |

> [!WARNING]
> **ENGINEER** sub-category exists in the DB (6 cards) but is NOT mentioned in the rulebook's Target Acquisition Table. Need designer ruling: does ENGINEER map to an existing range, or is it a scenario-only type?

### 8.3. Threat Cards (36 total, 5 sub-categories)

| Sub-Category | Count |
|-------------|-------|
| AAA | 6 |
| CAP | 12 |
| DRONE GUN | 6 |
| SAM | 6 |
| SMALL ARMS | 6 |

> [!WARNING]
> **DRONE GUN** sub-category exists in the DB (6 cards) but maps to "Anti-Drone Weapon" in the rulebook's Threat Determination Table. Implementation should map `DRONE GUN` → `Anti-Drone Weapon` range (≥96).

**Special threat card rules** from scenario data:
- Small Arms: +3 LEFT column shift, ONLY LOW altitudes
- AAA (ZU-23): ONLY LOW altitudes, any 1D hit is DOUBLED
- SAM (IGLA-S): ONLY LOW AND MEDIUM altitudes, any hit +5D extra

### 8.4. Card Flow Diagram

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
```

---

## 9. Drone Data (from DB)

### 9.1. Drone Capabilities

28 drones, all currently class B. Key capability flags:

| Capability | Column | Effect |
|-----------|--------|--------|
| AEASA Radar | `has_aeasa_radar` | +10 DRM to Target Acquisition |
| SATCOM | `has_satcom` | −1 to COMMS Check DRM |
| COMMS Redundancy | `has_comms_redundancy` | −1 to COMMS Check DRM |
| Autonomous DM AI | `has_autonomous_ai` | −1 to COMMS Check DRM |
| Built-in FO/Laze | `has_builtin_fo_laze` | Can use FO/Laze attack mode without KIT |

**Drones with all 4 capabilities**: MQ-9 REAPER, MQ-9B PROTECTOR, AVENGER, GRAY EAGLE

### 9.2. Loadout Options

Each drone has up to 5 loadout option pairs (opt1–opt5), each with weapon name + quantity. Scenario loadouts may override via `scenario_loadouts` table.

---

## 10. Scenario System

### 10.1. Scenario Data (from DB)

A scenario defines:

| Field | Description |
|-------|-------------|
| `name` | Scenario title |
| `campaign_name` | Parent campaign (v1.1) |
| `description` | Short description |
| `narrative` | Story/briefing text |
| `drone_id` | Assigned drone (FK to `drones`) |
| `primary_objective` | Mission goal description |
| `primary_objective_zone` | Zone where objective must be completed |
| `primary_objective_card_name` | Target card name to find/destroy |
| `primary_objective_weapon_req` | Required weapon type (e.g., THERMOBARIC) |
| `scoring_mode` | MAXIMUM_KILL or QUICK_KILL |
| `combat_no_event_count` | # of "No Event" cards in combat deck |
| `combat_event_count` | # of event cards in combat deck |
| `reinforcement_rule` | Bonus drones (campaign feature, v1.1) |
| `special_rules` | Free-text overrides |

### 10.2. Per-Zone Configuration

Each zone in a scenario has:
- **Target deck** (`scenario_target_deck`) — which target card types and quantities
- **Threat deck** (`scenario_threat_deck`) — which threat types, quantities, and special rules
- **Target ranges** (`scenario_target_ranges`) — custom probability ranges per type
- **Threat ranges** (`scenario_threat_ranges`) — custom probability ranges per type

### 10.3. Scenario Editor (§8, Q6)

> Designer answer: "Recreate from scratch as a multiple-choice survey form."

The scenario editor will present a step-by-step form:

1. **Setting** — name, description, narrative
2. **Drone selection** — pick from available drones
3. **Objective** — type, target, weapon requirements
4. **Scoring** — Maximum Kill or Quick Kill
5. **Zone setup** — number of zones, terrain descriptions
6. **Deck building** — select target/threat cards per zone with quantities
7. **Probability ranges** — configure target/threat roll ranges per zone
8. **Combat card mix** — set event vs no-event card counts
9. **Special rules** — free-text field

---

## 11. UI/UX Functional Requirements

### 11.1. Screens

| Screen | Purpose |
|--------|---------|
| Main Menu | Play mode selection, settings, scenario editor |
| Drone Selection | Browse/select drone, view stats |
| Loadout Configuration | Choose weapons/kits, validate restrictions |
| Game Board | Main gameplay — shows current box, drone state, active cards |
| Card Display | Show drawn combat/target/threat cards with details |
| Attack Resolution | Attack mode/weapon/altitude selection, dice roll, CRT lookup |
| Evasion Resolution | Dice roll, CRT lookup, damage application |
| Decision Points | Engage/disengage at B2, continue/RTB at B5 |
| Post-Scenario Briefing | Score, damage summary, targets destroyed |
| Scenario Editor | Multi-step survey form |

### 11.2. Key UI Elements

| Element | Behavior |
|---------|----------|
| Fuel bar | Color gradient: green → yellow → red as fuel depletes |
| Drone state panel | Shows integrity, sensors, VIS/RCS, COMMS as numeric + visual indicators |
| Altitude indicator | 4 levels: VLOW, LOW, MEDIUM, HIGH |
| Card piles | Visual stacks showing count for each pile (target deck, threat deck, combat deck, discarded, destroyed) |
| Dice roller | Animated dice roll with clear result display |
| CRT overlay | Shows relevant table with highlighted result cell |

---

## 12. Data Gaps & Blocking Issues

> [!CAUTION]
> These items must be resolved before development can begin on affected features.

### 12.1. DILEK Clearance Items (from rulebook Q&A)

| # | Issue | Impact | Status |
|---|-------|--------|--------|
| 1 | Counterfire CRT LOW row (Stand-Off & Close-In) — all cells empty | Cannot implement counterfire at LOW altitude | ⬜ OPEN |
| 2 | SAM Counterfire CRT LOW row — all cells empty | Cannot implement SAM reaction shot at LOW | ⬜ OPEN |
| 3 | VLOW altitude row missing from ALL CRTs | Cannot implement VLOW altitude | ⬜ OPEN |
| 4 | `endurance_hours` column missing from `drones` table | Cannot determine starting fuel | ⬜ OPEN |

### 12.2. Database Issues Found During Analysis

| # | Issue | Details |
|---|-------|---------|
| 5 | All 28 drones are class B | Rulebook defines A/B/C/D classes but DB only has B. Are other classes planned? |
| 6 | `max_structural_integrity` = 1000 for all drones | This is likely a placeholder. Each drone should have a distinct value. |
| 7 | 6 drones have empty `altitude` field | AVENGER, S-70 OKHOTNIK-B, HERMES 450, NEURON, TARANIS, GHATAK — what are their altitude ranges? |
| 8 | ENGINEER target sub-category (6 cards) not in Target Acquisition Table | Where does ENGINEER map in the roll ranges? |
| 9 | DRONE GUN threat sub-category name vs "Anti-Drone Weapon" | Confirm mapping: `DRONE GUN` DB name = `Anti-Drone Weapon` rulebook name? |
| 10 | Target Acquisition Table has overlapping range at 35 (AFV) and 91 (VIP) | 35 appears in both PERSONNEL (19–35) and AFV (35–45); 91 appears in both HQ/BUNKER (80–91) and VIP (91–99). Need exclusive boundaries. |

---

## 13. Assumptions (Pending Confirmation)

| # | Assumption | Basis |
|---|-----------|-------|
| A1 | Solitaire Quick Game uses the full card pool (all 111 targets, all 36 threats, all 18 combat) | §5.1 implies this but doesn't state explicitly |
| A2 | In Solitaire mode, the default Target/Threat Acquisition Tables are used (not scenario overrides) | §5.1 vs §5.3 |
| A3 | Fuel consumption from the `(+)` loadout marker is per cycle, not per box | §2.5: "+2 Fuel extra to normal fuel usage in game cycle" |
| A4 | "Drone VP value" for the Solitaire scoring formula is a fixed value per drone | §5.1 says "subtract VP value of your drone" but drones table has no VP column |
| A5 | Altitude change at B1/B3 can be multiple levels (each costing 1F) | Rulebook says "costs 1F per altitude change" — unclear if one step or multiple |
| A6 | DRM cannot exceed 6 or be less than 1 for D6 rolls, but 2D10 DRM has no such cap | §3 states DR rules for D6 only |

---

*End of Functional Specification*
