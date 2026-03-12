# OB3 Drone Commander — Development Task Breakdown

> **Author**: OB3-ProjectManager (BA)
> **Date**: 2026-03-10
> **Source**: [functional-spec.md](functional-spec.md)
> **Tech Stack**: Flutter (Dart), SQLite (sqflite), iOS-first

---

## Specification Summary

**Original Requirements**: Full rulebook mechanics (B0→B5 game loop, all card types, all 28 drones, loadout system, combat/evasion CRTs, damage cascading, scoring), Solitaire Quick Game + Scenario Game modes, Scenario Editor (survey-form).

**Technical Stack**: Flutter/Dart, sqflite, iOS-first. State management and architecture TBD by architect.

**Scope**: v1.0 — Campaign and 2P modes deferred to v1.1.

---

## Pre-Development: Database Fixes

> These must be completed before feature development can start.

### [ ] Task 0.1: Fix Database Schema — Fuel/Endurance Column

**Description**: Add `endurance_hours` column to `drones` table and populate with correct values for all 28 drones.

**Acceptance Criteria**:
- Column `endurance_hours` exists as `REAL NOT NULL DEFAULT 0`
- All 28 drones have non-zero endurance values (sourced from designer/datasheets)
- Migration script included

**Files to Create/Edit**:
- `assets/db/ob3.db` (ALTER TABLE)
- New migration script

**Reference**: Functional Spec §4.3, DILEK Clearance Item #4

---

### [ ] Task 0.2: Fix Database — Structural Integrity Values

**Description**: Replace placeholder `max_structural_integrity = 1000` with correct values for each drone.

**Acceptance Criteria**:
- Each drone has a distinct, game-balanced integrity value
- Values sourced from designer

**Files to Edit**:
- `assets/db/ob3.db`

**Reference**: Functional Spec §12.2 Issue #6

---

### [ ] Task 0.3: Fix Database — Missing Drone Altitude Data

**Description**: Populate empty `altitude` fields for 6 drones: AVENGER, S-70 OKHOTNIK-B, HERMES 450, NEURON, TARANIS, GHATAK.

**Acceptance Criteria**:
- All 28 drones have non-empty altitude strings
- Values match real-world or designer-specified capabilities

**Files to Edit**:
- `assets/db/ob3.db`

**Reference**: Functional Spec §12.2 Issue #7

---

### [ ] Task 0.4: Resolve CRT Table Gaps

**Description**: Get corrected CRT values from designer for:
1. Counterfire CRT LOW row (Stand-Off & Close-In) — currently all empty
2. SAM Counterfire CRT LOW row — currently all empty
3. VLOW row for ALL three CRT tables (Attack, Counterfire, SAM)

**Acceptance Criteria**:
- All CRT cells have definitive values
- Values documented in functional spec
- CRT data encoded in code/config (not just rulebook text)

**Reference**: Functional Spec §5.4–5.6, DILEK Clearance Items #1, #2, #3

---

### [ ] Task 0.5: Resolve Data Mapping Questions

**Description**: Get designer answers for remaining open items:
- ✅ Where does ENGINEER map: PERSONNEL class (same mechanics, flavour name only)
- ✅ DRONE GUN = Anti-Drone Weapon (≥96 range)
- ✅ Overlapping boundaries fixed: PERSONNEL 19–34, HQ/BUNKER 80–90
- ✅ Are A/C/D class drones planned? **No — all 28 drones stay class B for v1.0**
- ✅ Drone VP cost = **5 VP constant**
- ✅ Altitude: multiple levels allowed, **2F per level UP, 1F per level DOWN**

**Acceptance Criteria**:
- Each question answered and documented
- Functional spec updated with confirmed answers

**Reference**: Functional Spec §12.2, §13

---

## Phase 1: Core Data Layer

### [ ] Task 1.1: Database Service — Read Models

**Description**: Create Dart data models and a database service to read all card and drone data from SQLite.

**Acceptance Criteria**:
- `DroneModel` — all fields including capabilities, loadout options, parsed altitude list
- `WeaponModel` — all fields including per-target DRM values
- `TargetCardModel` — all fields including VP, restrictions
- `ThreatCardModel` — all fields including column shift, restrictions
- `CombatCardModel` — all fields including parsed instructions
- `ScenarioModel` — all fields + zone data, deck composition, ranges
- `DatabaseService` class with methods to query each table
- All models are immutable (final fields)
- Unit tests pass for model construction from DB row maps

