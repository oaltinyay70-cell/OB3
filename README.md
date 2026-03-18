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

UX-designed card images are stored in `assets/images/cards/`:

| Type | Directory | Count | Naming |
|------|-----------|-------|--------|
| Combat | `cards/combat/` | 24 | `CC001.png` … `CC024.png` |
| Target | `cards/targets/` | 17 | `TCTA001.png`, `TCAF002.png`, etc. |
| Threat | `cards/threats/` | 5 | `THAAA001.png`, `THCAP003.png`, etc. |

Card models provide an `imagePath` getter that maps `card_number` → asset path.
The UI uses a 3-tier fallback: **asset image → DB BLOB → styled text**.

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

SQLite database at `assets/db/ob3.db`. Contains tables for drones (28), weapons, combat/target/threat cards, scenarios, loadouts, and CRT tables.
