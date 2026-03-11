# OB3 — Task Distribution from SeniorDev

> **Date**: 2026-03-11
> **From**: OB3-SeniorDev
> **Status**: Core game engine COMPLETE (57 tests passing). Blocked on deliverables below.

---

## 📋 FOR: OB3-Orchestrator (DILEK)

> Copy-paste this section to the Orchestrator agent.

**Subject: 4 BLOCKING items needed to finalize the game engine CRT tables and DB**

The core engine is built but uses **placeholder data** for the following. These must be resolved before the engine can be considered production-ready.

### Task 1: Fix Counterfire CRT Table — LOW Row
The **Counterfire & Evasive Action Table** (§6.4.4) LOW altitude row currently shows:
- **Stand-Off**: All 6 DRM columns empty (no damage)
- **Close-In**: All 6 DRM columns empty (no damage)

This was flagged as incorrect in the rulebook Q&A (Q1). **Please provide the correct values for LOW/Stand-Off DRM 1-6 and LOW/Close-In DRM 1-6.** Format: for each cell, provide damage (e.g., 1D) and fuel cost (e.g., 1F), or "—" for no effect.

### Task 2: Fix SAM Special Counterfire Table — LOW Row
The **SAM Target Unit Special Counterfire Table** (§6.4.3.1) entire LOW row is empty across all 3 attack modes. This was flagged as likely incorrect (Q2). **Please provide the corrected LOW row values for Stand-Off, Close-In, and FO/Laze (6 DRM columns each).**

### Task 3: Add VLOW Altitude Rows to ALL CRT Tables
Q9 confirmed 4 altitude levels: **VLOW — LOW — MEDIUM — HIGH**. The rulebook only defines 3 rows (LOW, MEDIUM, HIGH). **Please provide the VLOW row values for:**
- Drone Attack Table (3 modes × 6 columns)
- Counterfire & Evasive Action Table (3 modes × 6 columns)
- SAM Special Counterfire Table (3 modes × 6 columns)

### Task 4: Add `endurance_hours` Column to `drones` Table
The database at `assets/db/drone_commander_cards.db` has a `drones` table with a `range` column (distance in km) but **no fuel/endurance column**. Per Q7 answer, fuel = endurance in hours.

**Please add an `endurance_hours` INTEGER column to the `drones` table and populate it for all 28 drones.** The engine currently defaults to 24 for all drones.

```sql
-- Example:
ALTER TABLE drones ADD COLUMN endurance_hours INTEGER DEFAULT 24;
UPDATE drones SET endurance_hours = 27 WHERE id = 1; -- TB2
UPDATE drones SET endurance_hours = 24 WHERE id = 2; -- AKINCI
-- ... etc for all 28 drones
```

**Deliverable**: Updated `drone_commander_cards.db` file.

---

## 📋 FOR: OB3-UIDesigner

> Copy-paste this section to the UI Designer agent.

**Subject: 4 deliverables needed for UI layer implementation**

The game engine is complete with state management and a callback system ready for UI binding. I need the following design specs to start building screens.

### Task 5: Design System Tokens
Provide a complete design system spec for the MILSTD (dark intelligence dashboard) theme:
- **Color palette**: primary, secondary, accent, surface, background, error, text colors (hex values)
- **Typography scale**: font family, sizes for h1-h6, body, caption, button
- **Spacing scale**: base unit and multipliers
- **Border radius**, elevation/shadow specs
- **State colors**: success, warning, danger, info

**Deliverable**: A design tokens file or spec document I can translate into `ThemeData`.

### Task 6: Screen Mockups/Wireframes
Provide layout specs for these core screens:
1. **Game Board** — main gameplay screen showing drone position (B0-B5), current cards, fuel bar, damage indicators, action buttons per phase
2. **Drone Selection** — grid/list of 28 drones with country, class, capabilities
3. **Loadout Configuration** — weapon selection from drone's loadout options
4. **Post-Mission Briefing** — score summary, destroyed targets list, damage report

For each screen: component placement, hierarchy, key interactions.

### Task 7: Fuel Bar Design
Per the project spec, fuel is shown as a **color bar that changes color as it depletes**. Provide:
- Gradient color stops (green → yellow → orange → red)
- Threshold percentages (e.g., >60% green, 30-60% yellow, <30% red)
- Bar dimensions and style (height, rounded corners, glow effects)

### Task 8: Card Display Design
The DB has `image` (BLOB) fields for combat, target, and threat cards. Provide:
- Card frame/border treatment
- Card info layout (title, VP value, instructions, type icon)
- How cards appear during draw animations
- Card sizing for mobile viewport

**Deliverable**: Mockups or detailed wireframes (images or Figma specs).

---

## 📋 FOR: OB3-ProjectManager (BA)

> Copy-paste this section to the Business Analyst agent.

**Subject: 3 deliverables needed for feature scope and screen flow**

### Task 9: Functional Specification
Provide a functional spec covering:
- **Complete screen list** with navigation flow (which screen leads where)
- **User actions per screen** (buttons, gestures, decisions)
- **State transitions** mapped to screens (e.g., B2 decision → show Engage/Retreat buttons)
- **Edge cases**: what happens when fuel=0 mid-phase, weapons exhausted, all targets destroyed

### Task 10: Scenario Editor Survey Form
Per Q6 answer, the scenario editor should take inputs as a **multiple-choice survey**. Provide:
- List of survey questions (drone selection, zone count, target types, threat types, objectives, etc.)
- Input types per question (dropdown, multi-select, number input, text)
- Validation rules
- How the survey maps to DB tables (`scenarios`, `scenario_zones`, etc.)

### Task 11: Settings Screen Requirements
Define what goes in the Settings screen:
- Theme toggle (MILSTD dark / light?)
- Sound on/off
- Difficulty settings (if any)
- Game speed / animation speed
- Any other configurable options

**Deliverable**: Updated functional spec document.

---

## Priority Matrix

| Priority | Items | Agent | Why |
|----------|-------|-------|-----|
| 🔴 CRITICAL | 1, 2, 3, 4 | DILEK | Engine CRT tables have placeholder data |
| 🟡 HIGH | 5, 6, 7, 8 | UIDesigner | Can't build screens without design specs |
| 🟢 MEDIUM | 9, 10, 11 | BA/PM | Feature scope for complete app |

> **SeniorDev will start building UI immediately upon receiving Items 5-8.**
> **SeniorDev will patch engine CRT tables immediately upon receiving Items 1-4.**
