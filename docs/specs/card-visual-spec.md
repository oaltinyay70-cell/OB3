# OB3 Drone Commander — Card Visual Specification
# LOCKED — Do not modify without explicit user approval

> **Version**: 1.0  
> **Date**: 2026-03-19  
> **Status**: 🔒 LOCKED  
> **Authority**: Single source of truth for all card image generation, in-app rendering, and print recreation.

---

## 1. Universal Card Dimensions

All three card types share identical physical dimensions.

| Property | Value |
|----------|-------|
| **Aspect Ratio** | 1 : 1.4 (Standard Bridge/Poker card) |
| **Canvas Width** | 630 px (print: 63 mm @ 254 dpi) |
| **Canvas Height** | 882 px (print: 88.2 mm @ 254 dpi) |
| **Safe Area Padding** | 16 px all sides |
| **Corner Radius** | 18 px |
| **Border Width** | 4 px |
| **Background** | `#0D1117` (near-black, all types) |

> **Print DPI**: 300 dpi production. 254 dpi internal reference grid.  
> **Screen (pt)**: 280 × 392 pt logical (2× retina = 560 × 784 px)

---

## 2. Shared Zone Architecture

All cards use the same 5-zone vertical layout:

```
┌─────────────────────────────────────┐  ← corner radius 18px
│ ██████████ HEADER BAR █████████████ │  Zone 1 — 72px tall
├─────────────────────────────────────┤
│  TITLE                              │  Zone 2 — 88px tall
│  subtitle                           │
├─────────────────────────────────────┤
│  ┌─────────────────────────────┐    │
│  │                             │    │  Zone 3 — 352px tall (image)
│  │     SENSOR / ART WINDOW     │    │
│  │         (1.78:1)            │    │
│  └─────────────────────────────┘    │
├─────────────────────────────────────┤
│  [ STAT BOX LEFT ] [ STAT BOX RT ]  │  Zone 4 — 88px tall
├─────────────────────────────────────┤
│  flavor / rule text                 │  Zone 5 — 80px tall
└─────────────────────────────────────┘
   Total height: 72+88+352+88+80 = 680px + 2×16px padding = 712px canvas body
```

---

## 3. THREAT CARD — Full Specification

### 3.1 Identity
| Property | Value |
|----------|-------|
| Card type label | `THREAT CARD` |
| ID format | `THXXX-000` (e.g., `THSA-004`) |
| Border color | `#FF1744` · Pantone **186 C** (Crimson Red) |
| Background | `#0D1117` |

### 3.2 Zone 1 — Header Bar
| Property | Value |
|----------|-------|
| Height | 72 px |
| Background | `#C62828` · Pantone **1955 C** (Deep Crimson) |
| Left text | `"THREAT CARD"` — **Barlow Semi-Condensed Bold**, 18px, `#FFFFFF` |
| Right text | `"ID: THXX-000"` — **Share Tech Mono**, 14px, `#FFAB00` (Amber) |
| Padding horizontal | 16 px |
| Vertical alignment | Center |

### 3.3 Zone 2 — Title Area
| Property | Value |
|----------|-------|
| Height | 88 px |
| Background | `#111827` |
| Title font | **Barlow Semi-Condensed ExtraBold**, 30px, `#FFFFFF` |
| Subtitle font | **Barlow Semi-Condensed Medium**, 13px, `#FFAB00` · Pantone **137 C** |
| Subtitle format | `"THREAT — [CATEGORY]"` (all caps) |
| Title padding | 16 px left, 8 px top |

### 3.4 Zone 3 — FLIR Thermal Image Window
| Property | Value |
|----------|-------|
| Width | 598 px (canvas − 2×16px padding) |
| Height | 352 px |
| Aspect ratio | 1.7:1 landscape |
| Image style | **FLIR Thermal — Amber/Orange on Black** |
| Primary tone | `#FF6F00` · Pantone **152 C** (Deep Amber) |
| Hot-spot tone | `#FFD54F` · Pantone **114 C** (Bright Amber) |
| Background tone | `#1A0A00` (near-black warm) |
| Crosshair color | `#FF1744` |
| HUD text color | `#FFAB00`, **Share Tech Mono** 10px |
| Border | 2px `#FF1744` inset |
| HUD elements | altitude readout (top-left), heading (top-right), scale (bottom-left), range (bottom-right) |

### 3.5 Zone 4 — Stat Boxes
| Property | Value |
|----------|-------|
| Height | 88 px |
| Gap between boxes | 8 px |
| Left box background | `#3E0000` |
| Left box border | 2px `#FF1744` |
| Left box text | **Barlow Semi-Condensed Bold**, 22px, `#FF1744` |
| Left box label | e.g., `"SHIFT: +1R"` or `"+1R SHIFT"` |
| Right box background | `#2A1800` |
| Right box border | 2px `#FFAB00` |
| Right box text | **Barlow Semi-Condensed Bold**, 22px, `#FFAB00` |
| Right box label | e.g., `"ALT: LOW"` |
| Box corner radius | 6px |
| Box padding | 12px horizontal, 8px vertical |

