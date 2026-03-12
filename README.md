# OB3 — Drone Commander Mobile

> A mobile game adaptation of the **Obscure Battles 3: Drone Commander** solo board game — UCAV combat operations on your phone.

🚧 **Status:** In Development — Phase 1: Analysis & Design

---

## Why This Exists

The original Drone Commander is a rich, deeply tactical solo board game about modern drone warfare. It has 28 real-world UCAVs, complex loadout decisions, and a game loop that rewards risk assessment over luck. But it requires a table, printed cards, dice, and 20 minutes of setup.

This project adapts those mechanics into a native mobile experience — faithful to the rulebook, but with the UX players expect from a modern game app.

## Quick Start

> **No runnable app yet.** The project is in the planning and documentation phase. See [Roadmap](#roadmap) below.

To explore the project materials:

```bash
git clone <repo-url>
cd tidal-comet
```

Browse the key documents:
- [Rulebook (V3.1-D10)](docs/game-rules/rulebook.md) — the source of truth for all game mechanics
- [Game Loop Diagram](docs/game-rules/game_loop_diagram.md) — visual flowchart of the B0–B5 cycle
- [Architecture](ARCHITECTURE.md) — system design, state machine, database schema
- [Project Brief](docs/discovery/project_brief.md) — background and key decisions

---

## Game Overview

You are a **Drone Commander**. You select a UCAV, configure its loadout, and fly missions across scenario zones — searching for targets, evading threats, and managing fuel and structural integrity.

### Core Game Loop

Each mission is a series of **cycles** through six phases:

```
B0 (In Transit) → B1 (Search) → B2 (Target/Threat) → B3 (Positioning) → B4 (Attack) → B5 (Evasion)
     ↑                                                                                      │
     └──────────────────────────── continue / RTB / destroyed ──────────────────────────────┘
```

| Phase | Name | What Happens |
|-------|------|-------------|
| **B0** | In Transit | COMMS check if damaged; set starting altitude |
| **B1** | Search | Optional altitude change; draw combat card |
| **B2** | Target Acq / Threat Det | Roll 2D10 for target and threat; decide: engage or retreat |
| **B3** | Positioning | Optional altitude change; draw combat card |
| **B4** | Drone Attack | Select mode → weapon → altitude → roll → consult CRT |
| **B5** | Evasive Action | Roll for counterfire; apply damage; decide: continue or RTB |

### Key Player Decisions

- **Drone selection** — 28 real-world UCAVs with different capabilities and loadout options
- **Loadout configuration** — weapon types restrict which targets you can engage and how
- **Engage or retreat** (B2) — is the target VP worth the threat risk?
- **Attack mode** (B4) — Stand-Off (safe, low hit), Close-In (risky, high hit), FO/Laze (variable)
- **Continue or RTB** (B5) — burn more fuel for more VP, or bank your score?

---

## Database

The game reuses the mature `ob3.db` from the first edition — 12 tables with comprehensive game data:

| Table | Rows | Purpose |
|-------|------|---------|
| `drones` | 28 | UCAV specs: class, altitude, loadout options, capabilities |
| `weapons` | 28 | Weapon stats with DRM modifiers per target type |
| `combat_cards` | 18 | Battlefield event cards that set loop conditions |
| `target_cards` | 111 | Targets with VP values, altitude restrictions, weapon requirements |
| `threat_cards` | 36 | Threats (SAMs, AAA, etc.) with column shift modifiers |
| `scenarios` | 1+ | Scenario definitions with objectives and scoring modes |
| `scenario_zones` | — | Zone layout per scenario |
| `scenario_loadouts` | — | Available loadouts per scenario |
| `scenario_target_deck` | — | Target card composition per zone |
| `scenario_threat_deck` | — | Threat card composition per zone |
| `scenario_target_ranges` | — | Target probability ranges per zone |
| `scenario_threat_ranges` | — | Threat probability ranges per zone |

---

## Tech Stack

| Layer | Choice | Rationale |
|-------|--------|-----------|
| **Framework** | Flutter (Dart) | Cross-platform; Android follow-up is trivial |
| **Platform** | iOS first | Reduce scope for v1.0 |
| **Database** | SQLite via `sqflite` | Reuse existing mature database |
| **State Management** | TBD by architect | — |
| **Architecture** | TBD by architect | — |

---

## Project Structure

```
tidal-comet/
├── README.md                   # ← You are here
├── ARCHITECTURE.md             # System design, state machine, database schema
├── CONTRIBUTING.md             # How to contribute, conventions, agent workflow
├── agents/                     # Agent role definitions (8 agents)
│   ├── DILEK.md                # 🎯 Orchestrator
│   ├── OB3-ProjectManager.md   # 📋 Business Analyst / PM
│   ├── OB3-UXArchitect.md      # 🏗️ UX Architect
│   ├── OB3-UIDesigner.md       # 🎨 UI Designer
│   ├── OB3-SeniorDev.md        # 💻 Senior Developer
│   ├── OB3-MobileBuilder.md    # 📱 Mobile App Builder
│   ├── OB3-QA.md               # 🧪 Evidence Collector (QA)
│   └── OB3-TechWriter.md       # ✍️ Technical Writer
├── assets/
│   └── db/                     # ob3.db (SQLite)
├── docs/
│   ├── discovery/              # Project brief, discovery Q&A
│   ├── game-rules/             # Parsed rulebook, game loop diagram
│   ├── specs/                  # Functional specs (TBD)
│   └── task.md                 # Master task checklist
├── project-specs/              # Agent pipeline specs, setup docs
├── project-tasks/              # Agent task lists (TBD)
└── lib/                        # Flutter source code (TBD)
```

---

## Agent Roster

Development uses an 8-agent pipeline, each with a specialized skill:

| # | Agent | Skill | Responsibility |
|---|-------|-------|----------------|
| 1 | **DILEK** | Orchestrator | Pipeline coordination, quality gates |
| 2 | **OB3-ProjectManager** | Senior PM | Rulebook → functional spec, task breakdown |
| 3 | **OB3-UXArchitect** | UX Architect | Game flow, screen architecture, state machine |
| 4 | **OB3-UIDesigner** | UI Designer | Design system, components, MILSTD theme |
| 5 | **OB3-SeniorDev** | Senior Developer | Core game engine, business logic |
| 6 | **OB3-MobileBuilder** | Mobile Builder | iOS build, native integration, deployment |
| 7 | **OB3-QA** | Evidence Collector | Testing, screenshots, PASS/FAIL validation |
| 8 | **OB3-TechWriter** | Technical Writer | README, ARCHITECTURE, API docs |

---

## Roadmap

| Phase | Status | Description |
|-------|--------|-------------|
| **0: Foundation** | 🟢 Done | Discovery, rulebook parsing, project setup |
| **1: Analysis & Design** | 🟡 In Progress | Functional spec, UX architecture, design system |
| **2: Project Setup** | ⬜ Planned | Flutter scaffold, database integration, project structure |
| **3: Core Implementation** | ⬜ Planned | Game engine, card systems, combat resolution |
| **4: Scenario System** | ⬜ Planned | Scenario loader, scenario editor |
| **5: Polish & QA** | ⬜ Planned | Evidence collection, documentation, iOS deployment |

### v1.0 Feature Requirements

1. Full rulebook mechanics (movement, combat, damage, scoring)
2. All card types — combat (18), target (111), threat (36)
3. All 28 drones with loadout configuration
4. Scenario system — load from database, zone-based
5. Scenario editor — create/install custom scenarios
6. Play modes — Solitaire Quick Game, Scenario Game

### Deferred to v1.1+

- Campaign mode (territory-based strategic play)
- 2+ Player competitive mode

---

## Documentation

| Document | Description |
|----------|-------------|
| [Rulebook](docs/game-rules/rulebook.md) | Complete game rules (V3.1-D10) with Q&A |
| [Game Loop Diagram](docs/game-rules/game_loop_diagram.md) | Mermaid flowchart of B0–B5 cycle |
| [Functional Specification](docs/specs/functional-spec.md) | Core mechanics, state machine rules, scoring |
| [UX Architecture](docs/specs/ux-architecture.md) | Screen flows, components, component hierarchy |
| [Design System](docs/specs/design-system.md) | Colors (MILSTD dark), typography, UI widgets |
| [Architecture](ARCHITECTURE.md) | System design, state machine, database |
| [Project Brief](docs/discovery/project_brief.md) | Background, key decisions, scope |
| [Discovery Q&A](docs/discovery/discovery_questions.md) | Answered discovery questions |
| [Game Engine API](docs/specs/game-engine-api.md) | Internal API reference for game mechanics |
| [Task Breakdown](project-tasks/task-breakdown.md) | 27-step developer implementation plan |
| [Agent Roster](project-specs/agent-roster.md) | Agent roles and pipeline flow |

---

## Critical Rule

> **ASK about anything that is not clear. NEVER ASSUME ANYTHING.**
> The rulebook is the source of truth. If something is ambiguous, unclear, or contradictory — STOP and ask.

---

## License

Private project — not yet licensed for distribution.
