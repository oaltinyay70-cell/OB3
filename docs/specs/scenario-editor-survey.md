# OB3 — Drone Commander Mobile: Scenario Editor Survey
> **Agent**: OB3-ProjectManager (BA)
> **Date**: 2026-03-11
> **Status**: Ready for Review

## 1. Overview
As confirmed by the game designer, the v1.0 Scenario Editor will function as a **multiple-choice, step-by-step survey form**. This approach guarantees that valid, playable scenarios are generated and stored correctly in the SQLite database without requiring a complex visual map editor.

The output of this survey populates the following tables:
- `scenarios`
- `scenario_zones`
- `scenario_threat_deck`
- `scenario_target_deck`
- `scenario_threat_ranges`
- `scenario_target_ranges`
- `scenario_loadouts`

---

## 2. Step-by-Step UX Flow

### Step 1: Scenario Setting & Narrative
*Define the context and flavor of the mission.*

| Field | UI Type | Constraints | DB Mapping |
|-------|---------|-------------|------------|
| Scenario Name | Text Input | Required, max 50 chars | `scenarios.name` |
| Brief Description | Text Input | Required, max 100 chars | `scenarios.description` |
| Narrative Briefing | Text Area | Optional, max 1000 chars | `scenarios.narrative` |
| Campaign Assignment | Dropdown | Optional (picks from campaigns) | `scenarios.campaign_name` |

### Step 2: Drone & Rules Constraints
*Limit what the player can use to increase difficulty or realism.*

| Field | UI Type | Constraints | DB Mapping |
|-------|---------|-------------|------------|
| Allowed Drones | Multi-select Dropdown | Default: "All 28 drones". Can select specific drones. | (Handled via application logic / link table) |
| Hardcoded Drone | Toggle + Dropdown | If ON, forces a specific drone. | `scenarios.drone_id` |
| Scoring Mode | Radio Buttons | MAXIMUM_KILL or QUICK_KILL | `scenarios.scoring_mode` |
| Reinforcement Rule | Text Input | Text rule for campaign integration | `scenarios.reinforcement_rule` |
| Special Global Rules | Text Area | Plain text modifier rules | `scenarios.special_rules` |

### Step 3: Primary Objective
*Define what constitutes mission success (critical for QUICK_KILL).*

| Field | UI Type | Constraints | DB Mapping |
|-------|---------|-------------|------------|
| Objective Description | Text Input | Required | `scenarios.primary_objective` |
| Objective Target Name | Dropdown (Target Cards) | Select specific target (e.g., "General Barkov") | `scenarios.primary_objective_card_name` |
| Required Weapon Type | Dropdown (Weapon Types) | e.g., "BUNKER BUSTER" required | `scenarios.primary_objective_weapon_req` |
| Completion Zone | Select | Dropdown of Zone 1-9 | `scenarios.primary_objective_zone` |

### Step 4: Environment & Zoning
*Break the mission into geographical operations.*

| Field | UI Type | Constraints | DB Mapping |
|-------|---------|-------------|------------|
| Number of Zones | Stepper/Spinner | Min 1, Max 9 | Generates X rows in `scenario_zones` |

*(For each created zone, prompt the following)*:
| Field | UI Type | Constraints | DB Mapping |
|-------|---------|-------------|------------|
| Zone Title | Text Input | Required (e.g., "Coastal Approach") | `scenario_zones.name` |
| Zone Narrative | Text Area | Flavour text for terrain | `scenario_zones.terrain_description` |

### Step 5: Card Pool Building
*Construct the exact target and threat decks.*

**(This page repeats per zone defined in Step 4)**

**Target Deck:**
- UI: List of 10 sub-categories (AFV, AIR, ARTILLERY, ENGINEER, HQ-BUNKER, PERSONNEL, SAM, TANK, TRUCK, VIP).
- Interaction: User specifies *Quantity* for each category to include in this zone.
- *DB Mapping*: Generates `scenario_target_deck` records.

**Threat Deck:**
- UI: List of 5 sub-categories (AAA, CAP, Anti-Drone Weapon, SAM, Small Arms).
- Interaction: User specifies *Quantity* for each.
- *Advanced Toggle*: For each threat, user can add a "Special Rule" string (e.g., "Any 1D hit is DOUBLED").
- *DB Mapping*: Generates `scenario_threat_deck` records.

### Step 6: Acquisition Probability Ranges
*Override default D100 dice roll target/threat acquisition mapping.*

**Target Ranges Override:**
- UI: 10 sliders with dual thumbs (0-100) stacked vertically, or numeric matrix inputs.
- Validation logic: Ranges must be *exclusive* and *contiguous* (no overlapping numbers, e.g., 0-18, 19-34).
- Default: Pre-filled with rulebook default ranges.
- *DB Mapping*: `scenario_target_ranges`

**Threat Ranges Override:**
- UI: 5 sliders/numeric matrix (similar to target ranges).
- Validation: Exclusive and contiguous.
- Default: Pre-filled with rulebook default ranges.
- *DB Mapping*: `scenario_threat_ranges`

### Step 7: Combat Event Volatility
*Determine how chaotic the airspace is.*

| Field | UI Type | Constraints | DB Mapping |
|-------|---------|-------------|------------|
| # Event Cards | Stepper/Spinner | Range: 0 - 12 (drawn from DB CC001-CC006, CC013-018) | `scenarios.combat_event_count` |
| # "No Event" Cards | Stepper/Spinner | Range: 0 - 6 (drawn from DB CC007-CC012) | `scenarios.combat_no_event_count` |

---

## 3. Validation & Generation Logic

Before saving, the survey must run a validation pass:
1. **Objective Check**: Does the target card selected as the primary objective actually exist in the quantities specified in the Target Deck build (Step 5)?
2. **Range Validation**: Do the acquisition ranges (Step 6) leave any gaps or overlaps? Does it cover 0-100%?
3. **Empty Decks**: A scenario cannot have 0 target cards. It will be rejected.

If valid:
- Generate a unique `scenario_id`.
- Execute a batched SQLite transaction `INSERT` across all 7 relevant scenario tables.
- Return user to Main Menu with a success toast.

---
*End of Specification*
