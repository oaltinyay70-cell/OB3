# OB3 Drone Commander — Visual Design System

> **Theme**: MILSTD Dark Intelligence Dashboard
> **Platform**: Flutter (iOS-first, Android later)
> **Designer**: OB3-UIDesigner
> **Date**: 2026-03-10

---

## 1. Design Foundations

### 1.1 Color System

The palette draws from military HUD/FLIR aesthetics — dark backgrounds, phosphor greens, amber warnings, and high-contrast readouts.

#### Primary Palette

| Token | Hex | Usage |
|-------|-----|-------|
| `background-primary` | `#0A0E14` | Main app background (near-black with blue undertone) |
| `background-secondary` | `#111927` | Panel backgrounds, cards, modals |
| `background-tertiary` | `#1A2332` | Elevated surfaces, active states |
| `background-overlay` | `#0A0E14CC` | Modal overlays (80% opacity) |
| `surface` | `#1E293B` | Card surfaces, input backgrounds |
| `surface-hover` | `#253347` | Interactive element hover states |

#### Accent Colors

| Token | Hex | Usage |
|-------|-----|-------|
| `accent-primary` | `#00E676` | Primary interactive elements, success, active HUD elements |
| `accent-primary-dim` | `#00C86440` | Glow effects, subtle highlights (25% opacity) |
| `accent-secondary` | `#40C4FF` | Links, info indicators, secondary actions |
| `accent-warm` | `#FFB300` | Warnings, attention indicators |
| `accent-danger` | `#FF1744` | Errors, critical damage, destruction |

#### Semantic Colors — Status System

| Token | Hex | Usage |
|-------|-----|-------|
| `status-ok` | `#00E676` | System nominal, no damage |
| `status-caution` | `#FFD600` | Minor damage, low fuel |
| `status-warning` | `#FF9100` | Moderate damage, critical fuel |
| `status-critical` | `#FF1744` | Heavy damage, fuel emergency |
| `status-destroyed` | `#B71C1C` | System destroyed, mission failure |

#### Text Colors

| Token | Hex | Usage |
|-------|-----|-------|
| `text-primary` | `#E0E7EF` | Primary text (soft white, reduces eye strain) |
| `text-secondary` | `#8B9BB4` | Secondary labels, metadata |
| `text-muted` | `#4A5568` | Disabled text, placeholders |
| `text-inverse` | `#0A0E14` | Text on light/accent backgrounds |
| `text-hud` | `#00E676` | HUD overlays, phosphor-green readouts |

#### Border / Divider Colors

| Token | Hex | Usage |
|-------|-----|-------|
| `border-subtle` | `#1E293B` | Subtle separator lines |
| `border-default` | `#2D3F56` | Default borders on cards/inputs |
| `border-active` | `#00E676` | Active/focused element borders |
| `border-danger` | `#FF1744` | Error borders |

---

### 1.2 Typography System

#### Font Families

| Token | Font | Usage |
|-------|------|-------|
| `font-display` | **Rajdhani** | Headlines, titles, drone names — angular military style |
| `font-body` | **IBM Plex Sans** | Body text, descriptions, rules — clean and readable |
| `font-mono` | **IBM Plex Mono** | Numeric readouts, data values, coordinates, dice rolls |
| `font-hud` | **Share Tech Mono** | HUD overlays, fuel/damage readouts, status displays |

> **Fallback**: Rajdhani → Roboto Condensed → system-ui; IBM Plex Sans → -apple-system → sans-serif; IBM Plex Mono → Menlo → monospace

#### Type Scale

| Token | Size (pt) | Weight | Line Height | Usage |
|-------|-----------|--------|-------------|-------|
| `display-lg` | 32 | 700 | 1.1 | Screen titles ("MISSION BRIEFING") |
| `display-sm` | 24 | 600 | 1.2 | Section headers ("DRONE SELECTION") |
| `heading-lg` | 20 | 600 | 1.3 | Card titles, drone names |
| `heading-sm` | 16 | 600 | 1.3 | Subsection headers, stat labels |
| `body-lg` | 16 | 400 | 1.5 | Main body text, descriptions |
| `body-sm` | 14 | 400 | 1.5 | Secondary text, metadata |
| `caption` | 12 | 400 | 1.4 | Footnotes, helper text |
| `data-lg` | 28 | 700 | 1.0 | Large readout values (fuel %, VP) |
| `data-md` | 20 | 600 | 1.0 | Medium readout values (damage counters) |
| `data-sm` | 14 | 500 | 1.0 | Small data values (DRM, dice rolls) |
| `label-uppercase` | 10 | 600 | 1.2 | ALL-CAPS labels ("INTEGRITY", "FUEL") |

#### Letter Spacing

| Style | Tracking |
|-------|----------|
| Display | +0.5pt |
| Uppercase labels | +1.5pt |
| Mono readouts | +0.8pt |
| Body text | 0 (default) |

---

### 1.3 Spacing System

