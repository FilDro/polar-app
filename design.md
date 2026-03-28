# KINE — Design System

**v3.0 | March 2026**
**Supersedes:** `unified_color_spec_v2.md`, `design_system.md` (both retired)

Single source of truth for color, typography, spacing, and component tokens across all KINE surfaces. Platform-specific deviations are documented inline.

---

## Principles

1. **One palette, multiple renderings.** Platforms may use different token names, font stacks, and conventions, but brand colors must match.
2. **Color carries meaning, not decoration.** Chromatic color is reserved for: interaction accent, product identity, semantic status, and data visualization. Everything else is neutral.
3. **Gold is the brand accent.** `#FFCF00` is the primary interaction color across all platforms — active states, emphasis, CTAs, selection indicators.
4. **Red is never a primary action color.** Red means error, danger, or destructive action. Never used for "buy", "navigate", or "interact".
5. **Severity follows the warm spectrum.** green (good) → yellow (caution) → orange (warning) → red (danger).
6. **Every color usage must meet WCAG 2.1 AA.** 4.5:1 normal text, 3.0:1 large text, 3.0:1 non-text UI components.

---

## 1. Brand Colors

Six canonical hex values. All platforms reference these.

| Name | Hex | Role |
|------|-----|------|
| **Brand Gold** | `#FFCF00` | Primary interaction accent, emphasis, CTAs, selection states |
| **Brand Green** | `#16C47F` | KineForce identity, success, concentric/propulsive phase |
| **Brand Blue** | `#3081DD` | KineSense identity, info/data |
| **Brand Yellow** | `#FFD65A` | Caution, eccentric/unweighting phase |
| **Brand Orange** | `#FF9D23` | Warning, connecting/in-progress, elevated fatigue |
| **Brand Red** | `#F93827` | Error, danger, destructive, stationary/braking phase |

### Gold vs Yellow — Differentiation Rules

Gold (`#FFCF00`) and Yellow (`#FFD65A`) are perceptually close but serve distinct roles:

- **Gold** = interaction accent. Always paired with a shape affordance (underline, border, ring, uppercase label, selected dot). Never appears in a severity/status context.
- **Yellow** = caution semantic. Always appears alongside the green→orange→red severity spectrum. Never used for interaction or emphasis.

This pattern is validated across the pitch deck, mock dashboards, and website — gold selection indicators coexist with yellow "watch" status alerts without confusion.

### Chromatic Scales (7-shade)

Defined in `kinesense_app/lib/theme/colors.dart` (Flutter) as `KineColors.*`.

#### Green
| Shade | Flutter | Hex | Usage |
|-------|---------|-----|-------|
| 0 | `green0` | `#C0FFDA` | Subtle backgrounds (light) |
| 1 | `green1` | `#1EF09D` | Dark mode success, BLE ready |
| **2** | **`green2`** | **`#16C47F`** | **Brand green** |
| 3 | `green3` | `#0F9962` | Hover/emphasis, signal good |
| 4 | `green4` | `#087147` | Text-safe on white (6.06:1 AA) |
| 5 | `green5` | `#034B2E` | High contrast |
| 6 | `green6` | `#012816` | Dark mode backgrounds |

#### Blue
| Shade | Flutter | Hex | Usage |
|-------|---------|-----|-------|
| 0 | `blue0` | `#ECF1FE` | Subtle backgrounds (light) |
| 1 | `blue1` | `#B8CDFA` | Secondary info |
| 2 | `blue2` | `#75A6F6` | Dark mode info |
| **3** | **`blue3`** | **`#3081DD`** | **Brand blue** |
| 4 | `blue4` | `#215DA2` | Text-safe on white (6.66:1 AA) |
| 5 | `blue5` | `#123C6B` | Active states |
| 6 | `blue6` | `#061D39` | Dark mode backgrounds |

