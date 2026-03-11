# Obscure Battles 3: Drone Commander — Rulebook (V3.1-D10)

> Drone Warfare in the 20th and 21st Centuries
> Game Design: © Freman Goldbo | Graphics: © Idilix Graphics and Design Studio

---

## 0. Official Game Glossary

> [!IMPORTANT]
> Definitions provided directly by the game designer. These are canonical.

| Term | Definition |
|------|-----------|
| **Campaign** | A structured sequence of one or more Scenarios that the player progresses through in order. |
| **Scenario** | A single mission within a Campaign or as a standalone engagement. Defined by the scenario designer. |
| **Combat Card** | A card drawn at the start of each cycle whose effects modify gameplay mechanics for **that cycle only**. |
| **Target Card** | A card drawn representing an enemy target that the drone attempts to engage. |
| **Threat Card** | A card drawn representing a danger that may damage or destroy the drone. |
| **VP** | Victory Points. Scored when a target is killed. **Banked immediately — retained even if drone is destroyed later in the same cycle.** |
| **Kill List** | Running record of target card names confirmed killed during the scenario. |
| **RTB** | Return to Base. Player-initiated action to end the scenario and trigger post-scenario briefing. Remaining fuel has no score value. |
| **Primary Objective** | Required kill targets. Must be achieved to advance to the next scenario in a Campaign. |
| **Secondary Objective** | Optional targets. VP awarded **only if primary objective is also achieved**. |
| **Drone Height** | Current altitude: Very Low / Low / Medium / High. Affects **hit probability, evasion probability, damage multiplier, and fuel consumption rate**. |
| **Loadout** | Munitions configuration selected by the player before the scenario begins. |

### 0.1 New Mechanical Rules Extracted from Glossary

> [!NOTE]
> These rules are embedded in the glossary definitions above and must be implemented in the game engine.

1. **VP Banking**: VP is scored the moment a target is killed and permanently banked. A drone being destroyed in the same cycle does NOT forfeit already-banked VP.
2. **Kill List**: The game must maintain a running list of killed target card names (displayed in post-scenario briefing).
3. **Secondary Objectives**: VP from secondary objectives is only awarded if primary objectives are also achieved. Secondary VP is conditional, not automatic.
4. **Altitude affects 4 factors**:
   - Hit probability (attack success chance)
   - Evasion probability (surviving counterfire)
   - Damage multiplier (how much damage hits deal)
   - Fuel consumption rate (higher altitude = different burn rate?)
5. **Fuel at RTB**: Remaining fuel when RTB is triggered has **no score value**.
6. **Combat Card scope**: Effects apply for **that cycle only** — reset at B0 of the next cycle.

---

## 1. Introduction


The player takes the role of a Drone Commander trying to locate and destroy enemy assets using one of the available Drone Types. The game simulates modern drone warfare operations involving UCAVs from multiple nations.

### 1.1. Game Hierarchy

> [!IMPORTANT]
> Official three-level hierarchy defined by game designer.

The game is structured as a **strict three-level hierarchy**:

| Level | Entity | Description |
|-------|--------|-------------|
| 1 | **Campaign** | Container for an ordered sequence of Scenarios. Tracks **cumulative VP** and campaign progression gate. |
| 2 | **Scenario** | A single mission with its own card decks, objectives, VP targets, and termination conditions. |
| 3 | **Cycle** | The atomic unit of gameplay: a repeating **three-step loop** of Combat / Target / Threat card resolution. |

```
Campaign  (cumulative VP, progression gate)
  └── Scenario  (own card decks, objectives, VP targets, termination conditions)
        └── Cycle  (Combat Card → Target Card → Threat Card)
```

> [!NOTE]
> **Reconciliation with B0–B5**: The original boardgame rulebook describes movement boxes B0–B5 within each cycle. The three-card sequence (Combat/Target/Threat) maps to specific B boxes. Designer clarification needed on exact mapping:
> - **Combat Card** drawn at → B1 (Search)?
> - **Target Card** drawn at → B3 (Positioning)?
> - **Threat Card** resolved at → B4/B5 (Attack/Evasion)?

### 1.2. Scenario Termination Conditions

> [!IMPORTANT]
> The scenario ends **immediately** upon any of the following conditions.

**RTB (Return To Base)** = the end of the current scenario.

| # | Condition | Post-Scenario Path |
|---|-----------|-------------------|
| 1 | **Drone destroyed** (HP = 0) | Post-scenario briefing displayed. All banked VP retained. If primary not met, **campaign does not advance**. |
| 2 | **Fuel exhausted** | Post-scenario briefing displayed. Campaign advancement depends on whether primary was achieved before fuel ran out. |
| 3 | **Player chooses RTB** (voluntary, available at any time) | Post-scenario briefing displayed. Campaign advancement depends on primary objective status. |

**After every scenario end:**
- A **Post-Scenario Briefing** screen is always displayed (same code path for all 3 conditions)
- If scenario is part of a campaign: **player must complete scenarios in order — no skipping ahead**
- Campaign advances **only if primary objective was achieved**

### 1.3. Campaign Progression Rules

| Rule | Specification |
|------|--------------|
| **Advance Condition** | Player may proceed to the next scenario **ONLY IF** the primary objective of the current scenario was achieved |
| **Fail / Retry State** | If primary objective not achieved, the next scenario remains **locked**. Player must retry the current scenario |
| **Secondary VP Rule** | Secondary objective VP is added to the campaign score **ONLY** if primary was also achieved in that scenario |
| **Standalone Scenarios** | Scenarios not part of a campaign have no progression gate. Post-scenario briefing shows results only |

---

## 2. How the Game is Played