**Files to Create**:
- `lib/models/drone_model.dart`
- `lib/models/weapon_model.dart`
- `lib/models/target_card_model.dart`
- `lib/models/threat_card_model.dart`
- `lib/models/combat_card_model.dart`
- `lib/models/scenario_model.dart`
- `lib/services/database_service.dart`
- `test/models/` — unit tests per model

**Reference**: Functional Spec §9, §10

---

### [ ] Task 1.2: Game State Model

**Description**: Create the core game state model tracking all mutable game data.

**Acceptance Criteria**:
- `DroneState` — fuel, integrity damage, sensors damage, comms damage, VIS/RCS, altitude, loaded weapons, position (B0–B5)
- `DeckState` — target deck, threat deck, combat card deck, discarded pile, destroyed pile (each as list of card models)
- `GameState` — drone state, deck state, current cycle, active target/threat cards, scoring mode, game phase, turn history
- Damage cascading formulas implemented correctly:
  - `sensorsDamage = min(floor(structuralDamage / 2), 9)`
  - `commsDamage = min(floor(structuralDamage / 3), 5)`
  - `visDamage = commsDamage + sensorsDamage + adjustments`
- Unit tests for damage cascade math

**Files to Create**:
- `lib/models/drone_state.dart`
- `lib/models/deck_state.dart`
- `lib/models/game_state.dart`
- `test/models/game_state_test.dart`

**Reference**: Functional Spec §5.7

---

### [ ] Task 1.3: Dice Engine

**Description**: Implement dice rolling with DRM modifier application.

**Acceptance Criteria**:
- `roll1D6()` → returns 1–6
- `roll2D10()` → returns 0–99 (first die = ones, second = tens)
- `applyDRM(roll, modifiers)` → returns modified value
- D6 results clamped to 1–6 (per §3: "DR cannot exceed 6 or be less than 1")
- 2D10 results NOT clamped (DRM can exceed 100 or go below 0)
- Deterministic mode for testing (injectable RNG)
- Unit tests cover edge cases (boundary values, extreme DRM)

**Files to Create**:
- `lib/services/dice_service.dart`
- `test/services/dice_service_test.dart`

**Reference**: Functional Spec §3, §5.2

---

## Phase 2: Combat Resolution Engine

### [ ] Task 2.1: CRT Data Tables

**Description**: Encode all three Combat Resolution Tables as queryable data structures.

**Acceptance Criteria**:
- Drone Attack CRT — 4 altitudes × 3 modes × 6 DRM values = 72 cells
- Counterfire & Evasion CRT — same dimensions
- SAM Reaction Shot CRT — same dimensions
- Each cell returns: fuel cost (int), hit (bool), damage (int)
- Column shift logic: `shiftRight(steps)` / `shiftLeft(steps)` clamped to 1–6
- Unit tests for lookups at all boundaries

**Files to Create**:
- `lib/data/attack_crt.dart`
- `lib/data/counterfire_crt.dart`
- `lib/data/sam_counterfire_crt.dart`
- `test/data/crt_test.dart`

**Reference**: Functional Spec §5.4, §5.5, §5.6

---

### [ ] Task 2.2: Target Acquisition Logic

**Description**: Implement B2 target acquisition procedure.

**Acceptance Criteria**:
- Roll 2D10, apply DRM (+10 AEASA, +10 if COMMS=0, −10 per COMMS damage)
- Look up target type in acquisition table (default or scenario-specific ranges)
- **ENGINEER sub-category = PERSONNEL** — use PERSONNEL range and weapon rules
- Fallback logic: if no cards of that type → next lower range, then higher
- Draw matching card from target deck
- Return drawn card or null if deck empty
- Unit tests for DRM calculation, range matching, fallback, and ENGINEER→PERSONNEL mapping

**Files to Create**:
- `lib/services/target_acquisition_service.dart`
- `test/services/target_acquisition_service_test.dart`

**Reference**: Functional Spec §5.2

---