#### Yellow
| Shade | Flutter | Hex | Usage |
|-------|---------|-----|-------|
| **0** | **`yellow0`** | **`#FFD65A`** | **Brand yellow** (backgrounds only on white — 1.40:1) |
| 1 | `yellow1` | `#D6AF00` | Emphasis on dark backgrounds |
| 2 | `yellow2` | `#A98900` | Large text on white (3.35:1), non-text UI |
| 3 | `yellow3` | `#7E6600` | Text-safe on white (5.74:1 AA) |
| 4 | `yellow4` | `#564500` | Very dark |
| 5 | `yellow5` | `#312600` | Nearly black |
| 6 | `yellow6` | `#171000` | Dark mode backgrounds |

#### Orange
| Shade | Flutter | Hex | Usage |
|-------|---------|-----|-------|
| 0 | `orange0` | `#FFD2B8` | Subtle backgrounds |
| **1** | **`orange1`** | **`#FF9D23`** | **Brand orange** |
| 2 | `orange2` | `#CC7B00` | Hover states, right plate chart |
| 3 | `orange3` | `#995B00` | Text-safe on white (5.45:1 AA) |
| 4 | `orange4` | `#6A3D00` | Dark |
| 5 | `orange5` | `#3E2100` | Very dark |
| 6 | `orange6` | `#1D0D00` | Dark mode backgrounds |

#### Red
| Shade | Flutter | Hex | Usage |
|-------|---------|-----|-------|
| 0 | `red0` | `#FEEDEC` | Subtle backgrounds |
| 1 | `red1` | `#FCC3C2` | Borders |
| 2 | `red2` | `#FA8985` | Dark mode error |
| **3** | **`red3`** | **`#F93827`** | **Brand red** |
| 4 | `red4` | `#BA2516` | Text-safe on white (6.24:1 AA) |
| 5 | `red5` | `#7D150B` | Active states |
| 6 | `red6` | `#460703` | Dark mode backgrounds |

#### Gold
| Shade | Flutter | Hex | Usage |
|-------|---------|-----|-------|
| 0 | `gold0` | `#FFE566` | Subtle backgrounds (light) |
| 1 | `gold1` | `#FFD700` | Bright emphasis on dark |
| **2** | **`gold2`** | **`#FFCF00`** | **Brand gold** |
| 3 | `gold3` | `#CC9F00` | Hover/emphasis (= `--gold-hover` on web) |
| 4 | `gold4` | `#806300` | Text-safe on white (5.67:1 AA) |
| 5 | `gold5` | `#4D3B00` | Very dark |
| 6 | `gold6` | `#1F1800` | Dark mode backgrounds |

Web also uses opacity variants of gold2 for subtle fills (see Section 3 web tokens).

---

## 2. Neutrals

### App — Warm Gray

Used in the Flutter app (`KineColors.gray0`–`gray6`). Green-tinted to complement system SF Pro.

| Shade | Flutter | Hex | Light mode | Dark mode |
|-------|---------|-----|------------|-----------|
| 0 | `gray0` | `#EFF1F0` | Cards, subtle bg | Primary text |
| 1 | `gray1` | `#CED4D1` | Borders, elevated | Secondary text |
| 2 | `gray2` | `#A8ADAA` | Disabled text | Tertiary text |
| 3 | `gray3` | `#838785` | Tertiary/muted text | Disabled text |
| 4 | `gray4` | `#606361` | Secondary text | Borders, elevated |
| 5 | `gray5` | `#3F4140` | — | Cards |
| 6 | `gray6` | `#212221` | Primary text | **Background** |

Internal contrast: `#212221` on `#EFF1F0` = **13.76:1** (AAA).

### Web / Pitch Deck — Near-Black (Exception)

The marketing website and pitch deck use a distinct neutral palette. This is a platform exception — Oswald's bold condensed letterforms work well against the near-black background, and the gold accent pops more strongly against `#0A0A0A` than against the warmer `#212221`.

| Token | Hex | Role |
|-------|-----|------|
| `--bg` | `#0A0A0A` | Page background |
| `--bg-subtle` | `rgba(255,255,255,0.05)` | Cards, sections |
| `--bg-muted` | `rgba(255,255,255,0.08)` | Badges, inputs |
| `--text` | `#EEEEE9` | Primary text |
| `--text-secondary` | `#A0A09C` | Body copy |
| `--text-tertiary` | `#6B6B68` | Timestamps, notes |
| `--border` | `rgba(255,255,255,0.12)` | Cards, dividers |
| `--border-subtle` | `rgba(255,255,255,0.06)` | Subtle separators |

