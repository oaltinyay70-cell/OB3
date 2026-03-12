# OB3 — Drone Commander Mobile: Project Specification

## Project Overview

Adapt the **Obscure Battles 3: Drone Commander** solo board game into a mobile game for **iOS** (Android later). The game simulates UCAV drone combat operations where players select drones, configure loadouts, and execute missions through a loop of searching targets, facing threats, attacking, and evading counterfire.

## Source Materials

- **Rulebook**: [docs/game-rules/rulebook.md](../docs/game-rules/rulebook.md) (V3.1-D10)
- **Database**: [assets/db/ob3.db](../assets/db/ob3.db)

### Database Schema (12 tables)

| Table | Rows | Key Fields |
|-------|------|------------|
| `drones` | 28 | name, country, category, class, altitude, loadout options, capabilities |
| `weapons` | 28 | type, name, targets, range, altitude, DRM per target type |
| `combat_cards` | 18 | card_number, type, name, instructions, image |
| `target_cards` | 111 | card_number, type, sub_category, name, VP, altitude_restriction, weapon_type |
| `threat_cards` | 36 | card_number, type, sub_category, name, altitude_restriction, column_shift |
| `scenarios` | 1+ | name, campaign, description, objectives, scoring_mode, card counts |
| `scenario_zones` | — | zone_number, star marking, terrain |
| `scenario_loadouts` | — | loadout options per scenario |
| `scenario_target_deck` | — | target card composition per zone |
| `scenario_threat_deck` | — | threat card composition per zone |
| `scenario_target_ranges` | — | target probability ranges per zone |
| `scenario_threat_ranges` | — | threat probability ranges per zone |

## Tech Stack

- **Framework**: Flutter (Dart)
- **Platform**: iOS first
- **Database**: SQLite (via sqflite)
- **State Management**: TBD by architect
- **Architecture**: TBD by architect

## Core Game Loop (from rulebook)

```
B0 (In Transit) → B1 (Search/Combat Card) → B2 (Target Acq + Threat Det)
    ↓ Decision: Engage or retreat to B1
B3 (Positioning/Combat Card) → B4 (Drone Attack) → B5 (Evasive Action)
    ↓ Decision: Continue to B0, go to Base, or pitstop
```

## v1.0 Feature Requirements

1. **Full rulebook mechanics** — all movement, combat, damage, scoring as specified
2. **All card types** — combat (18), target (111), threat (36)
3. **All 28 drones** with loadout configuration
4. **Scenario system** — load from database, zone-based
5. **Scenario editor** — create/install custom scenarios
6. **Play modes** — Solitaire Quick Game, Scenario Game
7. **Campaign mode** — territory-based strategic play (can be v1.1)
8. **2+ Player mode** — competitive (can be v1.1)

## CRITICAL RULE

> **ASK about anything that is not clear. NEVER ASSUME ANYTHING.**
> The rulebook is the source of truth. If something in the rulebook is ambiguous, unclear, or seems contradictory, STOP and ask the user for clarification.