### [ ] Task 2.3: Threat Determination Logic

**Description**: Implement B2 threat determination procedure.

**Acceptance Criteria**:
- Roll 2D10, apply DRM (+10 per 2 VIS points)
- Look up threat type in determination table (default or scenario-specific)
- Fallback logic: same as target acquisition
- Draw matching card from threat deck
- Reshuffle rule: if all threats used but targets remain → reshuffle used threats
- Unit tests for DRM, range matching, fallback, and reshuffle

**Files to Create**:
- `lib/services/threat_determination_service.dart`
- `test/services/threat_determination_service_test.dart`

**Reference**: Functional Spec §5.2

---

### [ ] Task 2.4: Drone Attack Resolution (B4)

**Description**: Implement the complete B4 attack procedure.

**Acceptance Criteria**:
- Input: attack mode, weapon, altitude, current game state
- Validate weapon compatibility with target type
- Validate weapon compatibility with attack mode (AA→Stand-Off, etc.)
- Validate altitude (AA missiles → MED/HIGH only, weapon fire_altitude restrictions)
- Roll 1D6, apply all DRM (weapon per-target DRM, combat card, target card, scenario)
- Apply column shift (+1 RIGHT per 2 sensor damage)
- Look up Attack CRT
- Apply result: HIT → destroy target (VP), MISS → discard target
- Deduct fuel per cell, remove weapon marker
- Unit tests for each validation and resolution path

**Files to Create**:
- `lib/services/attack_service.dart`
- `test/services/attack_service_test.dart`

**Reference**: Functional Spec §5.4

---

### [ ] Task 2.5: Counterfire & Evasion Resolution (B5)

**Description**: Implement the complete B5 evasion procedure.

**Acceptance Criteria**:
- Roll 1D6, apply DRM (threat card modifiers, combat card, scenario)
- Apply column shift (−1 LEFT per 2 VIS points)
- Look up Counterfire CRT
- Apply damage to drone state (cascading per §5.7)
- Check drone survival (structural integrity, COMMS failure)
- Deduct fuel, discard threat card
- SAM reaction shot: if target was SAM AND missed → additional CRT check
- Unit tests for normal evasion, SAM reaction, and drone destruction

**Files to Create**:
- `lib/services/evasion_service.dart`
- `test/services/evasion_service_test.dart`

**Reference**: Functional Spec §5.5, §5.6

---

### [ ] Task 2.6: Damage System

**Description**: Implement the damage cascading engine.

**Acceptance Criteria**:
- Apply N damage points to structural integrity
- Auto-calculate sensors damage: `min(floor(structural / 2), 9)`
- Auto-calculate COMMS damage: `min(floor(structural / 3), 5)`
- Auto-calculate VIS increase from sensors + COMMS damage
- Detect drone destruction (structural ≥ max integrity)
- COMMS Check procedure (D6 + DRM modifiers → consult table)
- Handle special threat card damage rules (e.g., "any 1D hit DOUBLED", "+5D extra")
- Unit tests for incremental damage, cascade math, destruction detection

**Files to Create**:
- `lib/services/damage_service.dart`
- `test/services/damage_service_test.dart`

**Reference**: Functional Spec §5.7

---

### [ ] Task 2.7: Combat Card Execution Engine

**Description**: Implement all 18 combat card effects.

**Acceptance Criteria**:
- Parse and execute each unique combat card instruction
- State-mutating effects: CC002 (+2 COMMS), CC003 (+1 sensor permanent), CC004 (VIS→0), CC005 (clear COMMS), CC006 (force LOW altitude)
- Turn-scoped effects: CC001 (close-in only until B0), CC014 (+1 DRM for HQ/BUNKER stand-off), CC016 (1 LEFT attack shift), CC017 (skip counterfire), CC018 (1 LEFT counterfire if CAP/SAM)
- Special effects: CC013 (reveal 3 targets, pick 1), CC015 (return last destroyed target)
- No-event cards (CC007–CC012): discard without action
- Active effect tracking in game state
- Unit tests for each card type

**Files to Create**:
- `lib/services/combat_card_service.dart`
- `test/services/combat_card_service_test.dart`

**Reference**: Functional Spec §8.1

---

## Phase 3: Game Loop Controller