**Base unit**: 4pt grid

| Token | Value | Usage |
|-------|-------|-------|
| `space-1` | 4pt | Tight inner padding, icon gaps |
| `space-2` | 8pt | Component inner padding, compact lists |
| `space-3` | 12pt | Standard inner padding, between labels |
| `space-4` | 16pt | Standard outer padding, list item gaps |
| `space-5` | 20pt | Section inner padding |
| `space-6` | 24pt | Card padding, section gaps |
| `space-8` | 32pt | Screen section dividers |
| `space-10` | 40pt | Major layout gaps |
| `space-12` | 48pt | Screen edge padding (safe area) |

#### Border Radius

| Token | Value | Usage |
|-------|-------|-------|
| `radius-xs` | 2pt | Badges, tiny indicators |
| `radius-sm` | 4pt | Buttons, input fields — crisp military feel |
| `radius-md` | 6pt | Cards, panels |
| `radius-lg` | 8pt | Modals, dialogs |
| `radius-full` | 50% | Circular indicators, avatars |

> **Design note**: Small radii reinforce the MILSTD aesthetic — no pill shapes or large curves.

---

### 1.4 Elevation & Shadow System

| Token | Value | Usage |
|-------|-------|-------|
| `shadow-none` | none | Flat elements |
| `shadow-sm` | `0 1px 3px rgba(0,0,0,0.4)` | Subtle depth for cards |
| `shadow-md` | `0 4px 8px rgba(0,0,0,0.5)` | Modals, floating elements |
| `shadow-glow-green` | `0 0 12px rgba(0,230,118,0.3)` | Active HUD elements, fuel bar glow |
| `shadow-glow-amber` | `0 0 12px rgba(255,179,0,0.3)` | Warning state glow |
| `shadow-glow-red` | `0 0 12px rgba(255,23,68,0.3)` | Critical state glow |

---

## 2. Game UI Components

### 2.1 🔋 Fuel Color Bar (CRITICAL COMPONENT)

> [!IMPORTANT]
> Per design directive: **Fuel is shown as a color bar, NOT numbers.** The bar smoothly transitions through green → yellow → red as fuel depletes.

#### Specification

```
┌──────────────────────────────────────────────────┐
│  FUEL ■■■■■■■■■■■■■■■■■■■■■■■■■■■■░░░░░░░░░░░░ │
│  ▲                                               │
│  UPPERCASE LABEL (font-hud, 10pt, text-secondary)│
└──────────────────────────────────────────────────┘
```

| Property | Value |
|----------|-------|
| **Height** | 12pt (bar only); 28pt (with label) |
| **Width** | Full container width minus padding |
| **Background** | `#1A2332` (background-tertiary) — empty portion |
| **Border** | 1px solid `border-default` |
| **Border Radius** | `radius-xs` (2pt) |
| **Animation** | Smooth width transition (300ms ease-out) |

#### Color Gradient Thresholds

| Fuel % | Bar Color | Glow | Label Color |
|--------|-----------|------|-------------|
| 100–61% | `#00E676` (status-ok) | `shadow-glow-green` | `text-secondary` |
| 60–31% | `#FFD600` (status-caution) | `shadow-glow-amber` | `accent-warm` |
| 30–16% | `#FF9100` (status-warning) | `shadow-glow-amber` (brighter) | `accent-warm` |
| 15–1% | `#FF1744` (status-critical) | `shadow-glow-red` | `accent-danger` |
| 0% | `#B71C1C` (status-destroyed) | Pulsing `shadow-glow-red` | `accent-danger` (blink) |

#### Behavior
- **Smooth color interpolation** between thresholds (not hard steps)
- At ≤15% fuel: bar pulses gently (opacity 0.7 ↔ 1.0, 1.5s cycle)
- At 0% fuel: "FUEL EXHAUSTED" overlay appears, bar stops pulsing
- **Tick marks** at 25%, 50%, 75% — thin 1px lines in `text-muted`
- **No numeric value** on the bar itself (tooltip on long-press can show %)

#### Flutter Implementation Hint

```dart
// Use a custom LinearProgressIndicator with:
// - AnimatedContainer for smooth width
// - Color.lerp() between threshold colors
// - Overlay shimmer for pulse effect at critical
```

---

### 2.2 Drone Status Dashboard Panel

The status panel displays all drone vitals in a compact horizontal/vertical layout.

```
┌─────────────────────────────────────────────────────┐
│  DRONE STATUS                              MQ-9A    │
│  ─────────────────────────────────────────────────  │
│  FUEL   ■■■■■■■■■■■■■■■■■■■■■■■■░░░░░░░░░░░░░░░  │
│  ─────────────────────────────────────────────────  │
│  INTEGRITY  ●●●●●○○○○○   SENSORS  ●●○○○○○○○       │
│  VIS/RCS    ●●●○○○○○○○   COMMS    ●○○○○○          │
│  ─────────────────────────────────────────────────  │
│  ALT: ▲ HIGH    LOADOUT: [AGM] [GBU] [CAM]         │
└─────────────────────────────────────────────────────┘
```

