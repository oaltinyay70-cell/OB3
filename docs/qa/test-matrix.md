# OB3 — QA Test Matrix & Edge Cases

> **Agent**: OB3-QA (EvidenceQA)  
> **Date**: 2026-03-11  
> **Reference**: `docs/specs/ux-architecture.md` (Section 2.4 Transitions, Section 2.2 State Machine)

---

## 1. State Machine Transition Test Matrix (QA-1)

Every transition defined in the Game State Machine (Section 2.4) must be verifiable.

| Test ID | From State | To State | Trigger Condition | Expected Side Effects / Payload | Status |
|---------|-----------|----------|-------------------|---------------------------------|--------|
| `SM-01` | `B0` | `B1` | COMMS check passed (DRM ≤ 2) | No penalty applied. Transition to Search. | Pending |
| `SM-02` | `B0` | `B1` | COMMS check degraded (DRM 3-5) | `commsCheckPenalty` set to -1. Transition to Search. | Pending |
| `SM-03` | `B0` | `GAME_OVER` | COMMS check failed (DRM ≥ 6) | `gameEndReason = UNCONTROLLABLE`. Prompt destruction. | Pending |
| `SM-04` | `B1` | `B2` | Combat card resolved, Fuel > 0 | Fuel correctly deducted if Altitude changed (-1F). Target/Threat decks prepped. | Pending |
| `SM-05` | `B1` | `FORCED_RTB`| Fuel = 0 after combat card/alt change | `gameEndReason = NO_FUEL`. Prompt mission end. | Pending |
| `SM-06` | `B2` | `B1` | Commander Decision: "Retreat" | Target and Threat cards discarded. No VP gained. Return to Search. | Pending |
| `SM-07` | `B2` | `B3` | Commander Decision: "Engage" | Target and Threat cards locked for current cycle. Proceed to Positioning. | Pending |
| `SM-08` | `B2` | `TARGETS_EXHAUSTED`| No target cards left to draw | `gameEndReason = TARGETS_EXHAUSTED`. Game triggers scoring. | Pending |
| `SM-09` | `B3` | `B4` | Combat card resolved, Positioning done | Fuel deducted if Altitude changed (-1F). Proceed to Attack. | Pending |
| `SM-10` | `B4` | `B5` | Attack resolved (Hit/Miss) | Fuel cost applied (1F/2F/3F). Target moved to Destroyed/Discard. Weapon consumed. | Pending |
| `SM-11` | `B4` | `GAME_OVER` | SAM reaction destroys drone | `gameEndReason = DESTROYED`. Drone DP reached max. | Pending |
| `SM-12` | `B5` | `B0` | Commander Decision: "Continue" | Cycle count increments. Fuel/Damage applied to state. New loop begins. | Pending |
| `SM-13` | `B5` | `RTB` | Commander Decision: "Return to Base" | `gameEndReason = VOLUNTARY_RTB`. Proceed to Post-Scenario Briefing. | Pending |
| `SM-14` | `B5` | `GAME_OVER` | Evasion damage destroys drone (SI ≥ Max) | `gameEndReason = DESTROYED`. Proceed to Post-Scenario Briefing. | Pending |

---

## 2. Critical Edge Cases (QA-2)

The engine must accurately handle these compounding chains without crashing or bypassing rules.

### EC-1: `Fuel Exhaustion Mid-Cycle`
- **Scenario**: Fuel drops exactly to 0 during an altitude change in `B1` or `B3`.
- **Expected Behavior**: Game interrupts normal flow, forces `FORCED_RTB` transition immediately. The player cannot proceed to B2 or B4.

### EC-2: `Cascading COMMS Failure`
- **Scenario**: Drone receives Evasion damage in `B5` that pushes COMMS damage > 2. The player selects "Continue" to `B0`.
- **Expected Behavior**: The game forces a COMMS Check roll at the start of `B0`. If the roll fails (DRM ≥ 6), the drone is immediately destroyed before `B1` can begin.

### EC-3: `SAM Reaction Chain`
- **Scenario**: Player attacks a SAM target and *misses*. 
- **Expected Behavior**: Must trigger SAM Reaction sequence. Roll 1D6 + VIS. If ≥ 6, check SAM Special Counterfire Table. Any damage applies. If this destroys the drone, transition directly to `GAME_OVER` before `B5` (Evasion) can begin.

### EC-4: `Threat Deck Exhaustion`
- **Scenario**: In `B2`, the Threat Deck is empty, but Target Deck is not.
- **Expected Behavior**: According to rulebook B2, immediately reshuffle used Threat Cards back into play to draw a new threat. Target flow is not interrupted unless target deck itself is empty.

### EC-5: `Weapon Compatibility Lockout`
- **Scenario**: Player reaches `B4` with a Target type (e.g. PERSONNEL) but their loadout only has ATGM constraints that cannot target PERSONNEL.
- **Expected Behavior**: Target should be un-engageable. Player forced to skip attack or game automatically registers auto-miss (need design clarification if they forfeit fuel).

---

## 3. CRT Verification Data (QA-3)

Concrete inputs used by QA and Unit Tests to guarantee CRT (Combat Resolution Table) lookups are mathematically correct.

### Expected Outcomes for Known Inputs:

| Component | Input Params | Expected CRT Cell & Outcome |
|-----------|--------------|-----------------------------|
| **Drone Attack** | `STANDOFF`, `MEDIUM` Alt, Base Roll 4, +0 DRM (`net 4`) | Result: 1F, No Hit |
| **Drone Attack** | `STANDOFF`, `HIGH` Alt, Base Roll 5, +0 DRM (`net 5`) | Result: 1F, **HIT** |
| **Drone Attack** | `CLOSE_IN`, `LOW` Alt, Base Roll 6, +0 DRM (`net 6`) | Result: 2F, **HIT** |
| **Counterfire**  | `STANDOFF`, `HIGH` Alt, Threat Roll 5, VIS 0 (`net 5`) | Result: 1D + 2F |
| **Counterfire**  | `CLOSE_IN`, `MEDIUM` Alt, Threat Roll 6, VIS 2 (`net 5` shifted Left 1) | `net 5` → 1D + 1F |
| **SAM Reaction** | `STANDOFF`, `HIGH` Alt, Roll 6, VIS 0 (`net 6`) | Result: 1D + 2F |
| **SAM Reaction** | `FO_LAZE`, `MEDIUM` Alt, Roll 5, VIS 2 (`net 4` shifted Left 1) | `net 4` → Safe (No Damage) |