### [ ] Task 3.1: Game Loop State Machine

**Description**: Implement the B0→B5 state machine controlling game flow.

**Acceptance Criteria**:
- States: `B0_IN_TRANSIT`, `B1_SEARCH`, `B2_TARGET_ACQ`, `B2_DECISION` (engage/disengage), `B3_POSITIONING`, `B4_ATTACK`, `B5_EVASION`, `B5_DECISION` (continue/RTB), `GAME_OVER`
- Valid transitions:
  - B0→B1→B2→B2_DECISION
  - B2_DECISION(engage)→B3→B4→B5→B5_DECISION
  - B2_DECISION(disengage)→B1
  - B5_DECISION(continue)→B0
  - B5_DECISION(RTB)→GAME_OVER
- Automated per-box actions (fuel deduction, card draws, COMMS checks)
- Game end condition detection (all 6 conditions from §6)
- Cycle counter increment at B0
- Unit tests for each state transition and end condition

**Files to Create**:
- `lib/controllers/game_loop_controller.dart`
- `test/controllers/game_loop_controller_test.dart`

**Reference**: Functional Spec §5, §6

---

### [ ] Task 3.2: Loadout Selection Logic

**Description**: Implement loadout validation and selection.

**Acceptance Criteria**:
- Parse drone's opt1–opt5 weapon pairs
- Validate class restrictions (*A, *B, *C, *D)
- Enforce exclusive (%) restriction
- Calculate extra fuel cost for (+) weapons
- Cross-reference weapon compatibility with attack modes and target types
- Provide available weapon list for given target + attack mode combination in B4
- Scenario loadout overrides from `scenario_loadouts` table
- Unit tests for restriction validation

**Files to Create**:
- `lib/services/loadout_service.dart`
- `test/services/loadout_service_test.dart`

**Reference**: Functional Spec §4.2, §6.4.1

---

### [ ] Task 3.3: Scoring Service

**Description**: Implement both scoring methods.

**Acceptance Criteria**:
- Track destroyed target pile with VP values
- Maximum Kill: sum VP from all destroyed targets
- Quick Kill: sum VP, end immediately when primary objective accomplished
- Solitaire: subtract **5 VP** (fixed constant for all drones — confirmed by designer)
- Post-scenario score summary (targets destroyed, damage taken, cycles completed)
- Unit tests for both scoring modes

**Files to Create**:
- `lib/services/scoring_service.dart`
- `test/services/scoring_service_test.dart`

**Reference**: Functional Spec §7

---

## Phase 4: Scenario System

### [ ] Task 4.1: Scenario Loader

**Description**: Load scenario data from database and configure the game accordingly.

**Acceptance Criteria**:
- Load scenario by ID from `scenarios` table
- Load zone data from `scenario_zones`
- Build target deck from `scenario_target_deck` (per zone)
- Build threat deck from `scenario_threat_deck` (per zone, with special rules)
- Load custom probability ranges from `scenario_target_ranges` / `scenario_threat_ranges`
- Load scenario-specific loadouts from `scenario_loadouts`
- Configure combat card deck (event vs no-event counts)
- Apply scenario special rules to game state
- Validate scenario data completeness before game start
- Unit tests for deck building and range loading

**Files to Create**:
- `lib/services/scenario_service.dart`
- `test/services/scenario_service_test.dart`

**Reference**: Functional Spec §10

---

### [ ] Task 4.2: Solitaire Quick Game Setup

**Description**: Implement the default Solitaire Quick Game mode setup.

**Acceptance Criteria**:
- Use full card pools: all 111 targets, 36 threats, 18 combat cards
- Use default Target/Threat Acquisition Tables (not scenario overrides)
- Player selects drone freely from all 28
- Player configures loadout from drone's options (no scenario restrictions)
- Scoring: Maximum Kill with drone VP subtraction
- Game end: all target cards expanded OR fuel exhausted OR drone destroyed

**Files to Create**:
- `lib/services/quick_game_service.dart`
- `test/services/quick_game_service_test.dart`

**Reference**: Functional Spec §5.1

---

### [ ] Task 4.3: Scenario Editor (Survey Form)

**Description**: Multi-step form to create custom scenarios, saved to database.