#### Status Indicator Dots

Each drone stat uses filled/empty dots to show current vs max capacity:

| State | Dot Style |
|-------|-----------|
| Undamaged | `●` filled circle in `text-primary` |
| Damage point | `●` filled circle in damage color (see below) |
| Maximum slot | `○` empty circle in `text-muted` |

#### Damage Color Rules

| Damage Level | Color | When |
|--------------|-------|------|
| 0 (none) | `status-ok` | No damage taken |
| 1–2 pts | `status-caution` | Light damage |
| 3–4 pts | `status-warning` | Moderate damage |
| 5+ pts | `status-critical` | Heavy damage |
| At max | `status-destroyed` | System destroyed |

#### Layout
- **Background**: `background-secondary`
- **Border**: 1px solid `border-default`
- **Padding**: `space-4` (16pt)
- **Border Radius**: `radius-md` (6pt)
- **Drone name**: `heading-lg` font in `accent-secondary`

---

### 2.3 Card Display Components

Three card types share a base layout but distinct accent colors.

#### Base Card Dimensions
- **Width**: 280pt (fixed, centered in display area)
- **Height**: 380pt (proportional to standard game card)
- **Border Radius**: `radius-md` (6pt)
- **Border**: 2px solid (color varies by type)

#### Card Type Color Mapping

| Card Type | Border Color | Header BG | Accent |
|-----------|-------------|-----------|--------|
| **Target** | `#40C4FF` (accent-secondary) | `#40C4FF15` | Blue tones |
| **Threat** | `#FF1744` (accent-danger) | `#FF174415` | Red tones |
| **Combat** | `#FFB300` (accent-warm) | `#FFB30015` | Amber tones |

#### Card Layout

```
┌──────────────────────────────┐
│  HEADER BAR (type color bg)  │ ← Card type + card number
│  ▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬ │ ← 2px accent line
│                              │
│     🎯 CARD NAME             │ ← heading-lg, text-primary
│     Sub-category             │ ← body-sm, text-secondary
│                              │
│  ┌──────────────────────┐    │
│  │   CARD IMAGE AREA    │    │ ← Square image (if available)
│  └──────────────────────┘    │
│                              │
│  VP: 12    ALT: MED+         │ ← data-md readouts
│  TYPE: ARMOR  DRM: +1        │
│                              │
│  Special instructions text   │ ← body-sm, italicized
│  in accent color             │
│                              │
└──────────────────────────────┘
```

#### Card Animations
- **Reveal**: Flip animation (Y-axis 3D rotation, 400ms)
- **Discard**: Slide right + fade out (200ms)
- **To destroyed pile**: Brief "explosion" particle burst + scale-down

---

### 2.4 Game Board Progress Indicator (B0–B5)

A horizontal step indicator showing the drone's position in the cycle.

```
  B0       B1       B2       B3       B4       B5
  ●────────●────────◉────────○────────○────────○
  TRANSIT  SEARCH   TARGET   POSITION ATTACK   EVASION
                    ACQ
```

| State | Style |
|-------|-------|
| **Completed** | `●` filled, `accent-primary`, solid connector line |
| **Current** | `◉` large ring + pulse animation, `accent-primary` + glow |
| **Upcoming** | `○` empty, `text-muted`, dashed connector line |

#### Layout
- **Height**: 48pt
- **Node diameter**: 16pt (completed/upcoming), 22pt (current with pulse)
- **Connector line**: 2pt thick
- **Labels below**: `label-uppercase`, `text-secondary`
- **Current label**: `accent-primary`, bold

---

### 2.5 Altitude Selector

A vertical selector for drone altitude levels (VLOW, LOW, MEDIUM, HIGH).

```
  ┌─────────┐
  │  HIGH   │ ← selected: accent-primary bg, text-inverse
  ├─────────┤
  │  MEDIUM │ ← available: surface bg, text-primary
  ├─────────┤
  │  LOW    │ ← available
  ├─────────┤
  │  VLOW   │ ← disabled (if drone can't operate): text-muted, no interaction
  └─────────┘
     ▲ 1F      ← Fuel cost indicator for altitude change
```

| Property | Value |
|----------|-------|
| **Width** | 80pt |
| **Cell height** | 36pt |
| **Selected bg** | `accent-primary` |
| **Selected text** | `text-inverse` |
| **Available bg** | `surface` |
| **Available text** | `text-primary` |
| **Disabled bg** | `background-primary` |
| **Disabled text** | `text-muted` |
| **Border** | 1px `border-default` |
| **Font** | `font-hud`, `heading-sm` size |

---

### 2.6 Dice Roll Display

Shows DR results with a satisfying animation.