The game is a board game simulating a Drone Operation based on sensory input and, in some scenarios, scripted conditional engagements. Different drone types are operated by the player against enemies determined by scenario settings.

**Dice Required:** One D6 (six-sided) and two D10 (ten-sided).

### 2.1. Deck Composition

> [!IMPORTANT]
> Official card deck rules for mobile adaptation.

- **Three Independent Decks**: Each scenario utilizes three distinct card decks: **Combat**, **Target**, and **Threat**.
- **Scenario Defined**: The composition of each deck (specific card IDs and their quantities) is defined by the scenario designer and stored in the database.
- **Duplicates Permitted**: A scenario designer may include the same card more than once in a deck (duplicates are intentional and fully supported).
- **Independent Shuffling**: Each deck is shuffled independently before the scenario begins.

### 2.2. Deck Exhaustion

- If any deck runs out of cards mid-scenario, that deck is **immediately reshuffled** from its full original designer-defined composition.
- Play continues without interruption. **The scenario does NOT end due to deck exhaustion.**

### 2.2.1. Deck Orientation & Storage
- **Backside Up**: All decks (Target, Threat, Combat) must be placed in their respective card holding boxes **backside up** (face-down).
- **Identification**: Decks are visually distinguished by their color-coded backs (Target: Cyan/Green, Threat: Red/Crimson, Combat: Blue).
- **Drawing**: Cards are drawn from the top of the face-down stack as required by the cycle steps.

### 2.3. Card Data Source

> [!CAUTION]
> **Architectural constraint** — must be enforced in all game engine code.

- All card instructions and game effects are **read from the database at the time the card is drawn**.
- Cards must **never be hard-coded** in game logic. The DB is the **sole source of truth** for card behaviour.

### 2.1. The Game Play

- The game consists of **turns**
- One turn = drone starts at **B0**, traverses all boxes up to **B5**, then returns to B0
- The "Drone Manager™" procedure simulates the "find, fix, finish" process
- Two modes: **Solitaire** and **2+ Player** (competitive)

### 2.2. Game Components

| Component | Description |
|-----------|-------------|
| Rule Book | Base rules; scenario/card special rules may override these |
| Game Board | Main page with gameplay steps and tracking tables |
| Campaign Map | A4 pages divided into zones for campaign missions |
| Target Cards | Info about targets to hunt — includes VP values |
| Threat Cards | Info about threats trying to shoot you down — may include DRM modifiers |
| Loadout Markers | Record loadout carried on drone; removed as used |
| Drone Marker | Records drone position on game board |
| Drone Info Cards | Documentation on drone types with status tracking |
| Combat Cards | Add battlefield randomness; events/conditions take precedence over normal rules |

### 2.3. Target Cards

- Feature information for targets the player hunts
- Each has a **VP Value** — added to score when target is destroyed
- May display additional DRM to add to Combat Attack procedure

### 2.4. Threat Cards

- Feature information about threats trying to shoot the drone down
- May display additional DRM for Counter Fire and Evasion procedure

### 2.5. Loadout Markers

Once loadout is decided, corresponding markers are placed on the Drone Info Card's Loadout section. Removed as used.

**Loadout restrictions by drone class:**

| Marker | Meaning |
|--------|---------|
| `(*A)` | Only usable on A-class Drones |
| `(*B)` | Only usable on B-class Drones or bigger |
| `(*C)` | Only usable on C-class Drones or bigger |
| `(*D)` | Only usable on D-class Drones or bigger |
| `(%)` | If carried, no other weapon OR KIT loadout can be carried |
| `(+)` | If carried, add +2 Fuel extra to normal fuel usage in game cycle |

### 2.6. Drone Info Cards

Show the status of vital parts and drone characteristics. Include:

#### 2.6.1. Drone Altitude Box