**Acceptance Criteria**:
- Step 1: Name, description, narrative (text inputs)
- Step 2: Drone selection (dropdown from 28 drones)
- Step 3: Primary objective — target type, card name, weapon requirement (dropdowns)
- Step 4: Scoring mode — Maximum Kill / Quick Kill (radio)
- Step 5: Zone setup — number of zones (1–9), terrain per zone (text)
- Step 6: Deck building — multi-select target/threat cards per zone with quantity spinners
- Step 7: Probability ranges — min/max per target/threat type per zone
- Step 8: Combat card mix — event count, no-event count (spinners)
- Step 9: Special rules (text area)
- Validate all inputs before save
- INSERT into all scenario-related tables
- Created scenario appears in scenario list

**Files to Create**:
- `lib/screens/scenario_editor/` — multi-screen wizard
- `lib/services/scenario_editor_service.dart`
- `test/services/scenario_editor_service_test.dart`

**Reference**: Functional Spec §10.3, rulebook §8

---

## Phase 5: UI Screens

### [ ] Task 5.1: Main Menu Screen

**Description**: Landing screen with play mode selection and navigation.

**Acceptance Criteria**:
- "Solitaire Quick Game" button → drone selection flow
- "Scenario Game" button → scenario list/selection
- "Scenario Editor" button → editor wizard
- "Settings" button → settings screen
- Visually polished, military-themed design

**Files to Create**:
- `lib/screens/main_menu_screen.dart`

**Reference**: Functional Spec §11.1

---

### [ ] Task 5.2: Drone Selection Screen

**Description**: Browse and select drone with stats preview.

**Acceptance Criteria**:
- List/grid of all 28 drones (or filtered by scenario)
- Show drone name, country, class, altitude range
- Show capabilities (AEASA, SATCOM, COMMS Redundancy, Autonomous AI, FO/Laze)
- Show available loadout options
- Tap to select → navigate to loadout configuration
- Scenario mode: drone may be pre-selected (locked)

**Files to Create**:
- `lib/screens/drone_selection_screen.dart`

**Reference**: Functional Spec §4.1

---

### [ ] Task 5.3: Loadout Configuration Screen

**Description**: Choose weapons/kits from drone's loadout options.