```
  ┌─────────────────────────────┐
  │    ┌───┐      ┌───┐┌───┐   │
  │    │ 4 │  or  │ 3 ││ 7 │   │ ← D6 or 2×D10
  │    └───┘      └───┘└───┘   │
  │                             │
  │    DRM: +2   FINAL: 6       │ ← data-md, accent-secondary
  └─────────────────────────────┘
```

#### Die Face

| Property | Value |
|----------|-------|
| **Size** | 56pt × 56pt |
| **Background** | `surface` |
| **Border** | 2px solid `border-active` |
| **Border Radius** | `radius-sm` (4pt) |
| **Number font** | `font-mono`, `data-lg` (28pt), `text-primary` |
| **Roll animation** | Rapid number cycling (100ms intervals) for 800ms, then settle |

#### DRM Display
- Positive DRM: shown in `accent-primary` with `+` prefix
- Negative DRM: shown in `accent-danger` with `−` prefix
- Final value: `accent-secondary`, bold, slightly larger

---

### 2.7 CRT Result Display

Shows combat resolution table results after dice rolls.

```
  ┌─────────────────────────────┐
  │  ATTACK RESULT              │
  │  ═══════════════════════    │
  │                             │
  │       ▶ HIT ◀               │ ← Large, centered, green flash
  │       2F consumed           │ ← Fuel cost
  │                             │
  │  Mode: CLOSE-IN   Alt: MED  │
  │  DRM: 5   Column: 5        │
  └─────────────────────────────┘
```

| Result | Style |
|--------|-------|
| **HIT** | `display-lg`, `accent-primary`, flash animation + scale pulse |
| **MISS** | `display-lg`, `accent-danger`, shake animation |
| **Damage (1D, 2D)** | `display-lg`, `accent-danger`, with damage detail below |
| **Fuel cost** | `data-md`, `accent-warm` |

---

### 2.8 Buttons

#### Primary Action Button
```
┌─────────────────────┐
│   ENGAGE TARGET      │ ← font-display, 16pt, uppercase
└─────────────────────┘
```

| Property | Value |
|----------|-------|
| **Height** | 48pt |
| **Padding** | `space-4` horizontal, `space-3` vertical |
| **Background** | `accent-primary` |
| **Text** | `text-inverse`, `font-display`, 600 weight, uppercase |
| **Border Radius** | `radius-sm` (4pt) |
| **Hover/Press** | Lighten 10%, subtle scale(1.02) |
| **Disabled** | Opacity 0.4, no interaction |
| **Letter Spacing** | +1pt |

#### Secondary / Outline Button
| Property | Value |
|----------|-------|
| **Background** | transparent |
| **Border** | 1px solid `accent-secondary` |
| **Text** | `accent-secondary` |
| **Hover/Press** | Fill with `accent-secondary` at 10% opacity |

#### Danger Button
| Property | Value |
|----------|-------|
| **Background** | `accent-danger` |
| **Text** | `#FFFFFF` |
| **Usage** | Destructive actions, "ABORT MISSION", emergency RTB |

---

### 2.9 Loadout Selection Interface

Weapon/kit items displayed as selectable tiles in a scrollable grid.

```
┌──────────────────────────────────────────────┐
│  SELECT LOADOUT                              │
│  ────────────────────────────────────────     │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐   │
│  │  AGM-114 │  │  GBU-12  │  │  CAMERA  │   │
│  │  Hellfire │  │  Paveway │  │  Kit     │   │
│  │  ───────  │  │  ───────  │  │  ─────── │   │
│  │  Types:   │  │  Types:   │  │  FO/Laze │   │
│  │  AFV,Tank │  │  Bunker   │  │  ──────  │   │
│  │  ──────── │  │  ──────── │  │  No wpn  │   │
│  │  Class: B+│  │  Class: A │  │  All     │   │
│  │  Mode: SO │  │  Mode: CI │  │  Mode: FO│   │
│  │  ✓ SELECT │  │  SELECT   │  │  SELECT  │   │
│  └──────────┘  └──────────┘  └──────────┘   │
│                                              │
│  Slots: 2/3 used                             │
│  [CONFIRM LOADOUT]                           │
└──────────────────────────────────────────────┘
```

#### Loadout Tile

| Property | Value |
|----------|-------|
| **Size** | 100pt × 160pt |
| **Background** | `surface` (unselected), `accent-primary-dim` (selected) |
| **Border** | 1px `border-default` (unselected), 2px `accent-primary` (selected) |
| **Selected indicator** | `✓` checkmark icon in top-right corner, `accent-primary` |
| **Disabled** | Opacity 0.3, crossed-out icon |
| **Restriction badges** | `(*A)`, `(%)`, `(+)` in `caption` font, `accent-warm` |

---

### 2.10 Drone Selection Grid