Shows current height. Some drones cannot operate above certain altitudes (if no Medium or High setting, it can't fly there).

#### 2.6.2. Drone Class

| Class | Description |
|-------|-------------|
| **A** | Heavy/Large (MQ Reaper, Ochotnik, Euro Drone) |
| **B** | Medium (TB2, Wing Loong Series) |
| **C** | Small, generally for FO/Lazing missions |
| **D** | Micro, limited range and horsepower |

#### 2.6.3. Drone System Health Box

Tracking table for:

| Indicator | Start Value | Description |
|-----------|-------------|-------------|
| **INTEGRITY DAMAGE** | 0 | Structural integrity; losing it may cause additional component damage and increase VIS |
| **SENSORS DAMAGE** | 0 | Damage to sensors → mission kill if drone can't locate/attack targets |
| **VIS/RCS** | 0 | Visibility to enemy (Radar/IR/eyeball); higher = easier target |
| **ONBOARD FUEL** | Drone's fuel rating | Fuel carried |
| **COMMS** | 0 | Command link from ground station; if lost, drone is lost. Max damage: 5 |

### 2.7. Combat Cards

- Add randomness to gameplay
- Some have events/conditions that take precedence over normal rules
- "No Event" cards = discard without action
- If all used up → reshuffle and place back face-up

---

## 3. Game Terms & Abbreviations

| Term | Meaning |
|------|---------|
| **CRT** | Combat Resolution Table |
| **DR** | Dice Roll (1D6 = single roll of six-sided die). DR cannot exceed 6 or be less than 1 |
| **DRM** | Dice Roll Modified — final roll after modifiers. Can exceed 10 or go below 1 |
| **D10** | Ten-sided die (used in Target Acquisition and Threat Determination) |
| **Discarded Pile** | Revealed cards kept here; destroyed Target Cards go to separate pile |
| **Destroyed Target Pile** | Cards for targets successfully destroyed |

---

## 4. Game Setup

### 4.1. Setting Up the Game

1. Lay the gameboard on the table
2. Place the Drone Icon on **B0 Box**
3. Set Fuel, Sensor, Visibility, and Integrity markers to values from Drone Info Card
4. Select loadout using Drone Info Card; place markers on card
   - Some ammo can't be used for all attack types
   - Some weapons can't attack certain target types
   - Consult weapon counter for options
5. Place Threat, Target, and Combat Cards in their respective card holding boxes, **backside up** (face-down).
6. [OPTIONAL] Campaign: place Base counter on first base territory zone
7. Ready to take off

### 4.2. First Turn Rules

- Place drone marker on **B0 Box**
- Some scenarios may have different starting locations/rules — consult scenario content

---

## 5. Game Play Modes

### 5.1. Solitaire Quick Game

**Rules:**
- No fuel → drone falls, you lose
- No munitions → can't make Standoff or Close-in attacks, but can still FO/Laze
- No Lazing/Camera kit → can't execute FO/Lazing missions
- Run out of fuel during target search or threat determination → return to base, mission ends
- All target cards expanded → game ends, drone returns to base

**Movement:** Always counterclockwise on gameboard, one step at a time, never skip or go back.

**End of game:** Sum VP from destroyed target cards, subtract VP value of your drone = final score.

### 5.2. 2+ Player Mode

Competitive mode using same solitaire rules, same decks for all players.

**Winner decided by:**
1. First player to reach mission objectives wins
2. If both lose drones before goals, higher VP total wins

### 5.3. Scenario Games

1-player games with strict orders and mission goals. May use own Target/Threat probability ranges.

### 5.4. Campaign Game

Strategic mode with zone-based territory control:
- Start at Zone 1 (home base)
- Can only conduct missions in adjacent zones
- Eliminate all targets in a zone → it becomes your territory
- Campaign objectives in campaign document (usually: take territory or eliminate specific target)
- May have limited drones with possible reinforcements
- May have different probability ranges for Target/Threat types

---

## 6. Playing the Game

### 6.1. Play Sequence

The game loops through **B0 → B5** until:
- a) All target cards expanded
- b) Run out of fuel → return to base
- c) Shot down

### 6.2. Basic Rules

Movement from box to box is governed by Movement Rules. Combat (target determination, attack, evasion) is governed by Combat Rules.

### 6.3. Movement Rules

Movement is always **1 box-step**. Cannot skip or go back unless specifically instructed.

#### 6.3.1. B0 — "In Transit"

**If starting the game:**
1. Place drone on B0
2. Set height to MEDIUM (default starting height for all scenarios)
3. Select loadout, place weapon markers on Drone Info Card
4. Place all combat/threat/target cards on game board face down

**If returning from B5:**
1. If COMMS Damage > 2: take a DR check for Drone Controllability (see Taking Damage section)

#### 6.3.2. B1 — "Search / In Transit to Target Area"

| Action Type | Description |
|------------|-------------|
| **OPTIONAL** | Change altitude — costs 1F (fuel) per altitude change |

- No card draws at B1
- After completing actions → move to B2

#### 6.3.3. B2 — "Target Acquisition / Threat Determination"

> [!IMPORTANT]
> Designer clarification: **Both Target Card AND Threat Card are drawn at B2** together.

| Action Type | Description |
|------------|-------------|
| **REQUIRED** | Spend 1F (fuel) |
| **REQUIRED** | Draw a **Target Card** — the enemy asset to engage |
| **REQUIRED** | Draw a **Threat Card** — the danger the drone faces |
| **REQUIRED** | Target Detection: Roll 2D10, apply DRM, consult Target Acquisition Table |
| **REQUIRED** | Threat Determination: Roll 2D10, apply DRM, consult Threat Determination Table |

##### Target Determination — Detailed Flow

| Attribute | Specification |
|-----------|--------------|
| **Trigger** | Immediately after Target Detection roll is resolved |
| **Action** | Draw one card from the Target Card deck |
| **Display** | The drawn target card is displayed on screen to the player |
| **Effect** | Card context is read from DB and applied to the current game state |
| **Kill Resolution** | A DICE ROLL using the existing hit probability algorithm determines if the target is killed. Both the roll result AND outcome are displayed (e.g. `Roll: 14 — Hit!`) |
| **On Kill — VP** | The VP value of the target (from DB) is added to the player's scenario VP **immediately**. This VP is permanently banked and is **NOT reversed** if the drone is destroyed later in the same cycle |
| **On Kill — Kill List** | The target card name is appended to the player's kill list |
| **On Miss** | No VP awarded. Kill list unchanged. Scenario continues to Step 3 (Threat resolution) |

##### Objectives Tracking

After **every** Step 2 kill resolution, the system must check the player's progress against scenario objectives:

| Objective Type | Rules |
|----------------|-------|
| **Primary** | Required number and type of specific target cards killed. Must be achieved to unlock the next scenario in a Campaign. Status checked after **each** kill. |
| **Secondary** | Optional additional kills for bonus VP. VP from secondary objectives is **ONLY** counted in the final campaign score if the primary objective was also achieved. During play, secondary VP is banked normally; **filtering occurs at post-scenario scoring time**. |

##### Primary Objective Completion Prompt

Immediately after the kill that completes the primary objective, and **before proceeding to Step 3** (Threat), the game must display a prompt:

- **Option A: RTB** — end the scenario now and display post-scenario briefing
- **Option B: Continue** — proceed to Step 3 (Threat Card) to attempt additional kills

> [!NOTE]
> This prompt is shown **once** per primary objective completion event. If the player continues, it does **not** re-appear in subsequent cycles. RTB remains available to the player at all times as a free action.