**Acceptance Criteria**:
- Display available loadout options (opt1–opt5)
- Show weapon names, quantities, type constraints
- Visual restriction indicators (*A/*B/*C/*D, %, +)
- Validate selections against rules (class, exclusive, compatibility)
- Show total fuel overhead from (+) weapons
- "Launch" button → start game
- Scenario mode: may have pre-configured loadout options

**Files to Create**:
- `lib/screens/loadout_screen.dart`

**Reference**: Functional Spec §4.2

---

### [ ] Task 5.4: Game Board Screen

**Description**: Main gameplay screen showing current box, drone state, and controls.

**Acceptance Criteria**:
- Visual game board with B0–B5 boxes, drone marker at current position
- Drone state panel: fuel bar (color gradient), integrity, sensors, COMMS, VIS/RCS
- Altitude indicator (4 levels)
- Card pile counts (target deck, threat deck, combat deck, discarded, destroyed)
- Current cycle counter
- Active combat card effects displayed
- Contextual action buttons per current game phase
- Action log (last 3 messages)

**Files to Create**:
- `lib/screens/game_board_screen.dart`
- `lib/widgets/drone_state_panel.dart`
- `lib/widgets/game_board_widget.dart`

**Reference**: Functional Spec §11

---

### [ ] Task 5.5: Card Display Widgets

**Description**: Card display for combat, target, and threat cards.

**Acceptance Criteria**:
- Card face with name, type, instructions/stats, image (if available)
- Target cards: show VP, type, sub_category, restrictions
- Threat cards: show type, sub_category, special rules, column shift
- Combat cards: show name, instruction text
- Card flip animation (face-down → face-up)
- Card discard animation

**Files to Create**:
- `lib/widgets/card_display_widget.dart`
- `lib/widgets/target_card_widget.dart`
- `lib/widgets/threat_card_widget.dart`
- `lib/widgets/combat_card_widget.dart`

**Reference**: Functional Spec §8

---

### [ ] Task 5.6: Attack Resolution Screen

**Description**: B4 attack mode, weapon, and altitude selection with dice roll and CRT display.

**Acceptance Criteria**:
- Attack mode selector (Stand-Off / Close-In / FO-Laze) with availability indicators
- Weapon selector (filtered by compatible weapons)
- Altitude selector (filtered by weapon + drone restrictions)
- Animated dice roll
- CRT table overlay with highlighted result cell
- Result display: HIT/MISS, fuel cost, weapon consumed
- "Apply" button → update game state

**Files to Create**:
- `lib/screens/attack_resolution_screen.dart`

**Reference**: Functional Spec §5.4

---

### [ ] Task 5.7: Evasion Resolution Screen

**Description**: B5 counterfire with dice roll, CRT display, and damage application.

**Acceptance Criteria**:
- Show active threat card details
- Animated dice roll with DRM breakdown
- CRT table overlay with highlighted result cell
- Damage result display with cascading breakdown (structural → sensors → comms → VIS)
- SAM reaction shot UI (if applicable)
- Drone survival/destruction indication
- "Apply" button → update game state, show post-evasion decision if survived

**Files to Create**:
- `lib/screens/evasion_resolution_screen.dart`

**Reference**: Functional Spec §5.5, §5.6

---

### [ ] Task 5.8: Decision Point Dialogs

**Description**: Modal dialogs for B2 (engage/disengage) and B5 (continue/RTB) decisions.

**Acceptance Criteria**:
- B2 Decision: show target + threat cards side by side, "Engage" / "Disengage" buttons
- B5 Decision: show drone state summary, "Continue Mission" / "Return to Base" buttons
- "Continue" disabled if no fuel or no ammo
- Clear consequence descriptions for each choice

**Files to Create**:
- `lib/widgets/decision_dialog.dart`

**Reference**: Functional Spec §5.2.1, §5.8

---

### [ ] Task 5.9: Post-Scenario Briefing Screen

**Description**: End-of-game results screen.

**Acceptance Criteria**:
- Score: total VP, drone VP subtraction (Solitaire), final score
- Targets destroyed list with VP values
- Damage summary (final drone state)
- Cycles completed
- Scenario outcome (objective completed / drone lost / RTB)
- "Play Again" / "Main Menu" buttons

**Files to Create**:
- `lib/screens/briefing_screen.dart`

**Reference**: Functional Spec §6, §7

---

## Phase 6: Integration & Polish

### [ ] Task 6.1: Navigation & Routing

**Description**: Wire all screens together with proper navigation flow.

**Acceptance Criteria**:
- Main Menu → Drone Selection → Loadout → Game Board → Briefing
- Game Board ↔ Attack/Evasion/Decision screens
- Back navigation handled correctly (no accidental game exit)
- Deep link to scenario from scenario list

**Files to Create**:
- `lib/app_router.dart`

---

### [ ] Task 6.2: State Management Setup

**Description**: Implement chosen state management solution (TBD by architect).

**Acceptance Criteria**:
- Game state accessible from all screens
- State changes trigger UI rebuilds
- Undo not required for v1.0
- State persisted during app lifecycle (pause/resume)

---

### [ ] Task 6.3: Full Game Flow Integration Test

**Description**: End-to-end test of complete game flow.

**Acceptance Criteria**:
- Start Solitaire Quick Game → select drone → configure loadout → play through B0-B5 → make decisions → complete game → see briefing
- Start Scenario Game → load scenario 1 → play through → complete/fail → see briefing
- Scenario Editor → create scenario → play created scenario
- No crashes, correct scoring, correct damage cascading

**Files to Create**:
- `test/integration/full_game_flow_test.dart`

---

## Quality Requirements

- [ ] All models and services have unit tests
- [ ] Damage cascade math verified with edge cases
- [ ] CRT lookups verified for all boundary values
- [ ] Column shift clamping verified (stays within 1–6)
- [ ] Game end conditions all trigger correctly
- [ ] Card deck depletion/reshuffle works correctly
- [ ] No silent catches — all try/catch includes meaningful logging
- [ ] No hardcoded credentials
- [ ] Mobile responsive layout (iOS portrait primary)

---

*End of Task Breakdown — 27 tasks across 6 phases + 5 pre-development fixes*