### 3.6 Zone 5 — Flavor / Rule Text
| Property | Value |
|----------|-------|
| Height | 80 px |
| Background | `#0D1117` |
| Font | **Share Tech Mono**, 12px, `#FFD54F` |
| Padding | 16 px horizontal, 8 px top |
| Max lines | 3 |
| Line height | 1.5 |

---

## 4. TARGET CARD — Full Specification

### 4.1 Identity
| Property | Value |
|----------|-------|
| Card type label | `TARGET CARD` |
| ID format | `TCXX000` (e.g., `TCTK001`) |
| Border color | `#00E5FF` · Pantone **306 C** (Cyan) |
| Background | `#0D1117` |

### 4.2 Zone 1 — Header Bar
| Property | Value |
|----------|-------|
| Height | 72 px |
| Background | `#00B8D4` · Pantone **3115 C** (Teal/Cyan) |
| Left text | `"TARGET CARD"` — **Barlow Semi-Condensed Bold**, 18px, `#FFFFFF` |
| Right text | `"ID: TCXX000"` — **Share Tech Mono**, 14px, `#002B36` (dark, on cyan) |
| Padding horizontal | 16 px |

### 4.3 Zone 2 — Title Area
| Property | Value |
|----------|-------|
| Height | 88 px |
| Background | `#0A1628` |
| Title font | **Barlow Semi-Condensed ExtraBold**, 30px, `#FFFFFF` |
| Subtitle font | **Barlow Semi-Condensed Medium**, 13px, `#00E5FF` |
| Subtitle format | `"TARGET — [SUB-CATEGORY]"` (all caps) |

### 4.4 Zone 3 — Night-Vision Aerial Image Window
| Property | Value |
|----------|-------|
| Width | 598 px |
| Height | 352 px |
| Image style | **Green Night-Vision (NV) — Aerial top-down drone camera** |
| Primary tone | `#00C853` · Pantone **802 C** (Phosphor Green) |
| Hot-spot tone | `#CCFF90` · Pantone **375 C** (Bright Green) |
| Background tone | `#001A00` (near-black cool green) |
| Crosshair color | `#00E5FF` (cyan) |
| HUD text color | `#00E5FF`, **Share Tech Mono** 10px |
| Camera perspective | **Top-down orthographic** — drone looking straight down |
| Border | 2px `#00E5FF` inset |

### 4.5 Zone 4 — Stat Boxes
| Property | Value |
|----------|-------|
| Height | 88 px |
| Left box background | `#002A3A` |
| Left box border | 2px `#00E5FF` |
| Left box text | **Barlow Semi-Condensed Bold**, 20px, `#00E5FF` |
| Left box format | `"X VP"` + sub-label `"VICTORY POINTS"` (10px) |
| Right box background | `#002A3A` |
| Right box border | 2px `#00E5FF` |
| Right box text | **Barlow Semi-Condensed Bold**, 22px, `#FFFFFF` |
| Right box label | `"ALT: ALL"` / `"ALT: LOW"` etc. |

### 4.6 Zone 5 — Flavor / Rule Text
| Property | Value |
|----------|-------|
| Height | 80 px |
| Font | **Share Tech Mono**, 12px, `#B2EBF2` |
| Padding | 16 px horizontal |

---

## 5. COMBAT CARD — Full Specification

### 5.1 Identity
| Property | Value |
|----------|-------|
| Card type label | `COMBAT CARD` |
| ID format | `NEW_CC_00` (e.g., `NEW_CC_01`) |
| Border color | `#00E5FF` · Pantone **306 C** (same cyan as target) |
| Background | `#0D1117` |

### 5.2 Zone 1 — Header Bar
| Property | Value |
|----------|-------|
| Height | 72 px |
| Background | `#00B8D4` · Pantone **3115 C** |
| Left text | `"COMBAT CARD"` — **Barlow Semi-Condensed Bold**, 18px, `#FFFFFF` |
| Right text | `"ID: NEW_CC_00"` — **Share Tech Mono**, 14px, `#002B36` |
| Padding horizontal | 16 px |

### 5.3 Zone 2 — Title Area
| Property | Value |
|----------|-------|
| Height | 88 px |
| Background | `#0A1628` |
| Title font | **Barlow Semi-Condensed ExtraBold**, 28px, `#FFFFFF` |
| Subtitle font | **Barlow Semi-Condensed Medium**, 13px, `#00E5FF` |
| Subtitle format | `"COMBAT — [TYPE]"` e.g., `ATTACK` / `WEATHER` / `ALTITUDE` / `ELECTRONIC` |

### 5.4 Zone 3 — Tactical HUD Image Window
| Property | Value |
|----------|-------|
| Width | 598 px |
| Height | 352 px |
| Image style | **Cyan/Teal tactical HUD display** — digital, 3D wireframe or tactical map |
| Primary tone | `#00E5FF` · Pantone **306 C** (Cyan) |
| Glow tone | `#80DEEA` (soft teal) |
| Background tone | `#00131A` (near-black deep teal) |
| Accent elements | Red warning markers `#FF1744` for negative cards |
| HUD text color | `#00E5FF`, **Share Tech Mono** 10px |
| Border | 2px `#00E5FF` inset |
| Imagery type | Relevant to card theme: drone 3D model, radar sweep, weather map, terrain nap-of-earth |