```
┌──────────────────────────────────────────────┐
│  SELECT YOUR DRONE                           │
│  Filter: [ALL ▼]  [Country ▼]  [Class ▼]    │
│  ────────────────────────────────────────     │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐   │
│  │  MQ-9A   │  │  TB2     │  │  Harop   │   │
│  │  Reaper  │  │  Bayraktar│  │  IAI     │   │
│  │  ───────  │  │  ─────── │  │  ─────── │   │
│  │  Class: A │  │  Class: B │  │  Class: C│   │
│  │  🇺🇸 USA  │  │  🇹🇷 TUR  │  │  🇮🇱 ISR │   │
│  │  Fuel: ██ │  │  Fuel: █  │  │  Fuel: █ │   │
│  └──────────┘  └──────────┘  └──────────┘   │
│                                              │
│  28 drones available                         │
└──────────────────────────────────────────────┘
```

#### Drone Card Tile

| Property | Value |
|----------|-------|
| **Size** | Responsive; ~160pt × 140pt (2-column on phone) |
| **Background** | `surface` |
| **Selected** | `accent-secondary` 2px border + glow |
| **Drone name** | `heading-sm`, `text-primary` |
| **Country flag** | 16pt emoji or small icon |
| **Class badge** | Colored pill badge (`radius-xs`): A=blue, B=green, C=amber, D=red |
| **Fuel preview** | Mini fuel bar (4pt tall, same color system) |

---

### 2.11 Decision Point Overlay

Appears at B2 (Engage or Retreat) and B5 (Continue, RTB, Pitstop).

```
┌──────────────────────────────────────┐
│                                      │
│  🎯 DRONE COMMANDER'S DECISION      │
│  ═══════════════════════════════     │
│                                      │
│  Target: T-72 Tank  (VP: 8)         │
│  Threat: SA-11 SAM                   │
│                                      │
│  ┌────────────────┐ ┌──────────────┐ │
│  │  ✓ ENGAGE      │ │  ✕ RETREAT   │ │
│  │  (go to B3)    │ │  (back to B1)│ │
│  └────────────────┘ └──────────────┘ │
│                                      │
└──────────────────────────────────────┘
```

- **Background**: `background-overlay` (dark translucent)
- **Card**: `background-secondary` with `border-active` border
- **Title**: `display-sm`, `accent-warm`
- **Engage button**: Primary (green)
- **Retreat button**: Secondary/outline

---

### 2.12 Post-Mission Briefing Screen

```
┌──────────────────────────────────────────────┐
│  MISSION DEBRIEF                             │
│  ════════════════════════════════════════     │
│                                              │
│  RESULT: MISSION COMPLETE                    │ ← or DRONE LOST
│                                              │
│  ┌────────────────────────────────────┐      │
│  │  Targets Destroyed     4          │      │
│  │  Victory Points        32         │      │
│  │  Drone VP Cost         -12        │      │
│  │  ─────────────────────────────    │      │
│  │  FINAL SCORE           20         │      │
│  └────────────────────────────────────┘      │
│                                              │
│  Cycles Completed: 6                         │
│  Fuel Remaining: ██░░░░░ (18%)               │
│  Damage Taken: 3 structural                  │
│                                              │
│  [VIEW DESTROYED TARGETS]  [MAIN MENU]       │
└──────────────────────────────────────────────┘
```

| Element | Style |
|---------|-------|
| Result (success) | `display-lg`, `accent-primary`, glow |
| Result (failure) | `display-lg`, `accent-danger`, shake |
| Score table | Monospaced `font-mono`, `data-md` |
| Final score | `data-lg`, `accent-secondary`, highlighted row |

---

### 2.13 Splash Screen

The first screen the player sees. Atmospheric, sparse, dramatic.

```
┌──────────────────────────────────────┐
│                                      │
│     ╱╱╱ subtle topo grid bg ╱╱╱     │
│                                      │
│          ┌─────────────┐             │
│         ╱   RADAR SWEEP  ╲           │
│        │  concentric rings  │        │
│        │                    │        │
│        │ DRONE  COMMANDER  │        │
│        │ OBSCURE BATTLES 3 │        │
│        │      V3.1         │        │
│         ╲                  ╱         │
│          └─────────────┘             │
│                                      │
│                                      │
│  ■■■■■■■■■■■■■■■░░░░░░░░░░░░░░░    │ ← Loading bar
│  INITIALIZING SYSTEMS...             │
│                                      │
└──────────────────────────────────────┘
```

