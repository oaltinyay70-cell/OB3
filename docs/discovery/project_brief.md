# Drone Commander Mobile — Project Brief

## Overview

**Drone Commander** is a solo board game about UCAV (drone) combat operations. The goal is to adapt it into a **mobile game for iOS** (Android later), starting fresh but reusing the existing SQLite database from the first edition.

**Target audience:** Board gamers and casual mobile players.

---

## Core Gameplay Loop

```
┌─────────────────────────────────────────────┐
│  1. DRAW COMBAT CARD → sets loop conditions │
│  2. SEARCH → find targets in zone           │
│  3. THREAT → resolve enemy threats/SAMs     │
│  4. RESOLVE ACTION → attack/engage          │
│  5. CHECK → win / destruction / fuel        │
│  └──→ loop back to 1 if conditions allow    │
└─────────────────────────────────────────────┘
```

**Player decisions:** Drone selection, loadout configuration, target prioritization, weapon allocation, zone movement, risk assessment (engage vs evade threats).

---

## Existing Assets to Reuse

### Database: `ob3.db` (12 tables)

| Table | Rows | Purpose |
|-------|------|---------|
| `drones` | 28 | UCAV specs (TB2, Reaper, Wing Loong, etc.) with loadout options, class, capabilities |
| `weapons` | 28 | Weapon stats with DRM modifiers per target type |
| `combat_cards` | 18 | Combat event cards that set loop conditions |
| `target_cards` | 111 | Target cards with VP values, altitude restrictions, weapon requirements |
| `threat_cards` | 36 | Threat cards (SAMs, AAA, etc.) with column shifts |
| `scenarios` | 1+ | Scenario definitions with objectives, scoring modes |
| `scenario_zones` | - | Zone layout per scenario |
| `scenario_loadouts` | - | Scenario-specific loadout configurations |
| `scenario_target_deck` | - | Zone-specific target card composition |
| `scenario_threat_deck` | - | Zone-specific threat card composition |
| `scenario_target_ranges` | - | Target engagement ranges per zone |
| `scenario_threat_ranges` | - | Threat engagement ranges per zone |

> [!IMPORTANT]
> The `drones` table in the cards DB has been extended beyond the base version with fields like `max_structural_integrity`, `drone_class`, `has_aeasa_radar`, `has_satcom`, `has_autonomous_ai`, and `description`. This is the most complete version and should be the source of truth.

### Board Game Files (in `Downloads/V3 OBSCURE BATTLES - DRONE COMMANDER/`)

- **Rulebook**: `Obscure Battles - V3 - DRONE COMMANDER V3.1-D10.pdf` (latest version)
- **Cards**: Combat, Target, Threat, Loadout, Drone Info (image assets by folder)
- **Scenarios**: 3 scenario folders + scenario docs
- **Gameboard, Counters, Campaign, Collateral**: Additional assets

### Previous Project (in `Documents/SW DESIGN/DC/`)

- Full Flutter project (will NOT be reused as codebase — fresh start)
- `DRONE COMMANDER RULE BOOK.docx` — additional rulebook format
- `ba_v2.txt` / `ba_v2_clean.txt` — previous business analysis docs
- `parsed_dataset.json` — parsed UCAV data

---

## Key Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Starting point | Fresh codebase | Clean architecture, learned from v1 mistakes |
| Database | Reuse `ob3.db` | Rich, mature data (12 tables, 28 drones, 28 weapons, 111 targets) |
| Platform | **iOS first** | Reduce scope, Flutter makes Android follow-up easy |
| Tech stack | **Flexible** (TBD) | Options: Flutter, native Swift, or other — needs decision |
| Adaptation style | **Faithful mechanics**, adapted UX | Board game rules matter, but mobile UX must be native-feeling |
| Monetization | **Undecided** | Personal project, may explore paid/freemium/ads later |
| Agent workflow | **Agent-per-skill** | Use installed agency skills with the orchestrator |

---

## v1.0 Scope (Definition of Done)

1. **Full rulebook implementation** — all game mechanics from the V3.1 rulebook
2. **Scenario editor** — allows installing/creating custom scenarios
3. All card types functional (combat, target, threat)
4. Drone selection with loadout configuration
5. Zone-based gameplay with movement
6. Win/loss/fuel condition tracking
7. VP scoring

---

## Open Questions Requiring Decision

### 1. Tech Stack

Since you're flexible, here are the realistic options for a fresh start:

| Option | Pros | Cons |
|--------|------|------|
| **A) Flutter (Dart)** | Cross-platform, you have experience, fast dev | Dart ecosystem smaller, custom rendering heavier |
| **B) Swift (native iOS)** | Best iOS performance, native feel, SwiftUI | iOS-only until separate Android app, learning curve if new |
| **C) React Native** | JS ecosystem, large community | Performance for game-like UX can be tricky |
| **D) Godot** | Purpose-built for games, 2D/3D engine | Different paradigm, steeper learning for app-like UI |

> [!IMPORTANT]
> **Recommendation:** Given iOS-first, a card/board game (not action-heavy), and wanting premium feel — **Flutter** or **Swift** are the strongest choices. Flutter if you want Android follow-up to be trivial; Swift if you want the most polished iOS-native experience.

### 2. Agent Workflow Design

You want "an agent for each skill." Before we proceed, we need to define:

- **Which skills are active for this project?** (Not all 70+ are relevant to a game)
- **What's the orchestration model?** (Sequential pipeline? Parallel specialists? On-demand?)
- **Where do agents communicate?** (File-based handoff? Chat monitor like you explored before?)

**Suggested initial agent roster for game development:**

| Agent Role | Skill | Responsibility |
|------------|-------|----------------|
| 🎯 Orchestrator | `agency-agents-orchestrator` | Pipeline coordination |
| 📋 Business Analyst | `agency-senior-project-manager` | Spec from rulebook, task breakdown |
| 🎨 UI Designer | `agency-ui-designer` | Game UI design system |
| 🏗️ UX Architect | `agency-ux-architect` | Game flow, screen architecture |
| 💻 Senior Dev | `agency-senior-developer` | Core implementation |
| 📱 Mobile Builder | `agency-mobile-app-builder` | Platform-specific concerns |
| 🧪 QA / Evidence | `agency-evidence-collector` | Testing, screenshots, validation |
| ✍️ Tech Writer | `agency-technical-writer` | Documentation |

### 3. Rulebook Parsing

The rulebook is a PDF/DOCX. Before any agent can work, we need to:
- Extract and convert the rulebook to a machine-readable format (markdown)
- Identify all game mechanics, phases, card effects, and resolution tables
- Map board game concepts to mobile game equivalents

> [!NOTE]
> This is the **critical first task** — the rulebook is the source of truth for the entire game. Every other agent depends on a clean, structured version of the rules.

---

## Recommended Next Steps

1. **You decide:** Flutter vs Swift (or other)
2. **You share:** Location of the rulebook PDF/DOCX for parsing
3. **I parse** the rulebook into structured markdown
4. **I set up** the agent workflow with the orchestrator skill
5. **BA agent** creates the functional specification from the parsed rules
6. **UI/UX agents** begin design system and screen architecture
7. **Dev agent** scaffolds the project and integrates the database

---

*Brief created: 2026-03-10*