### 5.5 Zone 4 — Combat Effect Box (Single Wide)
| Property | Value |
|----------|-------|
| Height | 88 px |
| Width | Full width (598 px) |
| Background | `#002A3A` |
| Border | 2px `#00E5FF` |
| Label | `"COMBAT EFFECT"` — **Barlow Semi-Condensed Bold**, 11px, `#00E5FF` (top, left-aligned) |
| Effect text | **Barlow Semi-Condensed ExtraBold**, 26px, `#FFFFFF` |
| Effect text examples | `"+2 ATTACK DRM"` / `"CLIMB +1 ALT BAND"` / `"SKIP COMMS PHASE"` |
| Corner radius | 6 px |
| Padding | 12 px horizontal, 8 px vertical |

### 5.6 Zone 5 — Flavor Quote
| Property | Value |
|----------|-------|
| Height | 80 px |
| Font | **Share Tech Mono**, 12px, `#B2EBF2` |
| Style | Movie/military quote, italic preferred |
| Padding | 16 px horizontal |

---

## 6. Typography System

| Role | Font | Pantone equiv | Hex |
|------|------|--------------|-----|
| Header label | Barlow Semi-Condensed Bold | — | varies by type |
| Card title | Barlow Semi-Condensed ExtraBold | — | `#FFFFFF` |
| Subtitle | Barlow Semi-Condensed Medium | — | varies by type |
| ID / monospace | Share Tech Mono | — | varies |
| Flavor text | Share Tech Mono | — | varies |
| HUD data | Share Tech Mono | — | type accent color |

> **Google Fonts CDN**: `Barlow+Semi+Condensed:wght@400;600;700;800` + `Share+Tech+Mono`

---

## 7. Pantone Color Registry

| Name | Usage | Hex | Pantone |
|------|-------|-----|---------|
| Crimson Red | Threat border, shift box text | `#FF1744` | **186 C** |
| Deep Crimson | Threat header bg | `#C62828` | **1955 C** |
| Deep Amber | Threat FLIR primary | `#FF6F00` | **152 C** |
| Bright Amber | Threat FLIR hot-spot | `#FFD54F` | **114 C** |
| Amber Text | Threat subtitle / ID | `#FFAB00` | **137 C** |
| Cyan | Target/Combat border, header | `#00E5FF` | **306 C** |
| Teal Header | Target/Combat header bg | `#00B8D4` | **3115 C** |
| Phosphor Green | Target NV primary | `#00C853` | **802 C** |
| Bright NV | Target NV hot-spot | `#CCFF90` | **375 C** |
| Near-Black | All card backgrounds | `#0D1117` | **Black 7 C** |
| Deep Navy | Title zone bg | `#0A1628` | **289 C** |
| Mid Navy | Stat box bg | `#002A3A` | **302 C** |
| Warm Black | Threat image bg | `#1A0A00` | — |
| Cool Black | Target image bg | `#001A00` | — |
| Deep Teal Black | Combat image bg | `#00131A` | — |

---

## 8. Border & Spacing System

| Property | Value |
|----------|-------|
| Card border width | 4 px |
| Card corner radius | 18 px |
| Inner zone separator | 2 px `rgba(255,255,255,0.08)` |
| Image inset border | 2 px (type accent color) |
| Stat box gap | 8 px |
| Stat box corner radius | 6 px |
| Global safe padding | 16 px |
| Zone internal padding | 12–16 px horizontal, 8–12 px vertical |

---

## 9. Image Generation Prompt Constants

When generating card images (AI), always include:

### Threat cards
```
FLIR thermal infrared (amber/orange on black). [SUBJECT]. Targeting crosshair center. 
FLIR HUD overlay: altitude top-left, heading top-right, scale bottom-left, range bottom-right.
Share Tech Mono HUD text in amber #FFAB00. No blue. No green. Amber/orange/red/black palette only.
```

### Target cards
```
Green night-vision aerial top-down drone camera view. [SUBJECT] seen from directly above.
Bright phosphor green (#00C853) on near-black (#001A00). Cyan crosshair (#00E5FF).
NV HUD data overlay corners. Orthographic top-down angle. No red. Green/cyan/black palette only.
```

### Combat cards
```
Cyan/teal tactical HUD display (#00E5FF on #00131A). [THEME-SPECIFIC IMAGERY].
3D wireframe or digital tactical map aesthetic. Teal glow. HUD data overlays.
Red warning accents (#FF1744) only for negative-effect cards. Cyan/teal/dark palette.
```

---

> [!IMPORTANT]
> **Status: 🔒 LOCKED — 2026-03-19**. This document supersedes all previous card template specs.
> Source artifacts: `threat_card_template.md`, `target_card_template.md`, `combat_card_template.md`
> Any reproduction — digital or physical — must match these values exactly.
