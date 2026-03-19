# OB3 Drone Commander — How to Play

> A solo tactical UCAV game. One pilot. One drone. One mission.

---

## The Objective

You are a drone operator. Your mission: penetrate enemy airspace, destroy high-value targets, and return your drone intact. The enemy fights back — with anti-aircraft guns, surface-to-air missiles, fighter jets, and small arms.

Every mission ends one of three ways:
- ✅ **RTB** — You completed your objectives and brought the drone home.
- 💀 **Drone Down** — Structural Integrity (SI) reached zero. Mission failed.
- ⛽ **Fuel Exhausted** — You stayed too long. Forced return to base.

---

## Before You Fly

### 1. Select Your Drone

Choose from **28 real-world UCAV platforms** — each with unique stats:

| Stat | What It Means |
|------|--------------|
| **Class** | A (Heavy) → D (Micro). Affects available weapons and altitude. |
| **Altitude** | Which altitude bands this drone can fly (VLOW / LOW / MEDIUM / HIGH). |
| **Endurance** | How many fuel units you start with. More endurance = more cycles. |
| **Structural Integrity (SI)** | Your drone's health. Reaches 0 → destroyed. |
| **AEASA Radar** | +10 bonus when acquiring targets. |
| **SATCOM** | Reduces communications check penalty. |
| **Autonomous AI** | Reduces communications check penalty. |

### 2. Configure Your Loadout

Select your weapons and sensor kits. Weapons are consumed when fired. Choose wisely — you can't rearm mid-mission (v1.0).

| Weapon Type | Best Against |
|-------------|-------------|
| **ATGM** | Armored vehicles, tanks, trucks |
| **Guided Bomb** | Most ground targets |
| **Cruise Missile** | SAM sites and bunkers |
| **Missile** | Personnel, light vehicles, tanks |
| **KIT (FO/Laze)** | Any ground target via fire support |

---

## The Game Loop — Six Phases Per Cycle

Each cycle (one pass through the target area) consists of six phases: **B0 → B1 → B2 → B3 → B4 → B5**, then repeat.

---

### 🔵 B0 — INGRESS *(In Transit)*

Your drone approaches the target area.

- If **COMMS Damage > 2**: Roll a controllability check. Fail (roll ≥ 6) → drone lost.
- Otherwise: automatic, no decisions.

---

### 🟡 B1 — RECON *(Search)*

You sweep the target area.

- **Optional**: Change altitude (costs fuel — more on this below).
- **Required**: Draw a **Combat Card** and execute it immediately.

> ⚠️ Combat cards can help you (+2 attack bonus!) or hurt you (−2 attack, visibility loss, signal lost…). No peeking — draw and deal with it.

---

### 🟠 B2 — CONTACT *(Target Acquisition & Threat Determination)*

The system draws a **Target Card** and a **Threat Card**. Costs 1 fuel.

- **Commander's Decision**: Do you Engage or Retreat?
  - **Engage** → Proceed to B3.
  - **Retreat** → Discard both cards. Return to B1. No fuel wasted on this retreat.

---

### 🔴 B3 — IP *(Positioning)*

You set up your attack run.

- **Optional**: Change altitude.
- No combat card drawn here.

---

### ⚡ B4 — WEAPONS HOT *(Attack)*

This is the combat phase — three decisions, then a dice roll.

**Step 1 — Altitude**: Lock in your attack altitude.

**Step 2 — Weapon**: Pick a weapon (filtered by target type). Incompatible weapons are greyed out.

**Step 3 — Attack Mode**:

| Mode | Altitude | Fuel Cost | Notes |
|------|----------|-----------|-------|
| **Stand-Off** | MEDIUM / HIGH | 1F | Lower risk, lower accuracy at LOWer alt |
| **Close-In** | VLOW / LOW | 2F | Higher risk, more effective up close |
| **FO/Laze** | Any | 3F | Call external fire support — very effective |

**Roll**: 1D6 + your DRM modifiers → consult the Combat Resolution Table (CRT) → **HIT** or **MISS**.

- HIT → target destroyed, VP banked, weapon consumed.
- MISS → no VP. If target was a SAM site → SAM may fire back.

---

### 🟢 B5 — EGRESS *(Evasive Action)*

You break away from the target area. The threat card fires at you.

- Roll 1D6 + evasion modifiers.
- Consult the Counterfire CRT.
- Take damage (SI hits, sensor hits, COMMS hits) or escape clean.
- **Decision**: Continue mission (→ B0) or **RTB** now?

