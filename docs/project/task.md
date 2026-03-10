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
- [ ] BA Agent: Create functional specification from parsed rulebook
- [ ] BA Agent: Map board game mechanics → mobile game equivalents
- [ ] BA Agent: Create scenario editor input survey (multiple choice form)
- [ ] BA Agent: Collect endurance hours data per drone for fuel system
- [ ] UX Architect: Define game flow & screen architecture
- [ ] UI Designer: Create design system (colors, typography, components)
- [ ] UI Designer: Design fuel color bar (green → yellow → red gradient)

## Phase 2: Project Setup
- [ ] Scaffold Flutter project in `tidal-comet`
- [ ] Integrate existing database (`drone_commander_cards.db`)
- [ ] Set up project structure (layers, state management, routing)

## Phase 3: Core Implementation
- [ ] Combat card system
- [ ] Drone selection & loadout configuration
- [ ] Zone-based gameplay with movement
- [ ] Target search & engagement
- [ ] Threat resolution
- [ ] Win/loss/fuel condition tracking
- [ ] VP scoring system

## Phase 4: Scenario System
- [ ] Scenario loader from database
- [ ] Scenario editor (create/install custom scenarios)

## Phase 5: Polish & QA
- [ ] QA Agent: Evidence collection & testing
- [ ] Tech Writer: Documentation
- [ ] iOS build & deployment prep

## 🚨 DILEK Pre-Delivery Clearance (CRITICAL)
- [ ] Fix Counterfire table LOW row (Stand-Off & Close-In empty cells)
- [ ] Fix SAM Counterfire table LOW row (some SAMs should hit at LOW)
- [ ] Add VLOW altitude row to ALL CRT tables
- [ ] Add `endurance_hours` column to `drones` DB table

## Scope Decisions
- Campaign Mode: **v1.1** (deferred)
- 2+ Player Mode: **No** (maybe later)
- Fuel display: **Color bar** (not numeric/liters)