---

## 3. Semantic Tokens

### App Theme (Flutter `KineColorTheme`)

Accessed via `KineColors.of(context).*`. Brightness-adaptive.

| Token | Light mode | Dark mode | Usage |
|-------|------------|-----------|-------|
| **surface** | `#FFFFFF` | gray6 `#212221` | Page background |
| **surfaceCard** | gray0 `#EFF1F0` | gray5 `#3F4140` | Card containers |
| **surfaceElevated** | gray1 `#CED4D1` | gray4 `#606361` | Highest elevation |
| **surfaceBorder** | gray1 `#CED4D1` | gray4 `#606361` | Border strokes |
| **textPrimary** | gray6 `#212221` | gray0 `#EFF1F0` | Headings, labels |
| **textSecondary** | gray4 `#606361` | gray1 `#CED4D1` | Body text |
| **textMuted** | gray3 `#838785` | gray3 `#838785` | Tertiary text |
| **textDisabled** | gray2 `#A8ADAA` | gray3 `#838785` | Disabled elements |
| **primary** | blue3 `#3081DD` | blue2 `#75A6F6` | Buttons, navigation, interactive controls |
| **accent** | gold3 `#CC9F00` | gold2 `#FFCF00` | Emphasis, highlights, selected states, brand moments |
| **success** | green2 `#16C47F` | green1 `#1EF09D` | Connected, good |
| **warning** | orange2 `#CC7B00` | orange1 `#FF9D23` | Elevated concern |
| **error** | red3 `#F93827` | red2 `#FA8985` | Critical, danger |

**Primary vs Accent — Platform Rules:**
- **App:** `primary` (blue) = buttons, navigation, interactive controls. `accent` (gold) = emphasis, highlights, selected states, brand identity moments. Blue buttons are a strong UX convention — users expect blue for "do this."
- **Web / marketing:** Gold takes over as the primary CTA color. Blue is reserved for KineSense product identity. No app-style navigation exists to conflict with.

#### Emphasis & Subtle Variants

| Semantic | Emphasis (light) | Subtle (light) | Emphasis (dark) | Subtle (dark) |
|----------|-----------------|----------------|-----------------|----------------|
| Success | green3 `#0F9962` | green0 `#C0FFDA` | green2 `#16C47F` | green6 `#012816` |
| Info | blue4 `#215DA2` | blue0 `#ECF1FE` | blue3 `#3081DD` | blue6 `#061D39` |
| Caution | yellow2 `#A98900` | yellow0 @ 15% | yellow0 `#FFD65A` | yellow6 `#171000` |
| Warning | orange3 `#995B00` | orange0 `#FFD2B8` | orange2 `#CC7B00` | orange6 `#1D0D00` |
| Error | red4 `#BA2516` | red0 `#FEEDEC` | red3 `#F93827` | red6 `#460703` |

### Web Token Mapping

Actual production tokens from `styles.css`, pitch deck, and mock dashboards:

```css
:root {
  --gold:           #FFCF00;
  --gold-hover:     #cc9f00;
  --gold-dim:       rgba(255,207,0,0.15);
  --green:          #16C47F;
  --yellow:         #FFD65A;
  --orange:         #FF9D23;
  --red:            #F93827;

  --product-force:        #16C47F;
  --product-force-subtle: rgba(22,196,127,0.06);
  --product-force-border: rgba(22,196,127,0.2);
}
```

Gold opacity scale (used for subtle backgrounds, borders, grid lines):

