# OB3 Scenario Editor

A Flutter web application for designing, testing, and managing scenarios for the **OB3 Drone Commander** mobile game.

## Getting Started

```bash
cd tools/scenario_designer   # from OB3 project root
flutter pub get
flutter run -d chrome --web-port=8080
```

## Features

### 9-Step Scenario Wizard
1. **Basic Info** — Title, description, briefing visual (JPG/PNG upload, max 100 KB), overview, mission briefing
2. **Drones** — Select available drones (multi-select or "ALL")
3. **Objectives** — Define primary + secondary objectives (NAMED_CARD / KILL_QUOTA conditions)
4. **Target Cards** — Build the target deck (card_id:quantity)
5. **Threat Cards** — Build the threat deck (card_number:quantity)
6. **Combat Cards** — Build the combat deck (card_id:quantity)
7. **Modifiers** — Gameplay adjustments (fuel cost, attack roll, evasion, etc.)
8. **Loadouts** — Exclude specific loadout options per drone
9. **Metadata & Review** — Difficulty, play time, author, tags, summary

### Export / Import
- **Export ⬇** — Available on **all 9 wizard steps** + the scenario list page
  - Format: `.txt` (human-readable `KEY: VALUE` with `#` remarks and working examples)
  - All fields included (filled or empty)
  - Downloads via browser to Downloads folder
  - File naming: `{name}_v{version}.txt`
- **Import** — Reads `.txt` file, validates IDs against DB, opens pre-populated wizard
- **Save Draft** — Saves to DB without validation (WIP scenarios)
- **Publish** — Validates all required fields (shows clean dialog with bulleted list of issues), then writes to `ob3.db`

### Validation (on Publish)
Shows a styled AlertDialog listing all missing fields:
- Title, Short Description, Overview, Mission Briefing (required)
- At least 1 drone selected
- At least 5 target, threat, and combat cards each
- At least one objective marked `is_primary`
- NAMED_CARD conditions must reference existing card names

### Objective System (Sprint OBJ-1)
- Objectives stored in `scenario_objectives` table (replaces old flat columns)
- **NAMED_CARD**: eliminate a specific named target card
- **KILL_QUOTA**: eliminate N cards of a target sub_category (TANK, AFV, etc.)
- **Compound**: multiple conditions under same objective — ALL must be met
- **Weapon requirement**: optional per condition — kill only counts with correct weapon
- One primary + N secondary objectives per scenario
- In-game: evaluated after every kill at B4 via `ObjectiveEvaluator` pure function
- Autocomplete for card names, import objectives from existing scenarios

### Scenario Versioning
- New scenarios start at `v1.00`
- Each save increments by `+0.01`
- Displayed as `vX.XX` in AppBar

### Briefing Visual
- File upload between Short Description and Overview
- Accepts: JPG, PNG — max 100 KB
- Recommended: 16:9 landscape
- Stored as base64 data URI in `mission_briefing_image_path`
- Live preview with Remove button

## Tech Stack
- Flutter (web target)
- SQLite via `sqflite_common_ffi_web`
- `file_picker` for import/export file dialogs
- Custom design system (military/tactical theme)

## Database
Uses `ob3.db` (bundled in `assets/data/`). The editor adds columns via `ALTER TABLE` on first run for designer-specific fields (version, modifiers, objectives, briefing image, etc.).
