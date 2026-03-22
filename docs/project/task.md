# Drone Commander Mobile — Task Checklist

## Phase 0: Foundation ✅
- [x] Discover & brief project (discovery questions, asset inventory, project brief)
- [x] Create GitHub repo (OB3 — private, oaltinyay70-cell/OB3)
- [x] Read & understand orchestrator skill workflow
- [x] Set up 8-agent roster with skill-based roles
- [x] Parse rulebook (V3.1-D10.pdf) into structured markdown
- [x] Decide tech stack details (Flutter confirmed, architecture patterns TBD by UX Architect)
- [x] Create persistent agent chatroom for inter-agent communication

## Phase 1: Analysis & Design ✅
- [x] BA Agent: Create functional specification from parsed rulebook
- [x] BA Agent: Collect endurance hours + SI data for all 28 drones
- [x] BA Agent: Map board game mechanics → mobile game equivalents
- [x] BA Agent: Create scenario editor input survey (multiple choice form)
- [x] UX Architect: Define game flow & screen architecture (`ux-architecture.md`)
- [x] UX Architect: Create game engine API reference (`game-engine-api.md`)
- [x] UX Architect: Create agent work orders (`agent-work-orders.md`)
- [x] UI Designer: Create design system — MILSTD dark theme (`design-system.md`, 972 lines)
- [x] UI Designer: Design fuel color bar (green/blue/orange/red 4-band)
- [x] Record all game rules (glossary, hierarchy, deck composition, CRT tables, damage)
- [x] Fix starting height: HIGH → MEDIUM
- [x] Fix fuel bar colors: green→yellow→red → green→blue→orange→red (4 bands)
- [x] 18 combat cards defined and inserted into DB
- [x] Resolve rulebook gaps G1-G4, H1, H2, F1-F2, B2, E1, E2

## Phase 2: Project Setup ✅
- [x] Scaffold Flutter project in `/Users/ozgur/Documents/OB3`
- [x] Add `endurance_hours` column to `drones` DB table
- [x] Update `max_structural_integrity` for all 28 drones
- [x] Update `endurance_hours` for all 28 drones
- [x] Set up project structure (core, data, engine, features, models, shared)
- [x] Create data models: `Drone`, `Weapon`, `TargetCard`, `ThreatCard`, `CombatCard`, `Scenario`
- [x] Create database service + repositories (drone, weapon, card, scenario)
- [x] Create engine: dice, combat resolution, damage system, deck manager, scoring
- [x] Create game engine with B0→B5 state machine (714 lines)
- [x] Create MILSTD theme (`lib/core/theme/milstd_theme.dart`)
- [x] Create GameBloc state management (`lib/features/game/bloc/`)
- [x] Engine unit tests — **57 tests passing** ✅
- [ ] Add height modifier config table to DB
- [ ] Add fuel base rate per cycle to scenario config

## Phase 3: Core Implementation (IN PROGRESS)
- [x] Game cycle engine (B0→B1→B2→B3→B4→B5→End-of-Loop)
- [x] Triple-deck card system (Combat/Target/Threat from DB)
- [x] Target Determination (dice roll, VP banking, kill list)
- [x] Threat Determination (evasion roll, damage cascading)
- [x] Drone Height system (4 levels, free action)
- [x] Objectives Tracking (primary/secondary, completion prompt)
- [x] End-of-Loop Check (strict order checks)
- [x] Scenario Termination (3 conditions)
- [x] Scenario loader from database
- [/] **Main Menu screen** ← NEXT
- [ ] Drone selection & loadout configuration screen
- [ ] Game Board screen (B0-B5 visual with drone status panel)
- [ ] Fuel color bar widget
- [ ] Attack Resolution screen
- [ ] Evasion Resolution screen
- [ ] Decision Point dialogs (B2 engage/retreat, B5 continue/RTB)
- [ ] Post-Scenario Briefing screen (6 mandatory sections)
- [ ] Card display widgets (target, threat, combat)
- [x] AI Generated target card visuals — ALL 111/111 COMPLETE
  - [x] AFV (18/18) · VIP (6/6) · ARTILLERY (18/18) · AIR (6/6)
  - [x] TANK (15/15) · ENGINEER (6/6) · HQ-BUNKER (6/6)
  - [x] PERSONNEL (12/12) · SAM (18/18) · TRUCK (6/6)

## Phase 4: Scenario System
- [x] Scenario loader from database (deck composition, objectives)
- [ ] Scenario editor (survey form wizard — 7 steps)

## Phase 5: Polish & QA
- [/] QA Agent: Test matrix and edge cases prepped
- [ ] Tech Writer: Documentation (README, ARCHITECTURE.md)
- [ ] iOS build & deployment prep

## 🚨 DILEK Pre-Delivery Clearance — ALL RESOLVED ✅
- [x] Fix Counterfire table LOW row → Resolved via CRT Rev 3
- [x] Fix SAM Counterfire table LOW row → Resolved via A3 answer
- [x] Add VLOW row to all CRT tables → Resolved (A1, A2, A3)
- [x] Add `endurance_hours` column → Done, all 28 drones populated

## Scope Decisions
- Campaign Mode: **v1.1** (deferred, rules documented)
- 2+ Player Mode: **No** (maybe later)
- Fuel display: **Color bar** (green/blue/orange/red, no numeric)
- Starting height: **MEDIUM**
- Height change: **Free action** (UP=+1F/level, DOWN=free)
- Fuel depletion: **End-of-cycle only**

## Open Items
- [x] All rulebook gaps (A1-H3) resolved ✅
- [/] D1-D2: "The Milk Run" scenario partially defined — needs deck composition
