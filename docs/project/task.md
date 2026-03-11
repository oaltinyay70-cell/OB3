# Drone Commander Mobile — Task Checklist

## Phase 0: Foundation
- [x] Discover & brief project (discovery questions, asset inventory, project brief)
- [x] Create GitHub repo (OB3 — private, oaltinyay70-cell/OB3)
- [x] Read & understand orchestrator skill workflow
- [x] Set up 8-agent roster with skill-based roles
- [x] Parse rulebook (V3.1-D10.pdf) into structured markdown
- [x] Decide tech stack details (Flutter confirmed, architecture patterns TBD by UX Architect)
- [x] Create persistent agent chatroom for inter-agent communication

## Phase 1: Analysis & Design
- [x] BA Agent: Create functional specification from parsed rulebook
- [x] BA Agent: Collect endurance hours + SI data for all 28 drones
- [x] Record official game glossary (12 terms, 6 new mechanical rules)
- [x] Record game hierarchy (Campaign → Scenario → Cycle)
- [x] Record deck composition rules (3 decks, DB-driven, duplicates, shuffling)
- [x] Record deck exhaustion rules (reshuffle from original)
- [x] Record card data source rule (DB sole source of truth, no hard-coding)
- [x] Correct B-box cycle flow (B1=search, B2=target+threat, B3=positioning, B4=attack, B5=evasion)
- [x] Add Drone Attack CRT Rev 3 (4 altitudes × 3 modes, hit probability summary, weapon restrictions)
- [x] Record Target Determination detailed flow (dice display, VP banking, kill list)
- [x] Record Objectives Tracking (primary gates campaign, secondary VP conditional)
- [x] Record Primary Objective Completion Prompt (RTB vs Continue, shown once)
- [x] Record Threat Determination detailed flow (damage multiplier = combat card × height)
- [x] Record End-of-Loop Check (strict order: destroyed → fuel → RTB → continue)
- [x] Record Drone Height Mechanic (4 levels, starting MEDIUM, free action, 4 affected mechanics)
- [x] Record Fuel/Endurance Mechanic (depletion at end-of-cycle, 4-band color bar)
- [x] Record Scenario Termination Conditions (3 conditions with campaign advancement logic)
- [x] Record Post-Scenario Briefing (6 mandatory sections)
- [x] Record Campaign Progression Rules (advance requires primary, fail = retry)
- [x] Fix starting height: HIGH → MEDIUM across all files
- [x] Fix fuel bar colors: green→yellow→red → green→blue→orange→red (4 bands)
- [/] BA Agent: Map board game mechanics → mobile game equivalents
- [ ] BA Agent: Create scenario editor input survey (multiple choice form)
- [ ] UX Architect: Define game flow & screen architecture
- [ ] UI Designer: Create design system (colors, typography, components)
- [ ] UI Designer: Design fuel color bar (green/blue/orange/red 4-band)

## Phase 2: Project Setup
- [ ] Scaffold Flutter project in `tidal-comet`
  - [x] Add `endurance_hours` column to `drones` DB table
  - [x] Update `max_structural_integrity` for all 28 drones (was all 1000)
  - [x] Update `endurance_hours` for all 28 drones
  - [ ] Add height modifier config table to DB
  - [ ] Add fuel base rate per cycle to scenario config
- [ ] Set up project structure (layers, state management, routing)

## Phase 3: Core Implementation
- [ ] Game cycle engine (B0→B1→B2→B3→B4→B5→End-of-Loop)
- [ ] Triple-deck card system (Combat/Target/Threat from DB)
- [ ] Drone selection & loadout configuration (28 drones, sensor kits as loadout)
- [ ] Target Determination (dice roll display, VP banking, kill list)
- [ ] Threat Determination (evasion roll, damage multiplier = combat card × height)
- [ ] Drone Height system (4 levels, free action, 4 affected mechanics)
- [ ] Fuel/Endurance system (depletion at end-of-cycle, 4-band color bar)
- [ ] Objectives Tracking (primary/secondary, completion prompt)
- [ ] End-of-Loop Check (strict order checks)
- [ ] Scenario Termination (3 conditions, same post-briefing path)
- [ ] Post-Scenario Briefing screen (6 mandatory sections)
- [ ] Campaign Progression logic (advance/locked/retry)

## Phase 4: Scenario System
- [ ] Scenario loader from database (deck composition, objectives)
- [ ] Scenario editor (create/install custom scenarios)

## Phase 5: Polish & QA
- [ ] QA Agent: Evidence collection & testing
- [ ] Tech Writer: Documentation
- [ ] iOS build & deployment prep

## 🚨 DILEK Pre-Delivery Clearance (CRITICAL)
- [ ] Fix Counterfire table LOW row (Stand-Off & Close-In empty cells)
- [ ] Fix SAM Counterfire table LOW row (some SAMs should hit at LOW)
- [x] Add VLOW row to Drone Attack CRT ✅ (Rev 3 — other CRT tables still need VLOW)
- [x] Add `endurance_hours` column to `drones` DB table ✅

## Scope Decisions
- Campaign Mode: **v1.1** (deferred, but rules documented)
- 2+ Player Mode: **No** (maybe later)
- Fuel display: **Color bar** (green/blue/orange/red, no numeric)
- Starting height: **MEDIUM** (not HIGH)
- Height change: **Free action** (not locked to specific step)
- Fuel depletion: **End-of-cycle only** (not mid-step)

## Open Items (from rulebook_gaps.md)
- [x] A4: VLOW drones → None, reserved for future
- [x] B1: Endurance + SI for all 28 drones → Done, in DB
- [x] E3: Post-Scenario Briefing content → 6 sections defined
- [x] H3: SI values → Done, all 28 updated in DB
- [x] Q3: LOW/Stand-Off 0% hit → Confirmed by CRT Rev 3
- [ ] A1-A3: VLOW CRT values (Counterfire + SAM tables — deferred)
- [ ] B2: Fuel consumption rate (1F = ? hours)
- [ ] C1-C3: Combat card deck contents
- [ ] D1-D2: Scenario definitions for v1.0
- [ ] E1: VP values (on cards or chart?)
- [ ] E2: Rank/rating system
- [ ] F1-F2: FO/Laze mechanics
- [ ] G1-G4: Drone special abilities details
- [ ] H1: Re-arm mid-scenario
- [ ] H2: Altitude change limits per turn