> **🎯 DRONE COMMANDER'S DECISION:**
> If the target is NOT worth the risk of facing the threat:
> - Discard both cards to Discarded Pile
> - Go back to **B1**
>
> If you want to continue → go to **B3**

#### 6.3.4. B3 — "Positioning"

> [!IMPORTANT]
> Designer clarification: B3 is positioning only. Altitude change is optional.

| Action Type | Description |
|------------|-------------|
| **OPTIONAL** | Change altitude — free action |

After completing actions → move to B4

#### 6.3.5. B4 — "Drone Attack"

> [!IMPORTANT]
> Designer clarification: Player selects **altitude, attack mode, and weapon** at B4 before rolling.

| Action Type | Description |
|------------|-------------|
| **REQUIRED** | Select attack altitude (VLOW/LOW/MEDIUM/HIGH) |
| **REQUIRED** | Select attack mode (Stand-Off / Close-In / FO/Laze) |
| **REQUIRED** | Select weapon from loadout |
| **REQUIRED** | Roll 1D6, add all DRM modifiers |
| **REQUIRED** | Consult ATTACK CRT TABLE for result — determine if target is hit |
| **REQUIRED** | Apply results (VP banked immediately if hit) |

After completing actions → move to B5.

#### 6.3.6. B5 — "Evasive Action"

> [!IMPORTANT]
> Designer clarification: Player attempts to evade the Threat Card drawn at B2. Result determines whether damage is inflicted.

| Action Type | Description |
|------------|-------------|
| **REQUIRED** | Roll 1D6, add all DRM modifiers |
| **REQUIRED** | Consult EVASION CRT TABLE for result |
| **REQUIRED** | Apply results — damage inflicted if evasion fails |

##### Threat Determination — Detailed Flow

| Attribute | Specification |
|-----------|--------------|
| **Trigger** | Immediately after Step 2 is resolved (unless player chose RTB at the Step 2 prompt) |
| **Action** | Draw one card from the Threat Card deck |
| **Display** | The drawn threat card is displayed on screen to the player |
| **Effect** | Threat card context is read from DB and applied to the game flow |
| **Damage Resolution** | If the threat card result produces damage: evasion roll using the existing evasion algorithm. If damage lands: apply to drone HP using **active damage multiplier (combat card modifier × height modifier)** |
| **Drone Destroyed** | If drone HP reaches 0 or below: **SCENARIO ENDS IMMEDIATELY**. All previously banked VP is retained |
| **Drone Survives** | Proceed to the End-of-loop check |

> **🎯 DRONE COMMANDER'S DECISION:**
> If drone survives:
> - a) Continue mission → move to **B0** (requires fuel)
> - b) **RTB** → end scenario, trigger Post-Scenario Briefing

#### 6.3.7. End-of-Loop Check

After threat evasion is resolved and the drone has not been destroyed, the following checks are performed in **strict order**:

| # | Check | Result |
|---|-------|--------|
| 1 | Drone destroyed? | **YES**: End scenario immediately. Display post-scenario briefing. |
| 2 | Fuel exhausted? | **YES**: End scenario (forced RTB due to fuel). Display post-scenario briefing. |
| 3 | Player initiated RTB? | **YES**: End scenario. Display post-scenario briefing. |
| 4 | All checks passed | Apply fuel depletion for this cycle. **Clear combat card modifier.** Increment cycle counter. Return to Step 1 (B0). |

> [!WARNING]
> **OB3-SeniorDev must verify:**
> - Fuel exhaustion triggers the **same post-scenario briefing path** as destruction or voluntary RTB
> - Cycle counter increments correctly and is **persisted in game state**

### 6.3.8. Drone Height Mechanic

#### 6.3.8.1. Height Levels

The drone operates at one of four altitude levels. The **starting height for every scenario is MEDIUM**.

| Level | Notes |
|-------|-------|
| **VERY LOW** | Lowest altitude. Highest damage received risk. Modifies fuel consumption and evasion probability. |
| **LOW** | Below standard operating altitude. |
| **MEDIUM** | Default starting height for all scenarios. |
| **HIGH** | Maximum altitude. |

#### 6.3.8.2. What Can Change Height

- **Player voluntary action** — a **free action** executable at any point during the scenario (not locked to a specific step)
- **Combat Card** — may force a height change as defined in the card's DB entry
- **Threat Card** — may force a height change as defined in the card's DB entry
- **Target Card** — may force a height change as defined in the card's DB entry

When a card forces a height change, the new height takes effect **at the moment the card effect is applied** and immediately affects all four height-dependent mechanics.

#### 6.3.8.3. Mechanics Affected by Height

| Mechanic | Effect |
|----------|--------|
| **Hit Probability** | Height modifies the probability of the drone's outgoing attack hitting a target |
| **Evasion Probability** | Height modifies the drone's ability to evade incoming threats |
| **Damage Multiplier** | Height affects the damage received when a threat hits the drone |
| **Fuel Consumption Rate** | Height affects the fuel burned per cycle |

Specific modifier values for each height level are to be defined by the game designer and stored in the DB or a configuration table.

> [!WARNING]
> **OB3-SeniorDev must verify:**
> - All four height-dependent mechanics update **simultaneously** when height changes
> - Height modifiers **stack correctly** with active combat card modifiers on the same mechanics

---

### 6.4. Combat Rules

#### 6.4.1. Loadout Selection

- Each Drone Info Card defines available weapon/kit options
- Choose from loadouts available in the scenario
- Loadout attack mode restrictions:

| Icon | Mode |
|------|------|
| Close-in icon | Close-in attacks only |
| Stand-off icon | Stand-off attacks only |
| Anti-Aircraft icon | Anti-Aircraft only (vs Air Targets) |

**Loadout types:**