| Token | Value | Usage |
|-------|-------|-------|
| `--accent-40` | `rgba(255,207,0,0.4)` | Strong emphasis |
| `--accent-30` | `rgba(255,207,0,0.3)` | Medium emphasis |
| `--accent-15` | `rgba(255,207,0,0.15)` | Subtle tint |
| `--accent-12` | `rgba(255,207,0,0.12)` | Borders |
| `--accent-10` | `rgba(255,207,0,0.1)` | Light tint |
| `--accent-06` | `rgba(255,207,0,0.06)` | Very subtle |
| `--accent-04` | `rgba(255,207,0,0.04)` | Background fill |
| `--accent-03` | `rgba(255,207,0,0.03)` | Grid lines |

---

## 4. Component Tokens

### BLE Connection States (app-only, brightness-independent)

| Token | Flutter const | Color | Usage |
|-------|---------------|-------|-------|
| `bleDisconnected` | gray3 | `#838785` | No active connection |
| `bleScanning` | blue3 | `#3081DD` | Actively scanning |
| `bleConnecting` | yellow0 | `#FFD65A` | Connection attempt |
| `bleConnected` | green2 | `#16C47F` | Successfully connected |
| `bleReady` | green1 | `#1EF09D` | Connected and data-ready |
| `bleReconnecting` | orange1 | `#FF9D23` | Attempting reconnection |
| `bleError` | red3 | `#F93827` | Connection failed / lost |

### BLE Signal Strength

| Level | Flutter const | Color | RSSI |
|-------|---------------|-------|------|
| Excellent | green2 | `#16C47F` | > -60 dBm |
| Good | green3 | `#0F9962` | -60 to -70 dBm |
| Fair | yellow0 | `#FFD65A` | -70 to -80 dBm |
| Weak | red3 | `#F93827` | < -80 dBm |

### Motion Phase Colors (brightness-independent)

| Phase | Flutter const | Color |
|-------|---------------|-------|
| Weighing | gray3 | `#838785` |
| Braking | red3 | `#F93827` |
| Propulsive | green2 | `#16C47F` |
| Flight | blue3 | `#3081DD` |
| Landing | orange1 | `#FF9D23` |
| Unweighting | yellow0 | `#FFD65A` |
| Stationary | gray3 | `#838785` |
| Eccentric | red3 | `#F93827` |
| Concentric | green2 | `#16C47F` |
| Inactive | gray4 | `#606361` |

Phase overlay alpha levels: light 0.10, medium 0.12, strong 0.15.

### Chart Colors

**Metric assignments (one color per metric):**

| Metric | Color | Hex | Rationale |
|--------|-------|-----|-----------|
| MCV (mean velocity) | green2 | `#16C47F` | Primary KPI |
| PCV (peak velocity) | yellow0 | `#FFD65A` | Peak emphasis |
| Displacement | blue3 | `#3081DD` | Data metric |
| Velocity Loss | red3 | `#F93827` | Fatigue alert |
| Live Data | blue3 | `#3081DD` | Real-time |
| ZUPT Data | red3 | `#F93827` | Stationary |
| Left Plate | green2 | `#16C47F` | — |
| Right Plate | orange2 | `#CC7B00` | — |
| Scatter Fill | blue3 | `#3081DD` | — |

**Multi-series palette (Tableau 10):** for charts needing >4 distinct series.

| Series | Hex |
|--------|-----|
| 1 | `#4E79A7` |
| 2 | `#F28E2B` |
| 3 | `#59A14F` |
| 4 | `#E15759` |
| 5 | `#B07AA1` |
| 6 | `#9C755F` |
| 7 | `#FF9DA7` |
| 8 | `#BAB0AC` |
| 9 | `#EDC948` |
| 10 | `#76B7B2` |

### Buttons (app)

| Type | Background (light) | Background (dark) | Foreground |
|------|-------------------|-------------------|------------|
| Primary | blue3 `#3081DD` | blue3 `#3081DD` | white |
| Danger | red3 `#F93827` | red3 `#F93827` | white |
| Secondary | gray0 `#EFF1F0` | gray5 `#3F4140` | gray6 / gray0 |

### Buttons (web / marketing)

| Type | Background | Text | Ratio | Usage |
|------|-----------|------|-------|-------|
| Gold CTA | gold2 `#FFCF00` | `#0A0A0A` | 13.37:1 AAA | Primary web CTAs |
| KineForce CTA | green2 `#16C47F` | `#0A0A0A` | 8.71:1 AAA | Product-specific |
| Neutral | `#0A0A0A` bg | `#EEEEE9` | ~16:1 AAA | Secondary |

