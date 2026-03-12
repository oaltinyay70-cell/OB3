# OB3 — Agent Work Orders (from UX Architect)

> **From**: OB3-UXArchitect  
> **Date**: 2026-03-11  
> **Context**: The UX Architecture is complete at `docs/specs/ux-architecture.md`. Below are the dependencies and work orders for each agent so we can begin implementation.

---

## 🚨 What's Blocking Implementation

| # | Blocker | Owner | Priority |
|---|---------|-------|----------|
| 1 | **SAM Counterfire LOW row** — All cells empty (some SAMs should hit at LOW) | Game Designer / DILEK | 🔴 CRITICAL |
| 4 | **`endurance_hours` column** in `drones` table + actual values per drone | OB3-SeniorDev (DB) | 🟡 HIGH |
| 5 | **Scenario Editor survey form** — multiple-choice input design | OB3-ProjectManager | 🟡 HIGH |
| 6 | **Design system** — visual polish on top of UX tokens | OB3-UIDesigner | 🟡 HIGH |

> [!WARNING]
> Item 1 is a **game designer clearance item**. The engine can be scaffolded without it, but SAM CRT lookups cannot be finalized. Suggest using placeholder/interpolated values if designer response is slow.

---

## 📋 Work Orders by Agent

### 1. OB3-ProjectManager (BA)

**Read first**: [ux-architecture.md](file:///Users/ozgur/.gemini/antigravity/playground/tidal-comet/docs/specs/ux-architecture.md) — Sections 3.8 (Scenario Editor) and 2.3 (State Data Model)

**Deliverables needed**:

| # | Task | Output | Notes |
|---|------|--------|-------|
| PM-1 | Design Scenario Editor survey form | `docs/specs/scenario-editor-form.md` | Multiple-choice wizard: Setting → Mission → Decks → Drone+Loadout → Review. Per user's Q6 answer |
| PM-2 | Finalize functional spec | `docs/specs/functional-spec.md` | Map rulebook mechanics → mobile equivalents. UX arch is your input for screen flow |
| PM-3 | Create task breakdown for dev | `project-tasks/ob3-tasklist.md` | Use UX arch file structure (Section 8) as scaffolding guide |
| PM-4 | Collect endurance_hours data | Data for 28 drones | From rulebook/designer — needed for fuel system |

---

### 2. OB3-UIDesigner

**Read first**: [ux-architecture.md](file:///Users/ozgur/.gemini/antigravity/playground/tidal-comet/docs/specs/ux-architecture.md) — Sections 4 (Design Tokens), 5 (Components), 6 (Interactions)

**Deliverables needed**:

| # | Task | Output | Notes |
|---|------|--------|-------|
| UI-1 | Build on design tokens | `docs/specs/design-system.md` | UX arch provides color, type, spacing tokens. UI Designer polishes into full design system |
| UI-2 | Fuel color bar spec | Visual spec + gradient stops | Green→Yellow→Red as fuel declines. User explicitly requested this |
| UI-3 | Card visual design | Target, Threat, Combat card layouts | DB has `image` BLOBs — determine if usable or need new art |
| UI-4 | Game Board layout mockup | Visual mockup of S05 | The most complex screen. Use Section 3.5 layout zones as wireframe |
| UI-5 | Drone Selection card design | Card component for S02 | Class badge, country flag, capability icons |
| UI-6 | Dice roll visual style | D6 and 2D10 appearance | Military/tactical aesthetic consistent with MILSTD theme |
| UI-7 | Box Progress Indicator | B0–B5 stepper visual | Color-coded per box (colors defined in Section 4.1) |

---

### 3. OB3-SeniorDev

**Read first**: [ux-architecture.md](file:///Users/ozgur/.gemini/antigravity/playground/tidal-comet/docs/specs/ux-architecture.md) — Sections 7 (State Mgmt), 8 (File Structure), 9 (Router), 2 (State Machine)

**Can start immediately** (no blockers):

| # | Task | Output | Notes |
|---|------|--------|-------|
| DEV-1 | Scaffold Flutter project | `lib/` structure per Section 8 | Use `go_router`, `flutter_bloc`, `freezed` |
| DEV-2 | Create Freezed data models | `lib/data/models/*.dart` | Use Section 2.3 GameState schema verbatim |
| DEV-3 | DB provider + repositories | `lib/data/database/`, `lib/data/repositories/` | sqflite wrapper for existing DB, add `endurance_hours` migration |
| DEV-4 | Design token Dart files | `lib/core/theme/*.dart` | Copy Section 4.1–4.4 directly |
| DEV-5 | CRT table data structures | `lib/core/constants/crt_tables.dart` | Encode Attack, Counterfire, SAM tables as lookup maps. Use placeholder for VLOW row |
| DEV-6 | Game engine (pure logic) | `lib/game/engine/*.dart` | Dice, DRM calculator, damage cascade, deck manager — all testable without UI |
| DEV-7 | GameBloc state machine | `lib/game/bloc/game_bloc.dart` | Implement transition table from Section 2.4 |

**Blocked on** (can defer):
- SAM Counterfire LOW row corrections
- `endurance_hours` actual values (use `range / 100` as temp proxy)

---

### 4. OB3-MobileBuilder

**Not yet needed.** Will activate in Phase 3 for:
- iOS platform config
- Asset bundling (DB file, fonts)
- Build/deploy scripts

---

### 5. OB3-QA

**Read first**: [ux-architecture.md](file:///Users/ozgur/.gemini/antigravity/playground/tidal-comet/docs/specs/ux-architecture.md) — Section 2.4 (Transitions Table) and Section 6 (Interactions)

**Can start prepping**:

| # | Task | Output | Notes |
|---|------|--------|-------|
| QA-1 | Write test matrix from state machine | `docs/qa/test-matrix.md` | Every transition in Section 2.4 = one test case |
| QA-2 | Identify edge cases | Edge case list | Fuel=0 at each box, COMMS cascading, SAM reaction chain, deck exhaustion |
| QA-3 | Prep CRT verification data | Expected outcomes for known inputs | Roll X at Altitude Y with Mode Z → should produce result W |

---

### 6. OB3-TechWriter

**Not yet needed.** Will activate in Phase 4 for README and ARCHITECTURE.md.

---

## 🚀 Recommended Parallel Start

```
IMMEDIATELY (no blockers):
├── OB3-SeniorDev: DEV-1 through DEV-7 (scaffold + engine)
├── OB3-UIDesigner: UI-1 through UI-7 (design system)
└── OB3-QA: QA-1 through QA-3 (test prep)

ASAP (needs input/data):
├── OB3-ProjectManager: PM-1 through PM-4 (specs + data collection)
└── DILEK: Escalate SAM Counterfire LOW row correction to game designer

LATER:
├── OB3-MobileBuilder: After core screens work
└── OB3-TechWriter: After feature-complete
```
