# Agent Broadcast: 2026-03-11 (Evening Update)

**To:** All OB3 Agents (DILEK, ProjectManager, TechWriter, UIDesigner, SeniorDev)  
**From:** Orchestrator/Analyst  
**Subject:** Rulebook Gaps 100% Resolved & Spec Finalized 

The USER has provided the final answers to all open questions in the `rulebook_gaps.md` document. The core game specification is now officially **locked and complete** for the V1.0 engine.

## Critical Updates & Rulings 

1. **FO/Laze Mechanics & Drones (F1/F2/G4)**
   - FO/Laze Attack Mode requires an **FO/Laze Kit** loadout to be equipped.
   - **EXCEPTION:** 22 out of the 28 drones have built-in FO/Laze (e.g., TB2, Reaper, etc.). They do *not* need a kit.
   - 6 drones *strictly require* a kit (TB-001 Scorpion, Avenger, S-70 Okhotnik-B, Mohajer-6, Mohajer-10, Shahed-129).
   - Fuel cost is confirmed at 3F. 

2. **Altitude / Height Changes (H2)**
   - Re-confirmed: Altitude change is a free action during B-3 Positioning. Drones are not restricted to changing 1 level per turn; they can jump multiple levels (e.g., HIGH straight down to LOW).
   - **NEW RULE (FUEL COST):** *Lowering* altitude is free (0F). However, *raising* altitude costs **+1F per level raised** (e.g., jumping from LOW to HIGH costs +2F). This fuel burns immediately upon ascending. 

3. **Re-arming (H1)**
   - Drones **cannot** re-arm mid-scenario. Once weapons are expended, they are weapons-out. They can still FO/Laze if equipped, but otherwise must RTB.

4. **Combat Cards (C2)**
   - The user provided the full catalog of 18 Combat Cards (with names, flavor text, and modifiers). 
   - 11 cards provide DRM modifiers (ranging from -2 to +2).
   - 7 cards force positive or negative altitude changes. 
   - The deck also contains "NO EVENT" buffer cards.
   - All 19 cards have been inserted into the SQLite database.

5. **Scoring & Progression (E1/E2)**
   - VP values are attached directly to each individual Target Card.
   - VP accumulates on the player's profile persistently. Medals and Rank-ups are awarded at VP thresholds. 

6. **Drone Abilities (G1-G3)**
   - Typo corrected: It is "AESA" Radar, not AEASA. 
   - AESA (+10 Target Acq), SATCOM (-1 Comms DRM), and DM AI (-1 Comms DRM) have **no other hidden mechanical effects** beyond their stated DRM modifiers. 

## Action Items 

- **@OB3-TechWriter:** The `docs/game-rules/rulebook.md` has been updated with all the above. Please review section 6.3.8.2 for the new altitude fuel cost wording.
- **@OB3-SeniorDev:** 
  - Ensure the fuel logic engine deducts 1F for every level a drone ascends during B-3. 
  - The SQLite database `ob3.db` now contains all target, threat, and combat cards. 
- **@OB3-ProjectManager:** `task.md` has been updated. Phase 1 Analysis is effectively complete. We are ready to transition fully to Phase 2 (Project Setup / Scaffold) and Phase 3 (Core Implementation). 

**STATUS NOTE FOR DILEK:** 
The DILEK Pre-Delivery Clearance list has only **one** item remaining: 
- Item #2: SAM Counterfire table needs data for the LOW row (currently empty cells for Stand-off/Close-in). 

Once Item #2 is closed, the project has full clearance to begin Dart/Flutter coding.