| Type | Used For |
|------|----------|
| **Armor Piercing/ATGW** | AFV, Tanks, trucks, tracked/wheeled vehicles |
| **Thermobaric Warheads** | Personnel, trucks, AFV, soft-skinned vehicles (penalties vs heavier armor) |
| **AA Warfare** | Air targets only |
| **Anti-Personnel** | Personnel targets only |
| **Bunker Buster** | HQ/Bunkers |
| **Multi-Purpose** | All target types |
| **Anti-Shipping** | Naval targets only |
| **KIT** | Special missions (sonobuoy, etc.) — see scenario instructions |

**Campaign rules:** New loadout types may be introduced; landing on base allows re-arming.

#### 6.4.2. Target Acquisition & Threat Determination

Both done in **B2**. Order doesn't matter but both must complete before leaving B2.

##### 6.4.2.1. Target Acquisition

**Procedure:**
1. Roll **2D10** (first = ones digit, second = tens digit)
   - Example: Roll 2 and 0 → "02"; Roll 2 and 5 → "25"; Roll 0 and 9 → "90"
2. Apply DRM modifiers
3. Match final DRM to Target Acquisition Table
4. Draw top card from matching Target Type deck

**DRM Modifiers:**
- +10 for Drone AEASA Radar
- +10 for "0" damage to Comms
- -10 from DRM for every 1 point of COMMS damage

**TARGET ACQUISITION TABLE** *(may change per scenario/campaign)*

| Range | Target Type |
|-------|-------------|
| ≤18 | TRUCK |
| 19–35 | PERSONNEL |
| 35–45 | AFV |
| 46–55 | SAM |
| 56–70 | TANK |
| 71–79 | ARTILLERY |
| 80–91 | HQ/BUNKER |
| 91–99 | VIP |
| ≥100 | AERIAL TARGET |

**If no matching target type available:** Look for next **lower** range type first. If none, pick next **higher** range type.

##### 6.4.2.2. Threat Determination

**Procedure:**
1. Roll **2D10**, add modifiers for final DRM
2. Match to Threat Determination Table
3. Draw top card from matching Threat Type deck

**DRM Modifiers:**
- +10 for each 2 points of VIS

**THREAT DETERMINATION TABLE** *(may change per scenario/campaign)*

| Range | Threat Type |
|-------|-------------|
| ≤19 | Small Arms |
| 20–65 | AAA |
| 66–85 | SAM |
| 86–95 | CAP |
| ≥96 | Anti-Drone Weapon |

**If no matching threat type available:** Same fallback as target acquisition (lower first, then higher).

**If all threat cards used up** but target cards remain and primary mission not accomplished: return used threat cards, reshuffle, put back into play.

#### 6.4.3. Drone Attack Rules (B4)

**Procedure:**

1. **Select Attack Mode:**

| Mode | Description |
|------|-------------|
| **Stand-Off** | Stay away from target; least chance of hit but best evasion chance |
| **Close-In** | Move to close range; better hit chance but harder to evade counterfire |
| **FO/Lazing** | Act as Forward Observer for heavy fire group (bomber, artillery battery) |

   **Weapon mode restrictions:**
   - AA missiles → Stand-Off / Medium–High only
   - Torpedoes & Sonobuoys → Close-In only
   - Anti-Shipping missiles → Stand-Off only

2. **Select weapon** — consult weapon counter for compatibility

3. **Select attack altitude** — High, Medium, or Low
   - AA missiles → Medium or High only
   - Mark altitude on Drone Info Card

4. **Roll 1D6**, add DRM from: Loadout counter, Combat Cards, Drone Info Card, Target card, scenario details → **find final DRM**

5. **Consult DRONE ATTACK TABLE** — find intersection of DRM column + altitude row

6. **Apply column shifts** (e.g., "Shift 1 RIGHT for each 2 Pts of Sensor Damage")

7. **Result:** If cell shows "HIT" → target destroyed → move Target Card to Destroyed pile. Otherwise → move to Discarded pile.

8. **Fuel/ammo:** Reduce fuel by amount in cell; remove used weapon

**DRONE ATTACK TABLE (CRT — Rev 3)**

Roll 1D6 + DRM modifiers. Find the intersecting cell. ❖ HIT = target destroyed. Fuel shown is always expended regardless of result.

|  | Stand-Off (1F base) |||||| Close-In (2F base) |||||| FO/Laze (3F base) ||||||
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| **ALT / DRM** | **1** | **2** | **3** | **4** | **5** | **6** | **1** | **2** | **3** | **4** | **5** | **6** | **1** | **2** | **3** | **4** | **5** | **6** |
| **VERY LOW** | N/A | N/A | N/A | N/A | N/A | N/A | 2F | 2F ❖ | 2F ❖ | 2F ❖ | 2F ❖ | 2F ❖ | 3F | 3F | 3F ❖ | 3F ❖ | 3F ❖ | 3F ❖ |
| **LOW** | 1F | 1F | 1F | 1F | 1F | 1F | 2F ❖ | 2F ❖ | 2F ❖ | 2F | 2F | 2F | 3F | 3F | 3F | 3F | 3F | 3F ❖ |
| **MEDIUM** | 1F | 1F | 1F | 1F | 1F | 1F ❖ | 2F | 2F | 2F | 2F | 2F ❖ | 2F ❖ | 3F ❖ | 3F ❖ | 3F ❖ | 3F ❖ | 3F | 3F |
| **HIGH** | 1F | 1F | 1F | 1F | 1F ❖ | 1F ❖ | 2F | 2F | 2F | 2F ❖ | 2F ❖ | 2F ❖ | 3F | 3F | 3F | 3F ❖ | 3F ❖ | 3F ❖ |

**Hit Probability Summary**