### Quality Indicators (L-V Profile)

| Quality | R² Range | Color |
|---------|----------|-------|
| Excellent | > 0.95 | green2 `#16C47F` |
| Good | 0.90–0.95 | yellow0 `#FFD65A` |
| Poor | < 0.90 | red3 `#F93827` |

### Shadows (app)

| Level | Value |
|-------|-------|
| Subtle | `#0D000000` (5% black) |
| Light | `#1A000000` (10% black) |
| Medium | `#33000000` (20% black) |
| Strong | `#66000000` (40% black) |

---

## 5. Product Identity

### Color + Shape Language

Product identity is never communicated by color alone.

| Product | Color | Hex | Shape | Rationale |
|---------|-------|-----|-------|-----------|
| **KineSense** | Brand Blue | `#3081DD` | Circle ◯ | Sensor form factor (round IMU puck) |
| **KineForce** | Brand Green | `#16C47F` | Square □ | Force plate form factor (rectangular plate) |

Token values for web/marketing surfaces:

| Product | Hex | Hover | Subtle (6%) | Border (20%) |
|---------|-----|-------|-------------|--------------|
| KineSense | `#3081DD` | `#2870c4` | `rgba(48,129,221,0.06)` | `rgba(48,129,221,0.2)` |
| KineForce | `#16C47F` | `#0f9962` | `rgba(22,196,127,0.06)` | `rgba(22,196,127,0.2)` |

### Where product colors appear

**Website home page:** Hero card hover borders (blue KineSense, green KineForce), ecosystem table shapes (blue ◯, green □). Everything else: gold accent + monochrome.

**Product pages:** CTA buttons, feature card hover borders, nav active link. KineForce page overrides gold accent → green.

**Documentation:** Device badges with shape icon + text label.

**App:** Product references always paired with product name text.

### Green Dual-Meaning Rules

Green = "success" (semantic) AND "KineForce" (product identity).

| Context | Green means | Rule |
|---------|------------|------|
| Marketing surfaces | KineForce identity | Always paired with "KineForce" text or □ shape |
| App — status indicators | Success / connected / good | Never accompanied by product name |
| App — product references | KineForce identity | Always accompanied by "KineForce" text |
| Documentation | KineForce device badge | Always has text label + □ icon |

### Blue Dual-Meaning Rules

With gold taking over as primary accent, blue's dual-meaning is simplified. Blue now means "KineSense identity" on marketing surfaces and "info / data" in the app. No more collision with primary interaction.

| Context | Blue means | Rule |
|---------|-----------|------|
| Marketing surfaces | KineSense identity | Paired with "KineSense" text or ◯ shape |
| App — data/info | Info semantic, displacement, flight phase | Standard usage |
| App — product references | KineSense identity | Paired with "KineSense" text |

### Colorblind Safety

Product differentiation for ~8% of males with red-green CVD (perceptual distance between blue and green drops 41-52%):
- Always pair product color with text label or shape (◯/□)
- Color is supplementary, never the sole differentiator

---

## 6. Typography

### App (Flutter — `KineTypography`)

**UI font:** System default (SF Pro on iOS/macOS). No explicit font family set.

| Token | Size | Weight | Usage |
|-------|------|--------|-------|
| `largeTitle` | 34 | 700 | Main screen titles |
| `title` | 28 | 600 | Section headers |
| `title2` | 22 | 600 | Subsection headers |
| `title3` | 20 | 500 | Card headers |
| `headline` | 17 | 600 | Emphasized labels |
| `body` | 17 | 400 | Primary body text |
| `bodyEmphasized` | 17 | 500 | Emphasized body |
| `callout` | 16 | 400 | Secondary information |
| `subheadline` | 15 | 400 | Captions, labels |
| `sectionTitle` | 16 | 600 | Section titles (legacy, 28+ files) |
| `subsectionTitle` | 15 | 600 | Subsection titles |
| `footnote` | 13 | 400 | Footnotes |
| `caption1` | 12 | 400 | Small labels |

