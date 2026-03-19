# OB3 — Drone Commander

UCAV combat mobile game for iOS. Single-player tactical board game digitized in Flutter.

## Game Flow

```
Splash → Call Sign → Main Menu → Drone Selection (+ Loadout) → Mission Briefing → Game Board → Debrief
```

### Game Loop (B0–B5)

| Phase | Display Name | Description |
|-------|-------------|-------------|
| B0 | **INGRESS** | COMMS check (auto) |
| B1 | **RECON** | Altitude change + combat card draw |
| B2 | **CONTACT** | Target acquisition + threat determination → engage/retreat |
| B3 | **IP** | Altitude positioning only (no combat card) |
| B4 | **WPN HOT** | Select attack mode + weapon → execute attack |
| B5 | **EGRESS** | Evasion roll → continue/RTB |

## Project Structure

```
lib/
├── main.dart
├── app.dart                          # Navigation, theme, game setup
├── core/
│   ├── theme/milstd_theme.dart       # MILSTD dark military design tokens
│   └── database/database_helper.dart # SQLite provider
├── models/                           # Data classes
│   ├── drone.dart, weapon.dart
│   ├── combat_card.dart, target_card.dart, threat_card.dart
│   └── game_enums.dart
├── engine/                           # Pure game logic
│   ├── game_engine.dart              # State machine (B0–B5)
│   ├── game_state.dart, drone_state.dart
│   ├── deck_manager.dart, damage_system.dart
│   └── combat_card_handler.dart
├── data/repositories/                # DB access layer
├── features/
│   ├── splash/, callsign/, main_menu/
│   ├── drone_selection/              # Drone + loadout picker
│   ├── briefing/                     # Mission briefing
│   └── game/                         # Game board screen + BLoC
└── shared/widgets/                   # Reusable components
```

## Card Visuals

All card images are stored as BLOBs in `assets/db/ob3.db`. The UI uses a 3-tier fallback: **DB BLOB → asset image → styled text**.

| Type | DB Table | Count | Format |
|------|----------|-------|--------|
| Combat (original) | `combat_cards` | 18 | `CC001`–`CC018` |
| Combat (NEW_CC) | `combat_cards` | 19 | `NEW_CC_01`–`NEW_CC_19` |
| Target | `target_cards` | 114 | `TCXX000` (10 sub-categories) |
| Threat | `combat_cards` | 36 | `THXXX-000` (5 sub-categories) |

**Locked-in visual format:** See [`docs/specs/card-visual-spec.md`](docs/specs/card-visual-spec.md) for pixel-precise specs (canvas size, Pantone colors, typography, spacing).

## Status Ribbon

| Indicator | Display |
|-----------|---------|
| Integrity | Color-coded progress bar (green → yellow → red) |
| Sensors | Numeric (0–9) |
| COMMS | Numeric (0–5) |
| VIS/RCS | Numeric |
| Altitude | Badge (VLOW / LOW / MEDIUM / HIGH) |

## Key Design Decisions

- **B3 has no combat card** — purely altitude/positioning phase
- **Game auto-starts** — no "READY FOR LAUNCH" intermediate screen
- **Weapon altitude restrictions** — weapons can only fire at specific altitudes; UI shows snackbar error
- **Phase headers removed** — more screen space for cards and controls
- **Altitude selector inline** — compact single-row with ALT label

## Running

```bash
flutter run          # Debug on connected device
flutter run -d ios   # iOS simulator
```

## Database

SQLite database at `assets/db/ob3.db`. Contains:

| Table | Rows |
|-------|------|
| `drones` | 28 |
| `weapons` | 28 |
| `combat_cards` | 37 (18 CC + 19 NEW_CC) + 36 threat cards |
| `target_cards` | 114 (10 sub-categories) |
| `scenarios` | varies |

> Threat cards and combat cards share the `combat_cards` table, distinguished by `card_type`.