| Altitude | Mode | HIT % | Min DRM to HIT | Hits / 6 |
|----------|------|-------|-----------------|----------|
| VERY LOW | Stand-Off | N/A | N/A | N/A |
| VERY LOW | Close-In | 83.3% | DRM 2 | 5 / 6 |
| VERY LOW | FO/Laze | 66.7% | DRM 3 | 4 / 6 |
| LOW | Stand-Off | 0% | NO HIT | 0 / 6 |
| LOW | Close-In | 50% | DRM 1 | 3 / 6 |
| LOW | FO/Laze | 16.7% | DRM 6 | 1 / 6 |
| MEDIUM | Stand-Off | 16.7% | DRM 6 | 1 / 6 |
| MEDIUM | Close-In | 33.3% | DRM 5 | 2 / 6 |
| MEDIUM | FO/Laze | 66.7% | DRM 3 | 4 / 6 |
| HIGH | Stand-Off | 33.3% | DRM 5 | 2 / 6 |
| HIGH | Close-In | 16.7% | DRM 6 | 1 / 6 |
| HIGH | FO/Laze | 50% | DRM 4 | 3 / 6 |

> **Notes:**
> 1. Stand-Off mode is **NOT available** at Very Low altitude.
> 2. Shift 1 column **RIGHT** for each 2 points of Sensor Damage.
> 3. Drone expends fuel shown in the final crossed cell — **regardless of HIT or MISS**.
> 4. **Weapon restrictions:** AA missiles → Stand-Off / Medium–High only. Torpedoes & Sonobuoys → Close-In only. Anti-Shipping → Stand-Off only.

##### 6.4.3.1. [OPTIONAL] Attacking SAM Type Targets

Applies to SAM targets (NOT AAA or MANPAD).

If attack misses (SAM not destroyed), the SAM gets a **reaction shot**:

**Procedure:**
1. Roll 1D6
2. Add VIS value as DRM
3. If final DRM ≥ 6 → SAM fires reaction shot
4. Consult SAM Special Counterfire Table

This becomes a **second** counterfire check (in addition to original threat). Player must survive **both**.

**SAM TARGET UNIT SPECIAL COUNTERFIRE TABLE**

|  | Stand-Off |||||| Close-In |||||| FO/Laze ||||||
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| **ALT / DRM** | **1** | **2** | **3** | **4** | **5** | **6** | **1** | **2** | **3** | **4** | **5** | **6** | **1** | **2** | **3** | **4** | **5** | **6** |
| **LOW** | — | — | — | — | — | — | — | — | — | — | — | — | — | — | — | — | — | — |
| **MEDIUM** | — | — | — | — | — | — | — | — | — | — | — | 1D+1F | — | — | — | — | 1D+1F | 1D+1F |
| **HIGH** | — | — | — | — | — | 1D+2F | — | — | — | — | 1D+1F | 1D+1F | — | — | — | — | 1D+1F | 1D+1F |

> **Notes:**
> - (1) Shift 1 LEFT for each 2 Pts of VISIBILITY
> - (2) Drone sustains damage + uses fuel indicated

#### 6.4.4. Counterfire & Evasive Action Rules (B5)

**Procedure:**
1. Roll **1D6** (if using SAM optional rule, reuse that D6 roll)
2. Add DRM from: Loadout counter, Combat Cards, Drone Info Card, Threat card, scenario details
3. Find final DRM
4. Consult COUNTERFIRE & EVASIVE ACTION TABLE (DRM column × altitude row)
5. Apply column shifts
6. If cell shows Damage (D) → register damage to Drone Info Card
   - If damage exceeds total DP → drone shot down
7. Reduce fuel by amount in cell
8. Remove Threat Card to Discarded pile

**COUNTERFIRE & EVASIVE ACTION TABLE (Rev 1 — VLOW ADDED)**

Roll 1D6 + DRM modifiers. Damage notation: `XD+YF` = X damage points + Y fuel expended.

|  | Stand-Off |||||| Close-In |||||| FO/Laze ||||||
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| **ALT / DRM** | **1** | **2** | **3** | **4** | **5** | **6** | **1** | **2** | **3** | **4** | **5** | **6** | **1** | **2** | **3** | **4** | **5** | **6** |
| **VERY LOW** | N/A | N/A | N/A | N/A | N/A | N/A | — | — | — | 3D+2F | 3D+2F | — | — | — | — | — | — | 1D+1F |
| **LOW** | — | — | — | — | — | — | — | — | — | 2D+F | — | — | — | — | — | — | — | 1D+1F |
| **MEDIUM** | — | — | — | — | 1D+1F | — | — | — | — | 1D+1F | 1D+1F | 2D+F | 1D+1F | 1D+1F | 1D+1F | 1D+1F | 1D+1F | 1D+1F |
| **HIGH** | — | — | — | — | 1D+2F | 1D+2F | — | — | — | 1D+1F | 1D+1F | 1D+1F | — | — | — | 1D+1F | 1D+1F | 1D+1F |

> **Notes:**
> 1. Stand-Off is **NOT available** at Very Low altitude.
> 2. Shift 1 **LEFT** for each 2 Pts of VIS/RCS.
> 3. Drone sustains the damage indicated AND expends the fuel shown in the crossed cell.

**COUNTERFIRE PROCEDURE SUMMARY:**
1. Roll 1D6 (reuse the D6 result from the SAM attack step if applicable).
2. Add all applicable DRM modifiers: Loadout counter, Combat Cards, Drone Info Card, Threat Info Card, scenario rules.
3. Find the Final DRM column under the relevant Attack Mode. Apply any column shifts from loadout, cards or scenario rules.
4. Intersect with the current Altitude row. If the cell shows a damage value, register that damage on the Drone Info Card. If total Damage Points exceed the Drone's DP value, the drone is shot down.
5. Expend the fuel shown in the crossed cell plus the load used in the attack (Torpedoes, Gun rounds, etc.).
6. Remove the Threat Card from the Current Threat Box to the Discard Pile.