---

## Damage System

Your drone accumulates damage across four systems:

| System | Max | Effect When Damaged |
|--------|-----|---------------------|
| **Structural Integrity (SI)** | Drone's max | Reaches 0 → destroyed |
| **Sensors** | 9 | Every 4 pts → −1 Attack DRM |
| **COMMS** | 5 | >2 → COMMS check each B0 |
| **VIS/RCS** | — | Higher → threats find you easier |

> Sensor and COMMS damage cascade from SI damage — a bad hit can degrade multiple systems at once.

---

## Altitude Guide

| Altitude | Threat Exposure | Best Attack Mode | Notes |
|----------|-----------------|-----------------|-------|
| **VLOW** | Low — hard to detect | Close-In only | Nap-of-earth; avoid radar |
| **LOW** | Moderate | Close-In only | Stand-Off can't land a hit here |
| **MEDIUM** | Standard | Stand-Off | Default starting altitude |
| **HIGH** | High — SAMs love you | Stand-Off | Best hit chance from Stand-Off |

---

## The Card Decks

### Combat Deck (37 cards + 6 NO EVENT)
Drawn at **B1**. Modifies the current cycle.

| Effect Type | What Happens |
|------------|-------------|
| ⬆️ Attack DRM | +1 or +2 to your attack roll |
| ⬇️ Attack DRM | −1 or −2 to your attack roll |
| 📶 Comms | Signal lost, skip comms phase, burst transmission |
| ⛰️ Altitude | Forced altitude change (up or down) |
| 🌤️ Weather | Visibility changes affect your sensors |
| 🚫 No Event | Discard — nothing happens |

### Target Deck (114 cards)
Drawn at **B2**. Tells you what you're attacking and how many VP it's worth.

| Sub-Category | VP Range | Notes |
|------------|---------|-------|
| VIP | 3–10 | Highest value — usually primary objectives |
| SAM | 0.5–5 | Dangerous — may fire back if you miss |
| TANK | 0.5–3.5 | Needs ATGM or Guided Bomb |
| HQ/BUNKER | 2–5 | Best attacked with Cruise Missile |
| PERSONNEL | 0.5–2 | Low VP but sometimes primary objective |

### Threat Deck (36 cards)
Drawn at **B2** alongside the target. This is what shoots at you during B5.

| Category | Danger Level | Notes |
|----------|-------------|-------|
| CAP (Fighter jets) | ⚠️⚠️⚠️ | Worst at HIGH altitude |
| SAM | ⚠️⚠️⚠️ | Worst at MEDIUM/HIGH |
| AAA | ⚠️⚠️ | Worst at LOW |
| DRONE GUN | ⚠️ | Specialist C-UAS systems |
| SMALL ARMS | ⚠️ | Light threat, mostly LOW altitude |

---

## Victory Points (VP)

- Each destroyed target has a **VP value** printed on the card.
- Secondary objective VP is **only counted** if the primary objective is also completed.
- Your final **score** = sum of VP from destroyed targets.

---

## Tips for New Operators

1. **Start at MEDIUM**. It's the default altitude for a reason — balanced risk.
2. **Don't ignore the combat card**. A −2 attack DRM card at the start of a cycle changes your whole plan.
3. **Know your threats**. If a SAM is your threat card, consider flying LOW before attacking.
4. **Retreat is valid**. If the target/threat combo looks bad, retreat costs you nothing except one cycle.
5. **Fuel is your clock**. Every cycle burns fuel. Don't dawdle if you're on a long-range drone.
6. **Sensor damage compounds**. At Sensor Damage 8, you're at −2 to all attacks. Protect that drone.

---

## Glossary

| Term | Meaning |
|------|---------|
| **UCAV** | Unmanned Combat Aerial Vehicle — your drone |
| **DRM** | Die Roll Modifier — added to dice rolls |
| **CRT** | Combat Resolution Table — determines hit/miss and damage |
| **SI** | Structural Integrity — drone's health points |
| **RTB** | Return to Base — voluntary or forced mission end |
| **VIS/RCS** | Visibility / Radar Cross Section — how visible your drone is |
| **CAP** | Combat Air Patrol — enemy fighters |
| **SAM** | Surface-to-Air Missile system |
| **AAA** | Anti-Aircraft Artillery |
| **FO/Laze** | Forward Observer / Laser Designation — calls in external fires |
| **VP** | Victory Points — your final score |
| **B0–B5** | The six phases of each game cycle |

---

*Good luck, operator. Bring the drone home.*