**Data font:** Monospace with `FontFeature.tabularFigures()` for numeric alignment.

| Token | Size | Weight | Usage |
|-------|------|--------|-------|
| `metricHero` | 72 | 700 | Hero metric display |
| `metricUnit` | 28 | 500 | Unit label paired with hero |
| `heroMetric` | 48 | 700 | Large metric (-0.8 letter-spacing) |
| `metricMedium` | 32 | 600 | Medium numeric readout |
| `metricValue` | 20 | 700 | Standard metric value |
| `metricLabel` | 12 | 400 | Metric label |
| `dataRegular` | 17 | 400 | Standard data text |
| `dataEmphasized` | 17 | 600 | Emphasized data |
| `dataSmall` | 15 | 400 | Compact data |
| `dataCompact` | 13 | 400 | Dense tables |
| `dataCaption` | 12 | 500 | Data annotations |
| `dataAnnotation` | 10 | 600 | Smallest annotation |
| `chartAxisLabel` | 10 | 400 | Chart axis ticks |
| `chartGridLabel` | 9 | 400 | Chart grid lines |
| `chartMarkerLabel` | 11 | 500 | Data point markers |
| `chartLimitLabel` | 8 | 500 | Threshold labels |

### Web / Pitch Deck (Exception)

The marketing website and pitch deck use Google Fonts. This is a platform exception — Oswald's condensed, high-impact style suits marketing contexts; Source Code Pro provides readable monospace for specs and data displays.

| Role | Font | Weights |
|------|------|---------|
| UI / headings | Oswald | 300, 400, 500, 600, 700 |
| Data / metrics | Source Code Pro | 400, 500, 700 |

These fonts are NOT used in the Flutter app. The app uses system fonts.

---

## 7. Spacing & Radius

### Spacing (`KineSpacing`)

| Token | px | Usage |
|-------|-----|-------|
| `xs` | 4 | Tight inner padding, icon gaps |
| `sm` | 8 | Compact padding, small gaps |
| `gap` | 10 | Grid gaps, list item padding |
| `inset` | 12 | Card inset, input fields |
| `md` | 16 | Standard inner padding |
| `lg` | 24 | Section padding, card padding |
| `xl` | 32 | Section gaps |
| `xxl` | 40 | Large section gaps |
| `xxxl` | 48 | Major section dividers |
| `huge` | 56 | Page-level padding |
| `massive` | 64 | Large offsets |

### Border Radius (`KineRadius`)

| Token | px | Usage |
|-------|-----|-------|
| `sm` | 4 | Markers, badges |
| `md` | 8 | Buttons, inputs |
| `lg` | 12 | Standard cards, clip shapes |
| `card` | 14 | Cards, collapsible sections |
| `xl` | 16 | Large containers |
| `pill` | 999 | Fully rounded / pill shapes |

### Web Radius

| Token | px |
|-------|-----|
| `--radius-sm` | 4 |
| `--radius-md` | 6 |
| `--radius-lg` | 8 |

---

## 8. Accessibility (WCAG 2.1 AA)

### On White / Light Backgrounds

| Brand Color | Normal text (≥4.5:1) | Large text (≥3.0:1) | Non-text UI (≥3.0:1) | Background fill |
|---|---|---|---|---|
| Green | green4 `#087147` (6.06:1) | green3 `#0F9962` (3.65:1) | Brand `#16C47F` — FAIL (2.27:1), use green3+ | Brand + dark text |
| Blue | blue4 `#215DA2` (6.66:1) | Brand `#3081DD` (3.95:1) | Brand `#3081DD` (3.95:1 PASS) | blue4 + white text |
| Yellow | yellow3 `#7E6600` (5.74:1) | yellow2 `#A98900` (3.35:1) | yellow2 (3.35:1 PASS) | Brand + dark text |
| Orange | orange3 `#995B00` (5.45:1) | FAIL at brand weight, use orange2+ | orange2 `#CC7B00` (4.17:1 PASS) | Brand + dark text |
| Red | red4 `#BA2516` (6.24:1) | Brand `#F93827` (3.73:1) | Brand `#F93827` (3.73:1 PASS) | Brand + white text |

