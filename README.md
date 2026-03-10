# OB3 — Drone Commander Mobile

A mobile game adaptation of the Drone Commander solo board game. Built with Flutter, targeting iOS first.

## Status

🚧 **In Development** — Phase 0: Foundation

## Project Structure

```
DC3/
├── docs/
│   ├── discovery/          # Project brief, discovery Q&A
│   ├── game-rules/         # Parsed rulebook (markdown)
│   └── specs/              # Functional specifications
├── project-specs/          # Agent pipeline specs
├── project-tasks/          # Agent task lists
├── assets/                 # Game assets (DB, images)
└── lib/                    # Flutter source (TBD)
```

## Game Overview

**Drone Commander** is a solo board game about UCAV combat operations. Players select drones, configure loadouts, and execute missions across scenario zones — drawing combat cards, searching targets, resolving threats, and managing fuel/damage.

### Core Loop
1. Draw combat card → sets conditions
2. Search → find targets
3. Threat → resolve enemy threats
4. Resolve action → engage
5. Check → win / destruction / fuel → loop

## Database

Reusing the existing `drone_commander_cards.db` from v1 with 12 tables covering 28 drones, 28 weapons, 111 targets, 36 threats, 18 combat cards, and scenario data.

## Tech Stack

- **Framework**: Flutter (Dart)
- **Platform**: iOS first, Android follow-up
- **Database**: SQLite (existing)
- **Architecture**: TBD

## Documentation

- [Discovery Questions](docs/discovery/discovery_questions.md)
- [Project Brief](docs/discovery/project_brief.md)
