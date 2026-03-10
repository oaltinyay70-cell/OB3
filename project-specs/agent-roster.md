# OB3 Agent Roster & Orchestration Plan

## Agent Roster

Each agent is a specialist operating under its skill instructions. The orchestrator coordinates handoffs.

---

### 1. 🎯 Orchestrator
- **Skill**: `agency-agents-orchestrator`
- **Name**: DILEK
- **Role**: Pipeline coordination, quality gates, agent handoffs
- **Inputs**: Project spec, task list
- **Outputs**: Status reports, completion summaries

---

### 2. 📋 Project Manager / Business Analyst
- **Skill**: `agency-senior-project-manager`
- **Name**: OB3-ProjectManager
- **Role**: Convert rulebook into functional spec, task breakdown, scope management
- **Inputs**: Rulebook (`docs/game-rules/rulebook.md`), database schema, project spec
- **Outputs**: `project-tasks/ob3-tasklist.md`, `docs/specs/functional-spec.md`
- **Key Rule**: Quote EXACT requirements from rulebook; add nothing not in the rules

---

### 3. 🏗️ UX Architect
- **Skill**: `agency-ux-architect`
- **Name**: OB3-UXArchitect
- **Role**: Game flow design, screen architecture, state machine, CSS/design foundation
- **Inputs**: Functional spec, rulebook
- **Outputs**: `docs/specs/ux-architecture.md`, screen flow diagrams, design tokens

---

### 4. 🎨 UI Designer
- **Skill**: `agency-ui-designer`
- **Name**: OB3-UIDesigner
- **Role**: Visual design system, component library, game UI mockups
- **Inputs**: UX architecture, brand preferences (MILSTD military theme from v1)
- **Outputs**: `docs/specs/design-system.md`, component specs, color/typography tokens

---

### 5. 💻 Senior Developer
- **Skill**: `agency-senior-developer`
- **Name**: OB3-SeniorDev
- **Role**: Core game engine, state management, business logic implementation
- **Inputs**: Functional spec, UX architecture, design system, database
- **Outputs**: Flutter source code in `lib/`

---

### 6. 📱 Mobile App Builder
- **Skill**: `agency-mobile-app-builder`
- **Name**: OB3-MobileBuilder
- **Role**: Platform-specific (iOS/Android), native integration, performance, deployment
- **Inputs**: Flutter project, platform requirements
- **Outputs**: Platform configs, build scripts, deployment prep

---

### 7. 🧪 Evidence Collector (QA)
- **Skill**: `agency-evidence-collector`
- **Name**: OB3-QA
- **Role**: Test every task, screenshot evidence, PASS/FAIL decisions
- **Inputs**: Implemented features, functional spec
- **Outputs**: Test reports with visual evidence, bug reports

---

### 8. ✍️ Technical Writer
- **Skill**: `agency-technical-writer`
- **Name**: OB3-TechWriter
- **Role**: README, architecture docs, API docs, inline documentation
- **Inputs**: All deliverables
- **Outputs**: Updated `README.md`, `ARCHITECTURE.md`, code documentation

---

## Pipeline Flow

```
Phase 1: OB3-ProjectManager
    → Reads rulebook + DB schema
    → Creates functional spec + task list
    → Quality gate: User review

Phase 2: OB3-UXArchitect + OB3-UIDesigner
    → UX: Screen architecture, game flow, state machine
    → UI: Design system, component specs, mockups
    → Quality gate: User review

Phase 3: [OB3-SeniorDev ↔ OB3-QA] Loop (per task)
    → Dev implements task
    → QA validates with evidence
    → If FAIL: loop back to dev (max 3 retries)
    → If PASS: next task
    → OB3-MobileBuilder for platform-specific tasks

Phase 4: Final Integration
    → OB3-QA: Full integration testing
    → OB3-TechWriter: Documentation
    → Quality gate: Production readiness
```

## How to Spawn an Agent

To activate an agent, read its SKILL.md and follow its instructions while assuming that agent's persona:

```
Agent: OB3-ProjectManager
Skill: /Users/ozgur/.gemini/antigravity/skills/agency-senior-project-manager/SKILL.md
Task: Read project-specs/ob3-setup.md and docs/game-rules/rulebook.md.
      Create functional spec at docs/specs/functional-spec.md
      Create task list at project-tasks/ob3-tasklist.md
```