### On Dark Backgrounds

| Brand Color | On app dark `#212221` | On web dark `#0A0A0A` | WCAG |
|---|---|---|---|
| Gold `#FFCF00` | 10.78:1 | 13.37:1 | AAA |
| Green `#16C47F` | 7.02:1 | 8.71:1 | AAA |
| Blue `#3081DD` | 4.04:1 | 5.01:1 | AA |
| Yellow `#FFD65A` | 11.42:1 | 12.77:1 | AAA |
| Orange `#FF9D23` | 7.68:1 | 8.59:1 | AAA |
| Red `#F93827` | 4.27:1 | 5.30:1 | AA |

### CTA Button Spec

| Button | Background | Text | Ratio | WCAG |
|--------|-----------|------|-------|------|
| Gold CTA (web) | `#FFCF00` | `#0A0A0A` | 13.37:1 | AAA |
| Gold CTA hover | `#cc9f00` | `#0A0A0A` | 8.04:1 | AAA |
| KineForce CTA | Green `#16C47F` | `#0A0A0A` | 8.71:1 | AAA |
| KineSense CTA | blue4 `#215DA2` | white | 4.09:1 | AA large |
| Neutral CTA | `#0A0A0A` | `#EEEEE9` | ~16:1 | AAA |

> **Critical:** White text on Brand Green (`#16C47F`) = 2.27:1 — fails everything. KineForce CTAs always use dark text on green background.

### Text-Safe Variants (for use on white)

| Color | Text-safe hex | Ratio on white |
|-------|---------------|----------------|
| Green | `#087147` (green4) | 6.06:1 AA |
| Blue | `#215DA2` (blue4) | 6.66:1 AA |
| Yellow | `#7E6600` (yellow3) | 5.74:1 AA |
| Orange | `#995B00` (orange3) | 5.45:1 AA |
| Red | `#BA2516` (red4) | 6.24:1 AA |
| Gold | `#806300` | 5.67:1 AA |

---

## 9. Platform Exceptions

| Exception | Platform | What | Rationale |
|-----------|----------|------|-----------|
| Dark background | Web / pitch deck | `#0A0A0A` instead of warm gray `#212221` | Near-black makes gold pop; suits Oswald's bold letterforms |
| Text colors | Web / pitch deck | `#EEEEE9` / `#A0A09C` / `#6B6B68` instead of warm gray scale | Paired with `#0A0A0A` background for optimal contrast |
| UI font | Web / pitch deck | Oswald (Google Fonts) instead of system SF Pro | Condensed, high-impact style suits marketing contexts |
| Data font | Web / pitch deck | Source Code Pro instead of system monospace | Readable mono for specs, metrics, and data displays |
| Border radius | Web | 4/6/8px instead of 4/8/12/14/16 | Tighter radius suits the web's more angular design language |

These exceptions apply to: production website (`website/production/`), pitch decks, and HTML mock prototypes (`kine_mock/prototypes/`). They do NOT apply to the Flutter app.

---

## 10. Logo Colors

The KINE logomark uses gradients distinct from the UI color system. These are identity-only — they do not map to tokens.

| Variant | Gradient | Hex | Files |
|---------|----------|-----|-------|
| Gold (primary) | Left → right | `#FFCF00` → `#FFD300` | `Kine_Icon.svg`, `Kine_Primary.svg` |
| Orange (alternate) | Left → right | `#FF1300` → `#FF7C00` | `Kine_Orange_Icon.svg`, `Kine_Orange_Primary.svg` |

The gold logo gradient shares its start value with Brand Gold (`#FFCF00`). This is intentional — the logo and UI accent are visually linked.

---

## 11. Retired Values

Do not use these going forward.