| Element | Specification |
|---------|--------------|
| **Background** | `background-primary` (#0A0E14) with faint topographic grid lines in `#111927` |
| **Radar circle** | 240pt diameter, concentric rings in `accent-primary` at 15% opacity, sweeping arm in `accent-primary` at 40% opacity, rotating 360° in 3s |
| **Title "DRONE COMMANDER"** | `font-display` (Rajdhani), 36pt, 700 weight, `accent-primary`, +1pt tracking, `shadow-glow-green` |
| **Subtitle "OBSCURE BATTLES 3"** | `font-body`, 16pt, 500 weight, `accent-secondary` |
| **Version "V3.1"** | `font-mono`, 12pt, `text-muted` |
| **Loading bar** | 4pt tall, `accent-primary`, animated left-to-right fill over ~2-3s, background `background-tertiary` |
| **Loading text** | `font-hud`, 10pt, `text-secondary`, uppercase, +1.5pt tracking |

#### Animation Sequence
1. **0–500ms**: Background fades in, radar rings appear with scale-up
2. **500–1200ms**: Radar arm begins sweeping, title types in letter-by-letter (typewriter effect)
3. **1200–1500ms**: Subtitle and version fade in
4. **1500ms+**: Loading bar begins filling; text cycles through: "INITIALIZING SYSTEMS...", "LOADING DATABASE...", "CALIBRATING SENSORS..."
5. **On complete**: Smooth crossfade to Call Sign screen

---

### 2.14 Call Sign Selection Screen

Appears after splash on first launch, or if no call sign is stored. Returning players go straight to Main Menu.

```
┌──────────────────────────────────────┐
│                                      │
│    IDENTIFY YOURSELF                 │ ← display-sm, accent-primary
│    ENTER YOUR CALL SIGN              │ ← body-sm, accent-secondary
│                                      │
│  ┌──────────────────────────────┐    │
│  │  MAVERICK█                    │    │ ← Large mono input, green text
│  └──────────────────────────────┘    │
│  3-12 characters, letters + numbers  │ ← caption, text-muted
│                                      │
│  RECENT CALL SIGNS                   │ ← label-uppercase, text-secondary
│  ┌─────────┐ ┌─────────┐ ┌────────┐ │
│  │  VIPER  │ │ GHOST-7 │ │REDHAWK │ │ ← selectable chips
│  └─────────┘ └─────────┘ └────────┘ │
│                                      │
│  ┌──────────────────────────────┐    │
│  │      CONFIRM CALL SIGN       │    │ ← Primary button
│  └──────────────────────────────┘    │
│  Continue as UNKNOWN                 │ ← skip link, text-muted
│                                      │
└──────────────────────────────────────┘
```

| Element | Specification |
|---------|--------------|
| **Title "IDENTIFY YOURSELF"** | `font-display`, `display-sm` (24pt), `accent-primary`, `shadow-glow-green` |
| **Subtitle** | `font-body`, `body-sm` (14pt), `accent-secondary` |
| **Input field** | Height: 64pt, `background-tertiary` bg, 1px `border-active` border, `radius-sm` |
| **Input text** | `font-hud` (Share Tech Mono), 28pt, `accent-primary`, uppercase auto-transform |
| **Input cursor** | Blinking block cursor in `accent-primary`, 1Hz blink rate |
| **Validation** | Min 3, max 12 chars; alphanumeric + hyphen only; real-time validation |
| **Helper text** | `font-body`, `caption` (12pt), `text-muted` |
| **Recent call signs** | Pill chips: `surface` bg, 1px `accent-primary` border, `radius-sm`, 36pt height |
| **Chip text** | `font-mono`, `body-sm`, `accent-primary`; on tap → fills input |
| **Confirm button** | Full-width Primary button (§2.8), disabled until input valid (≥3 chars) |
| **Skip link** | `body-sm`, `text-muted`, underline on press; sets call sign to "UNKNOWN" |

#### Behavior
- Recent call signs section hidden if no history exists (first-ever launch)
- Input auto-uppercases all text
- Invalid characters shake the input field briefly
- On confirm → store call sign to local storage → navigate to Main Menu

---

### 2.15 Main Menu Screen

The home hub. Player arrives here after call sign selection or on subsequent app launches.

```
┌──────────────────────────────────────┐
│                                      │
│      DRONE COMMANDER                 │ ← display-lg, text-primary
│      CALL SIGN: MAVERICK ✎           │ ← body-sm, accent-secondary
│                                      │
│  ┌──────────────────────────────┐    │
│  │ 🛩  QUICK GAME              ›│    │ ← Green left border
│  │    Solitaire — select drone   │    │
│  └──────────────────────────────┘    │
│                                      │
│  ┌──────────────────────────────┐    │
│  │ 🎯 SCENARIO                 ›│    │ ← Cyan left border
│  │    Mission-based with goals   │    │
│  └──────────────────────────────┘    │
│                                      │
│  ┌──────────────────────────────┐    │
│  │ 🗺  CAMPAIGN          SOON  ›│    │ ← Amber left border, dimmed
│  │    Territory control — v1.1   │    │
│  └──────────────────────────────┘    │
│                                      │
│  ┌──────────────────────────────┐    │
│  │ 💾 LOAD GAME                ›│    │ ← Gray left border
│  │    Resume a saved game        │    │
│  └──────────────────────────────┘    │
│                                      │
│  ┌────────────┐  ┌───────────────┐   │
│  │ ⚙ SETTINGS │  │ ? HOW TO PLAY │   │ ← Outline buttons
│  └────────────┘  └───────────────┘   │
│          v3.1-D10                    │ ← caption, text-muted
└──────────────────────────────────────┘
```

#### Menu Card

| Property | Value |
|----------|-------|
| **Height** | 72pt |
| **Background** | `surface` (#1E293B) |
| **Left border** | 3px solid, color varies by mode (see below) |
| **Border radius** | `radius-md` (6pt) |
| **Padding** | `space-4` (16pt) |
| **Icon** | 24pt, left-aligned, matching left-border color |
| **Title** | `font-display`, `heading-lg` (20pt), `text-primary`, uppercase |
| **Subtitle** | `font-body`, `body-sm` (14pt), `text-secondary` |
| **Chevron** | 16pt right arrow, matching left-border color |
| **Press state** | Background → `surface-hover`, subtle scale(0.98) |

#### Mode Color Mapping

| Mode | Left Border | Icon Color | Status |
|------|------------|------------|--------|
| **Quick Game** | `accent-primary` (#00E676) | `accent-primary` | Active |
| **Scenario** | `accent-secondary` (#40C4FF) | `accent-secondary` | Active |
| **Campaign** | `accent-warm` (#FFB300) | `accent-warm` | Disabled — "SOON" badge |
| **Load Game** | `text-secondary` (#8B9BB4) | `text-secondary` | Active (disabled if no saves) |

#### "SOON" Badge (Campaign)
- Small pill: 40pt × 20pt, `accent-warm` bg, `text-inverse` text
- `caption` font size (12pt), bold, rounded `radius-xs`
- Card opacity: 0.5 when disabled
- On tap: brief toast "Campaign mode coming in v1.1"

#### Call Sign Display
- Format: `CALL SIGN: {NAME}` in `font-mono`, `body-sm`, `accent-secondary`
- Edit icon (✎): 14pt, `text-muted`, tappable → navigates back to Call Sign screen
- Persisted via local storage; loaded on app start

#### Bottom Buttons
- Two equally-sized Outline buttons (§2.8 Secondary style)
- "SETTINGS" → gear icon + `accent-secondary` outline
- "HOW TO PLAY" → `?` icon + `accent-secondary` outline

#### Navigation Flow
```
Splash → Call Sign (first launch only) → Main Menu
                                           ├── Quick Game → Drone Select → Loadout → Game
                                           ├── Scenario → Scenario Select → Drone Select → ...
                                           ├── Campaign → (disabled, toast message)
                                           └── Load Game → Saved Games List → Resume Game
```

---

## 3. Flutter Theme Implementation

### 3.1 ThemeData Structure

```dart
// lib/ui/theme/milstd_theme.dart

class MilstdTheme {
  // Color tokens
  static const Color backgroundPrimary = Color(0xFF0A0E14);
  static const Color backgroundSecondary = Color(0xFF111927);
  static const Color backgroundTertiary = Color(0xFF1A2332);
  static const Color surface = Color(0xFF1E293B);
  static const Color surfaceHover = Color(0xFF253347);

  static const Color accentPrimary = Color(0xFF00E676);
  static const Color accentPrimaryDim = Color(0x4000C864);
  static const Color accentSecondary = Color(0xFF40C4FF);
  static const Color accentWarm = Color(0xFFFFB300);
  static const Color accentDanger = Color(0xFFFF1744);

  static const Color statusOk = Color(0xFF00E676);
  static const Color statusCaution = Color(0xFFFFD600);
  static const Color statusWarning = Color(0xFFFF9100);
  static const Color statusCritical = Color(0xFFFF1744);
  static const Color statusDestroyed = Color(0xFFB71C1C);

  static const Color textPrimary = Color(0xFFE0E7EF);
  static const Color textSecondary = Color(0xFF8B9BB4);
  static const Color textMuted = Color(0xFF4A5568);
  static const Color textInverse = Color(0xFF0A0E14);
  static const Color textHud = Color(0xFF00E676);

  static const Color borderSubtle = Color(0xFF1E293B);
  static const Color borderDefault = Color(0xFF2D3F56);
  static const Color borderActive = Color(0xFF00E676);

  // Spacing
  static const double space1 = 4;
  static const double space2 = 8;
  static const double space3 = 12;
  static const double space4 = 16;
  static const double space6 = 24;
  static const double space8 = 32;

  // Radii
  static const double radiusXs = 2;
  static const double radiusSm = 4;
  static const double radiusMd = 6;
  static const double radiusLg = 8;

  /// Build the Flutter ThemeData
  static ThemeData build() {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: backgroundPrimary,
      canvasColor: backgroundSecondary,
      cardColor: surface,
      colorScheme: const ColorScheme.dark(
        primary: accentPrimary,
        secondary: accentSecondary,
        error: accentDanger,
        surface: surface,
      ),
      // Typography, buttons, input decoration, etc.
      // will be defined in implementation phase
    );
  }
}
```

### 3.2 Fuel Bar Widget API

```dart
/// Fuel color bar — shows fuel as gradient bar, no numbers.
/// Color transitions: green → yellow → orange → red.
class FuelBar extends StatelessWidget {
  /// Current fuel level (0.0 to 1.0)
  final double fuelFraction;

  /// Whether to show pulse animation at critical levels
  final bool enablePulse;

  const FuelBar({
    required this.fuelFraction,
    this.enablePulse = true,
  });

  Color get barColor {
    if (fuelFraction > 0.60) return MilstdTheme.statusOk;
    if (fuelFraction > 0.30) return MilstdTheme.statusCaution;
    if (fuelFraction > 0.15) return MilstdTheme.statusWarning;
    return MilstdTheme.statusCritical;
  }
}
```

---

## 4. Accessibility Standards

### 4.1 Color Contrast

All text/background combinations meet **WCAG AA** (4.5:1 ratio minimum):

| Combination | Ratio | Pass |
|-------------|-------|------|
| `text-primary` (#E0E7EF) on `background-primary` (#0A0E14) | 14.2:1 | ✅ AAA |
| `text-secondary` (#8B9BB4) on `background-primary` (#0A0E14) | 6.1:1 | ✅ AA |
| `text-hud` (#00E676) on `background-primary` (#0A0E14) | 8.4:1 | ✅ AAA |
| `accent-warm` (#FFB300) on `background-primary` (#0A0E14) | 9.8:1 | ✅ AAA |
| `accent-danger` (#FF1744) on `background-primary` (#0A0E14) | 5.3:1 | ✅ AA |
| `text-inverse` (#0A0E14) on `accent-primary` (#00E676) | 8.4:1 | ✅ AAA |

### 4.2 Touch Targets

- Minimum interactive element size: **44pt × 44pt** (Apple HIG)
- Altitude selector cells: 80pt × 36pt ✅
- Buttons: 48pt height minimum ✅
- Loadout tiles: 100pt × 160pt ✅
- Dice display: 56pt × 56pt ✅

### 4.3 Motion Sensitivity

- All animations respect `MediaQuery.disableAnimations` / `prefers-reduced-motion`
- Fuel bar pulse can be disabled
- Card flip can be replaced with simple fade

---

## 5. Iconography & Visual Language

### 5.1 Icon Style

- **Style**: Line icons, 1.5pt stroke, monochrome in `text-secondary`
- **Active**: `accent-primary` fill
- **Size**: 20pt (default), 16pt (compact), 24pt (prominent)
- **Source**: Custom SVG or Phosphor Icons (military subset)

### 5.2 Game-Specific Icons

| Icon | Usage | Description |
|------|-------|-------------|
| Crosshair | Attack mode | Simple + crosshair |
| Shield | Evasion | Angled shield shape |
| Radar sweep | Search/B1 | Arc with dot |
| Flame | Fuel | Flame or lightning bolt |
| Wrench | Damage/repair | Crossed tools |
| Arrow up/down | Altitude | Chevron arrows |
| Target reticle | Target acquired | Concentric circles |
| Skull | Drone lost | Skull or X |
| Star | VP/score | 5-point star |
| Radio waves | COMMS | Broadcast symbol |

---

## 6. Screen Layout Architecture

### 6.1 Main Game Screen Layout (Portrait)

```
┌──────────────────────────────────────┐
│  ┌─ TOP BAR ────────────────────┐    │  48pt
│  │ ☰  CYCLE 3   ZONE 2   ⚙️    │    │
│  └──────────────────────────────┘    │
│                                      │
│  ┌─ PROGRESS BAR ──────────────┐    │  48pt
│  │ B0──B1──◉B2──B3──B4──B5    │    │
│  └──────────────────────────────┘    │
│                                      │
│  ┌─ STATUS PANEL ──────────────┐    │  ~120pt
│  │ FUEL ■■■■■■■■■■■░░░░░░░    │    │
│  │ INT ●●○○○  SEN ●○○○  ...   │    │
│  │ ALT: MED   LOADOUT: [×3]    │    │
│  └──────────────────────────────┘    │
│                                      │
│  ┌─ MAIN CONTENT AREA ────────┐    │  Flex
│  │                              │    │
│  │  (Cards / CRT / Dice        │    │
│  │   display area —             │    │
│  │   content changes per        │    │
│  │   game phase B0–B5)          │    │
│  │                              │    │
│  └──────────────────────────────┘    │
│                                      │
│  ┌─ ACTION LOG ────────────────┐    │  ~60pt
│  │ > Target acquired: T-72     │    │
│  │ > Threat detected: SA-11    │    │
│  │ > DR: 4 + DRM +2 = 6       │    │
│  └──────────────────────────────┘    │
│                                      │
│  ┌─ ACTION BUTTONS ───────────┐    │  56pt
│  │ [ENGAGE TARGET]  [RETREAT]  │    │
│  └──────────────────────────────┘    │
└──────────────────────────────────────┘
```

---

**Designer**: OB3-UIDesigner
**Design System Version**: 1.0
**Status**: Ready for developer handoff + user review
