# Contributing to OB3 — Drone Commander Mobile

> How to contribute to the project, conventions to follow, and the agent workflow.

---

## The Critical Rule

> **ASK about anything that is not clear. NEVER ASSUME ANYTHING.**
> The rulebook at [`docs/game-rules/rulebook.md`](docs/game-rules/rulebook.md) is the **source of truth** for all game mechanics. If something is ambiguous, unclear, or contradictory — **stop and ask the user for clarification**.

This applies to every agent and every contributor.

---

## Agent Workflow

Development follows an 8-agent pipeline. Each agent has a specialized role:

```
Phase 1: OB3-ProjectManager
    → Reads rulebook + DB schema
    → Creates functional spec + task list
    → Quality gate: User review

Phase 2: OB3-UXArchitect + OB3-UIDesigner (parallel)
    → UX: Screen architecture, game flow, state machine
    → UI: Design system, component specs, mockups
    → Quality gate: User review

Phase 3: OB3-SeniorDev ↔ OB3-QA (loop per task)
    → Dev implements task
    → QA validates with evidence (screenshots, test logs)
    → If FAIL: loop back to dev (max 3 retries)
    → If PASS: next task
    → OB3-MobileBuilder for platform-specific tasks

Phase 4: Final Integration
    → OB3-QA: Full integration testing
    → OB3-TechWriter: Documentation
    → Quality gate: Production readiness
```

### Handoff Rules

1. **Always read the spec first.** Before starting work, read the functional spec, relevant rulebook sections, and any upstream deliverables.
2. **Quote the rulebook.** When implementing game mechanics, cite the exact rulebook section that defines the mechanic. Never add rules that are not in the rulebook.
3. **Deliver to the correct location.** See [Directory Conventions](#directory-conventions) below.
4. **Flag blockers immediately.** If you encounter an ambiguity or missing information, stop and ask — do not assume.

---

## Directory Conventions

| Directory | Purpose | Who Writes Here |
|-----------|---------|-----------------|
| `docs/game-rules/` | Parsed rulebook, game loop diagrams | OB3-ProjectManager |
| `docs/specs/` | Functional specs, design system, UX architecture, API docs | PM, UX, UI, TechWriter |
| `docs/discovery/` | Project brief, discovery Q&A | Orchestrator |
| `project-specs/` | Agent pipeline config, setup docs | Orchestrator |
| `project-tasks/` | Task lists per agent | PM, Orchestrator |
| `agents/` | Agent role definitions | Orchestrator |
| `assets/db/` | SQLite database | SeniorDev |
| `lib/` | Flutter source code | SeniorDev, MobileBuilder |

---

## File Naming Conventions

- Use **lowercase with underscores** for all files: `functional_spec.md`, `game_engine_api.md`
- Markdown files use `.md` extension
- Dart files follow Flutter/Dart naming conventions: `snake_case.dart`
- Keep filenames descriptive but concise

---

## Documentation Standards

### Markdown

- Use ATX-style headers (`#`, `##`, `###`)
- Use tables for structured data
- Use mermaid diagrams for flow visualisation
- Use GitHub-style alerts (`> [!NOTE]`, `> [!WARNING]`, `> [!IMPORTANT]`, `> [!CAUTION]`) for callouts
- Link to other documents using relative paths

### Code Documentation

- Every public class and function must have a doc comment
- Dart uses `///` for doc comments
- Include parameter descriptions and return types
- Reference the rulebook section that defines the game mechanic

### Example

```dart
/// Resolves a drone attack against the active target.
///
/// Implements the B4 — Drone Attack procedure from
/// [rulebook section 6.4.3](docs/game-rules/rulebook.md#643-drone-attack-rules-b4).
///
/// [mode] The attack mode: Stand-Off, Close-In, or FO/Laze.
/// [weapon] The weapon to use (must be compatible with target type).
/// [altitude] The attack altitude.
///
/// Returns an [AttackResult] with hit/miss, fuel cost, and weapon consumed.
///
/// Throws [IncompatibleWeaponError] if the weapon cannot target this type.
AttackResult resolveAttack({
  required AttackMode mode,
  required Weapon weapon,
  required Altitude altitude,
}) { ... }
```

---

## Commit Messages

Use conventional commit format:

```
type(scope): description

feat(combat): implement drone attack CRT lookup
fix(fuel): correct fuel consumption at B2 phase entry
docs(readme): add database schema section
test(damage): add cascade damage unit tests
```

| Type | Use For |
|------|---------|
| `feat` | New feature or game mechanic |
| `fix` | Bug fix |
| `docs` | Documentation only |
| `test` | Tests only |
| `refactor` | Code restructuring without behaviour change |
| `style` | Formatting, linting |

---

## Testing Requirements

- Every game mechanic must have unit tests
- QA agent validates with **screenshot evidence** — a feature without visual proof is not done
- Maximum 3 retry loops between Dev and QA per task
- All CRT table lookups must be tested with boundary values (DRM 1 and 6, all altitudes)

---

*Contributing guide version: 0.1.0*
*Last updated: 2026-03-10*
