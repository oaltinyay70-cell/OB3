# OB3 Drone Commander — About This Project

## What Is This?

**OB3 Drone Commander** is a digital adaptation of the tabletop wargame *Obscure Battles 3: Drone Commander* — a single-player solo tactical game where you command an unmanned combat aerial vehicle (UCAV) against a randomized enemy threat system.

The game is built as a native iOS mobile application using Flutter, designed around a military intelligence dashboard aesthetic (MILSTD dark theme).

---

## The Concept

Modern warfare is increasingly dominated by drones. OB3 Drone Commander puts you in the seat of a ground control station operator tasked with penetrating enemy air defenses, acquiring and destroying high-value targets, and extracting your drone without losing it.

Every mission is a balance of risk vs. reward:
- Fly low to avoid detection — but close-in threats become lethal.
- Fly high for longer stand-off range — but SAMs and CAP aircraft become more dangerous.
- Choose your weapons wisely — different targets require different munitions.
- Manage your fuel — running out means mission failure.

---

## Who Is This For?

| Audience | What They Get |
|----------|--------------|
| **Wargame enthusiasts** | A faithful digital port of a physical card/dice game |
| **Strategy gamers** | A tactical solo experience with meaningful decisions each cycle |
| **Military tech fans** | 28 real-world drone platforms, accurate weapon systems, realistic threat environments |
| **Designers** | An open scenario system — create custom missions with the built-in Scenario Editor |

---

## Platform & Technology

| Aspect | Detail |
|--------|--------|
| **Platform** | iOS (iPhone & iPad, v1.0) |
| **Framework** | Flutter / Dart |
| **Database** | SQLite (`assets/db/ob3.db`) |
| **Theme** | MILSTD dark intelligence dashboard |
| **Architecture** | Event-driven state machine (B0–B5 game loop) |

---

## What Makes It Different

- **No opponents required** — fully solo, no network, no AI opponent. You vs. the card system.
- **37 combat cards** across two distinct decks — the original CC set and a new NEW_CC set with altitude and attack modifiers.
- **114 target cards** across 10 sub-categories (AFV, SAM, TANK, VIP, PERSONNEL…).
- **36 threat cards** across 5 categories (AAA, CAP, DRONE GUN, SAM, SMALL ARMS).
- **28 real-world UCAV platforms** with distinct stats, altitude envelopes, and special abilities.
- **Scenario Editor** — a standalone web tool for creating custom missions and decks.

---

## Related Documentation

| Document | Purpose |
|----------|---------|
| [`README.md`](README.md) | Quick start for developers |
| [`ARCHITECTURE.md`](ARCHITECTURE.md) | System design, data model, game loop |
| [`HOW_TO_PLAY.md`](HOW_TO_PLAY.md) | Player-facing game guide |
| [`docs/specs/PRD.md`](docs/specs/PRD.md) | Full product requirements |
| [`docs/specs/card-visual-spec.md`](docs/specs/card-visual-spec.md) | Card visual format spec (pixel-precise) |
| [`docs/game-rules/rulebook.md`](docs/game-rules/rulebook.md) | Original game rulebook reference |

---

## Project Status

| Component | Status |
|-----------|--------|
| Game engine (B0–B5) | ✅ Implemented |
| Card database | ✅ Complete (37 CC + 114 TC + 36 TH) |
| Drone database | ✅ Complete (28 drones) |
| Weapon system | ✅ Implemented |
| Scenario Editor | ✅ Implemented |
| iOS App | 🔄 Active development |
| Campaign mode | ⏳ v1.1 |

---

*OB3 Drone Commander — A tribute to the operators who fly the missions others only read about.*