#### 6.4.5. Taking Damage

Damage affects drone subcomponents cascadingly:

##### 6.4.5.1. Structural Integrity Damage

- Every 1D damage → registered to "Structural Integrity" column on Drone Info Card
- If damage ≥ drone's structural integrity value → drone destroyed

##### 6.4.5.2. Sensors Damage

- For every **2 points** of Structural Integrity damage → raise Sensors Damage by 1
- **Maximum:** 9 (regardless of structural damage)
- For every **4 points** of Sensor Damage → -1 to Drone Attack Combat Roll
- Optional Sensor Kits do NOT take damage (external, not part of body)
- **Optional Sensor Kits are loaded as loadout items** — they occupy loadout slots on the drone, just like weapons

##### 6.4.5.3. COMMS Damage

- For every **3 points** of Structural Integrity damage → raise COMMS Damage by 1
- Effects are per-turn unless drone becomes uncontrollable (game ends)
- If COMMS Damage > 2: take COMMS check at B0 each turn

**COMMS CHECK TABLE**

| DRM / Order | Result |
|-------------|--------|
| ≤2 | All OK — continue mission |
| 3, 4, 5 | Controllable but with difficulty: **-1 to Drone Attack Dice Roll** |
| ≥6 | **Drone uncontrollable — assumed destroyed. GAME ENDS.** |

**COMMS Check DRM Modifiers:**
- -1 if Drone has SATCOM
- -1 if Drone has Comms Sys Redundancy
- -1 if Drone has "Autonomous DM AI"
- (all cumulative)

##### 6.4.5.4. VIS/RCS Increase from Damage

- For every **1 damage** on COMMS **or** 1 damage on SENSORS → raise VIS by 1

---

### 6.5. Fuel / Endurance Mechanic

> [!IMPORTANT]
> **Fuel IS Endurance.** Wherever "fuel" appears in rules, it means endurance. On the app screen it is displayed as **"FUEL"**.

| Attribute | Specification |
|-----------|--------------|
| **Initial Value** | Full — value defined by scenario designer in DB (endurance_hours column) |
| **Fuel Unit** | **1F = 1D** (1 fuel unit = 1 damage-point equivalent of endurance) |
| **Depletion Method** | Base rate per cycle (fixed, designer-defined) **PLUS** modifiers from active height level **AND** active combat card effect |
| **Depletion Timing** | Applied at the **end of each cycle** (End-of-Cycle Check step 4) — **not mid-step** |
| **Score Impact** | **None.** Remaining fuel on RTB or scenario end has NO effect on VP or campaign score |
| **Exhaustion Result** | Scenario ends. Post-scenario briefing is displayed. Same code path as voluntary RTB |

#### 6.5.1. Fuel Display — Color Bar

The fuel gauge is a **color-coded bar** (no numeric value shown to player):

| Fuel Remaining | Color | Hex Suggestion |
|:--------------:|:-----:|:--------------:|
| 75% – 100% | 🟢 **Green** | `#22C55E` |
| 40% – 75% | 🔵 **Blue** | `#3B82F6` |
| 10% – 40% | 🟠 **Orange** | `#F97316` |
| 0% – 10% | 🔴 **Red** | `#EF4444` |

---

### 6.6. Post-Scenario Briefing Screen

> [!IMPORTANT]
> **Mandatory** — must be displayed every time the scenario ends, regardless of the termination reason. No code path should skip it.

| Section | Content |
|---------|---------|
| **Termination Reason** | Why the scenario ended: `Drone Destroyed` / `Fuel Exhausted` / `RTB` |
| **Objectives Checklist** | All primary and secondary objectives listed with **ACHIEVED** or **FAILED** status for each |
| **Kill List** | Full ordered list of target card names confirmed killed during the scenario |
| **VP Breakdown** | VP awarded per kill. Secondary objective VP is flagged separately and shown as **zero campaign value** if primary was not achieved |
| **Total Scenario VP** | Sum of all eligible VP. **Secondary VP excluded from total if primary objective was not met** |
| **Campaign Advancement** | If part of a campaign: **ADVANCE** (primary achieved) or **LOCKED** (primary not achieved). Not shown for standalone scenarios |

> [!WARNING]
> **OB3-SeniorDev must verify:**
> - The briefing screen always appears after **every** termination condition — no code path should skip it
> - Secondary VP is displayed but **correctly excluded from score totals** when primary is not met

---

## 7. Scoring

### Maximum Kill Method
Game ends when target card deck is fully expanded. Sum VP from Destroyed Target Card pile = final score.

### Quick Kill Method
Game ends immediately when main objective is finished (regardless of drone survival). Sum VP from Destroyed Target Card pile = final score.

---

## 8. Design Your Own Scenario

Guide for creating custom scenarios:

1. **Create the setting** — location, environmental parameters, other vectors
2. **Define the mission** — target type, attack mode required, other targets, available threats
3. **Build decks** — fill Target and Threat Card decks with appropriate cards
4. **Choose drone and loadouts**
5. **Play!**

---

## 9. Special Rules

### 9.1. 2P First Player

Players with less hair go first. Tie → player with beard goes last. Still tied → roll 1D6, higher roll goes LAST.

### 9.2. Campaign and Scenario Rules

Special rules in scenarios take precedence over base rules conditionally.

---

*Parsed from: Obscure Battles - V3 - DRONE COMMANDER V3.1-D10.pdf*
*Document version: V3.1-D10*

---