| Value | Where it was | Why |
|-------|-------------|-----|
| `#DC2626` | old `--accent` | Red-as-action violates principle #4 |
| `#B91C1C` | old `--accent-hover` | Same |
| `#2563EB` | old `--sense-blue` | Wrong blue. Brand blue is `#3081DD` |
| `#FF3D00` | prelaunch `--accent` | Pre-brand orange, not in palette |
| `#FF6D00` | prelaunch `--accent-end` | Same |
| `#ef4444` | `--destructive` | Tailwind red, not brand red. Use `#F93827` |

---

## 12. Open Questions

| Question | Context | Impact |
|----------|---------|--------|
| **BLE scanning color** | Flutter uses blue3 (`#3081DD`). Previous spec recommended yellow. With gold as primary, blue = "info/searching" reads cleanly. Keep blue? | Low urgency — current behavior works |
| **BLE signal good** | Flutter uses green3 (`#0F9962`). Previous spec recommended blue. Green good / green excellent is a weak distinction. | Low urgency — consider blue for differentiation |

### Resolved (v3.0)

| Item | Resolution |
|------|-----------|
| Gold 7-shade scale | Generated: gold0 `#FFE566` through gold6 `#1F1800`. gold3 `#CC9F00` = existing `--gold-hover`. |
| Gold contrast ratios | 10.78:1 on app dark, 13.37:1 on web dark — both AAA |
| Gold text-safe on white | gold4 `#806300` at 5.67:1 AA |
| `design_system.md` retired | Superseded by this document |
| `unified_color_spec_v2.md` retired | Superseded by this document |
| Web Slate migration | Won't fix — `#0A0A0A` stays as documented platform exception |

---

## Quick Reference

```
KINE Brand Colors (v3.0)
──────────────────────────────────────────────
Gold    #FFCF00  ■  Brand accent / emphasis           text: #806300
Green   #16C47F  ■  KineForce / Success             text: #087147
Blue    #3081DD  ■  Primary action / KineSense       text: #215DA2
Yellow  #FFD65A  ■  Caution / Eccentric              text: #7E6600
Orange  #FF9D23  ■  Warning / Connecting             text: #995B00
Red     #F93827  ■  Error / Danger ONLY              text: #BA2516

Severity (cool → warm)
──────────────────────────────────────────────
✓ Green → ─ Blue → ⚠ Yellow → ⚠ Orange → ✕ Red
  good     info     caution    warning    error

Gold is the brand accent, NOT part of the severity scale.
App: Blue = primary (buttons, nav). Gold = accent (emphasis, highlights).
Web: Gold = primary CTA. Blue = KineSense identity only.

Product Identity
──────────────────────────────────────────────
KineSense = Blue #3081DD ◯ circle  (hover #2870c4)
KineForce = Green #16C47F □ square  (hover #0f9962)
→ Never rely on color alone. Always pair with label or shape.

Neutrals
──────────────────────────────────────────────
App:  Warm Gray  #212221 → #EFF1F0
Web:  Near-Black #0A0A0A → #EEEEE9  (exception)

Fonts
──────────────────────────────────────────────
App:  System SF Pro + Monospace (tabular figures)
Web:  Oswald + Source Code Pro  (exception)

Rules
──────────────────────────────────────────────
Never use red for primary actions.
Never use brand-weight green/yellow/orange as text on white.
Always use the text-safe variant for text on light backgrounds.
Gold = brand accent/emphasis. Yellow = caution/status. Never swap.
App buttons = blue (primary). Web CTAs = gold (accent).
White text on green = FAIL. Always dark text on green.
```

---

## Source Files

| Platform | Files |
|----------|-------|
| Flutter app (colors) | `kinesense_app/lib/theme/colors.dart` |
| Flutter app (typography) | `kinesense_app/lib/theme/typography.dart` |
| Flutter app (spacing) | `kinesense_app/lib/theme/spacing.dart` |
| Flutter app (radius) | `kinesense_app/lib/theme/radius.dart` |
| Website | `website/production/styles.css` |
| Mock dashboards | `kine_mock/prototypes/dashboard-*.html` |
| Mock app theme | `kine_mock/lib/theme/colors.dart` |

---

*v3.0 — 2026-03-21. Supersedes unified_color_spec_v2.md and design_system.md.*