## ❓ Questions & Clarifications (Please Answer Below Each)

> [!IMPORTANT]
> These questions are blocking the functional spec. Please answer directly below each one.
> Following the "never assume" rule — I need your input before proceeding.

### Q1. Counterfire & Evasive Action Table — LOW / Stand-Off & Close-In ✅ RESOLVED

In the **Counterfire & Evasive Action Table**, the LOW altitude row was showing all empty cells for Stand-Off and Close-In.

**Your answer:** Corrected via Counterfire Table Rev 1. LOW row now has: Close-In DRM 4 = 2D+F. Stand-Off remains all dashes (no counterfire at LOW/Stand-Off). FO/Laze DRM 6 = 1D+1F. VLOW row also added.

> [!NOTE]
> **DILEK CLEARANCE ITEM #1**: ✅ RESOLVED — Counterfire table corrected with Rev 1 data.

---

### Q2. SAM Counterfire Table — LOW Row

Similarly, the **SAM Target Unit Special Counterfire Table** shows the entire LOW row as empty (dashes) across all three attack modes. Is this intentional — SAMs can't counterfire at LOW altitude?

**Your answer:** Some SAMs can hit at LOW altitude — this is probably wrong.

> [!CAUTION]
> **DILEK CLEARANCE ITEM #2**: SAM Counterfire table LOW row appears incorrect. Some SAMs should be able to hit at LOW altitude. Must be verified and corrected before final delivery.

---

### Q3. Drone Attack Table — LOW / Stand-Off ✅ RESOLVED

The LOW / Stand-Off results are all `1F` with **no HIT** anywhere (DRM 1–6). This means Stand-Off at LOW altitude can **never** hit a target. Is that correct by design?

**Your answer:** Yes, correct by design. **Confirmed by CRT Rev 3** — LOW/Stand-Off = 0% hit rate (0/6). The drone needs to carry an additional kit to make a hit at LOW/Stand-Off. Keep as-is.

---

### Q4. Campaign Mode — V1.0 or V1.1?

The rulebook describes Campaign Mode (zone-based territory, strategic movement, reinforcements). Should this be:
- **A)** Full v1.0 scope (develop it now)
- **B)** Defer to v1.1 (build the engine first, add campaigns later)

**Your answer:** **B) v1.1** — defer campaigns to later.

---

### Q5. 2+ Player Mode — V1.0 or V1.1?

Similarly, competitive 2+ Player mode — should this be:
- **A)** v1.0 scope
- **B)** Defer to v1.1

**Your answer:** No 2P version. Maybe later.

---

### Q6. "Design Your Own Scenario" — Is this the Scenario Editor?

Section 8 describes designing custom scenarios. Is this what you mean by the "scenario editor" in your v1.0 requirements? Or do you envision something more sophisticated (e.g., a visual editor with drag-and-drop zone creation)?

**Your answer:** Yes, but we need to recreate this from the start. The BA (OB3-ProjectManager) should prep a form to take inputs as a multiple choice survey.

> [!IMPORTANT]
> **BA ACTION ITEM**: OB3-ProjectManager must create a scenario editor input survey form for the user.

---

### Q7. Fuel — Starting Values & Consumption

The rulebook says fuel starts at the drone's "fuel rating value" but doesn't specify what those values are per drone. Are these in the database? I see the `drones` table doesn't have a `fuel` column. Where do starting fuel values come from?

**Your answer:** Fuel value is given by the endurance in hours for each drone. Use this value per drone.

> [!NOTE]
> The `drones` table currently has `range` (distance in km) but NO endurance/fuel column. An `endurance_hours` column needs to be added to the database for each drone.

> [!IMPORTANT]
> **UI DESIGN NOTE**: Fuel will NOT be shown as liters/numbers but as a **color bar that changes color as it declines** (green → yellow → red).

---

### Q8. VIS/RCS Starting Value

The rulebook says VIS/RCS starts at 0. Is this the same for all drones, or do some drones have inherent VIS values from the database?

**Your answer:** Each drone has different values but for the moment they all start at the same level.

---

### Q9. Altitude Levels

The rulebook mentions LOW, MEDIUM, HIGH altitudes. The drone table has an `altitude` column. Are there exactly 3 altitude levels, or can some drones access additional altitudes (e.g., VERY HIGH)?

**Your answer:** There are 4 altitude levels: **VLOW — LOW — MEDIUM — HIGH**

> [!NOTE]
> This is different from the rulebook which only describes 3 levels. The CRT tables and game mechanics will need to account for the additional VLOW altitude level.

---

### Q10. Turn Counter & Game Length

Is there a maximum number of turns, or does the game always end via fuel/ammo/destruction/target exhaustion?

**Your answer:** No maximum turn limit. The game always ends via scenario end conditions: drone destroyed, objectives completed, voluntary RTB, or fuel exhausted.

---

## 🚨 DILEK Pre-Delivery Clearance List

> [!CAUTION]
> These items MUST be resolved by DILEK (Orchestrator) before final delivery. This is CRITICAL.

| # | Issue | Source | Status |
|---|-------|--------|--------|
| 1 | **Counterfire table LOW row** — corrected with Rev 1 data (Close-In DRM 4 = 2D+F) | Q1 | ✅ RESOLVED |
| 2 | **SAM Counterfire table LOW row** — all cells empty, some SAMs should hit at LOW | Q2 | ⬜ OPEN |
| 3 | **VLOW altitude rows** — Attack CRT (Rev 3) + Counterfire (Rev 1) done. SAM table still needs VLOW. | Q9 | ⚠️ PARTIAL |
| 4 | **Endurance/fuel data** — `endurance_hours` added to `drones` table, all 28 updated | Q7 | ✅ RESOLVED |

---
