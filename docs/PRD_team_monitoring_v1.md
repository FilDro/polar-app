# KINE Team Monitoring — Product Requirements Document

**v1.0 | March 2026**

---

## 1. Problem

Youth sports coaches manage 15-30 athletes with no objective data on individual recovery state or internal training load. Decisions about who trains hard, who rests, and who is at risk of overtraining are based on subjective observation and athlete self-reporting — both unreliable in competitive team environments where athletes hide fatigue.

Existing solutions (Catapult, Firstbeat) cost $500-2000/sensor, require dedicated hardware infrastructure, and produce dashboards designed for professional sport scientists, not youth coaches.

**We need a system that gives a youth coach three things every day:**

1. Who is ready to train hard today? (morning readiness)
2. How hard did each athlete actually train? (session load)
3. Who is trending toward overtraining? (weekly load vs. recovery balance)

---

## 2. Users

### Athlete (age 14-22)

- Wears Polar Verity Sense on bicep during training
- Opens phone app briefly each morning (1 minute) and after each session (2-3 minutes for sync)
- Does not interpret data — the app tells them their status
- Cares about: speed of the interaction, not being bothered, seeing their own score

### Coach

- Views dashboard on tablet or laptop before and after training
- Manages a squad of 15-30 athletes
- Makes daily decisions: session design, individual load modifications, rest days
- Cares about: team-level overview at a glance, alerts for outliers, weekly trends
- Does NOT want: raw data, complex charts, sports science jargon

### Team Admin (often the coach)

- Onboards athletes, assigns sensors, configures HR zones
- Manages team roster

---

## 3. System Overview

```
MORNING (daily, 1 min)                    TRAINING (per session)
─────────────────────                    ─────────────────────

Polar Verity Sense                       Polar Verity Sense
  (on bicep, supine)                       (on bicep, training)
        │                                        │
        │ BLE (1-min PPI)                        │ Offline recording
        ▼                                        │ HR + IMU to flash
  ┌───────────┐                                  │
  │ Phone App │                                  │ Session ends
  │           │                                  ▼
  │ Record    │                            ┌───────────┐
  │ 1-min PPI │                            │ Phone App │
  │           │                            │           │
  │ Rust core:│                            │ BLE sync  │
  │ lnRMSSD   │                            │ download  │
  │ resting HR│                            │ .REC files│
  │           │                            │           │
  │ Upload    │                            │ Rust core:│
  └─────┬─────┘                            │ HR zones  │
        │                                  │ TRIMP     │
        │ HTTPS                            │ resting HR│
        ▼                                  │           │
  ┌───────────┐                            │ Upload    │
  │   Cloud   │                            └─────┬─────┘
  │           │◄─────────────────────────────────┘
  │ Store     │         HTTPS
  │ daily     │
  │ wellness  │
  │ + session │
  │ summaries │
  └─────┬─────┘
        │
        │ HTTPS (read)
        ▼
  ┌───────────┐
  │ Coach     │
  │ Dashboard │
  │           │
  │ Readiness │
  │ grid      │
  │ Session   │
  │ overview  │
  │ Weekly    │
  │ trends    │
  └───────────┘
```

---

## 4. Core Metrics

### 4.1 Morning Readiness (lnRMSSD)

**Input:** 1 minute of PPI data (R-R intervals in ms), recorded supine or seated.

**Computation:**

```
1. Discard warmup samples (first 25 seconds, error_estimate typically 30+)
2. RMSSD = sqrt(mean(successive_differences²))
3. lnRMSSD = ln(RMSSD)
4. Resting HR = 60000 / mean(RR_intervals)
```

PPI data from Polar Verity Sense at rest is clean — no RR filtering or ectopic
beat removal needed. The sensor's own quality indicators (error_estimate, blocker
flag) are sufficient. Only warmup samples need discarding.

**Baseline & scoring:**

```
rolling_mean = mean(lnRMSSD over last 60 days, excluding today)
rolling_sd = sd(lnRMSSD over last 60 days)
cv_7day = sd(lnRMSSD over last 7 days) / mean(lnRMSSD over last 7 days)

Readiness:
  GREEN  — lnRMSSD >= rolling_mean - 0.5 * rolling_sd
  AMBER  — lnRMSSD >= rolling_mean - 1.5 * rolling_sd
  RED    — lnRMSSD < rolling_mean - 1.5 * rolling_sd

Stability:
  STABLE   — cv_7day < 0.10
  VARIABLE — cv_7day >= 0.10
```

**Output (uploaded to cloud):**

```json
{
  "type": "morning_readiness",
  "athlete_id": "uuid",
  "date": "2026-03-28",
  "timestamp": "2026-03-28T07:12:00Z",
  "resting_hr_bpm": 58,
  "ln_rmssd": 4.21,
  "rmssd_ms": 67.4,
  "rr_mean_ms": 1034,
  "rr_count": 42,
  "readiness": "green",
  "baseline_mean": 4.15,
  "baseline_sd": 0.22,
  "cv_7day": 0.07
}
```

**Minimum data quality:** Recording must have >= 30 valid PPI samples after warmup discard. If fewer, prompt athlete to re-record ("Stay still and try again").

---

### 4.2 Resting Heart Rate Trend

**Input:** Resting HR derived from the same morning PPI recording (see 4.1).

**Computation:**

```
resting_hr = 60000 / mean(valid_RR_intervals)
rolling_mean_hr = mean(resting_hr over last 14 days)
rolling_sd_hr = sd(resting_hr over last 14 days)

Alert:
  ELEVATED — resting_hr > rolling_mean_hr + 5 bpm for 3+ consecutive days
```

**Combined signal with HRV:**

| Resting HR | lnRMSSD | Interpretation | Action |
|------------|---------|----------------|--------|
| Normal | Normal | Recovered | Train as planned |
| Normal | Low | Early fatigue | Monitor, reduce intensity |
| Elevated | Normal | Possible illness onset | Monitor, check symptoms |
| Elevated | Low | Overreaching / illness | Rest day, medical check if persists |

This 2x2 matrix is the primary coaching decision tool.

**Output:** Included in the morning_readiness payload above.

---

### 4.3 HR Zone Distribution

**Input:** HR data from offline recording during training session (1 Hz).

**Prerequisites:** Per-athlete configuration:

```json
{
  "hr_max": 195,
  "hr_rest": 55,
  "zones": {
    "z1": [0.50, 0.60],
    "z2": [0.60, 0.70],
    "z3": [0.70, 0.80],
    "z4": [0.80, 0.90],
    "z5": [0.90, 1.00]
  }
}
```

Zone boundaries are expressed as fraction of HR reserve: `threshold_bpm = hr_rest + fraction * (hr_max - hr_rest)`.

**Computation:**

```
For each HR sample:
  hr_reserve_fraction = (hr - hr_rest) / (hr_max - hr_rest)
  Classify into Z1-Z5 based on configured thresholds
  Accumulate time in each zone (seconds)

below_z1_s = time with hr_reserve_fraction < z1_lower
```

**Output:**

```json
{
  "zone_seconds": {
    "below_z1": 120,
    "z1": 1800,
    "z2": 900,
    "z3": 300,
    "z4": 180,
    "z5": 60
  },
  "zone_percent": {
    "z1": 53.6,
    "z2": 26.8,
    "z3": 8.9,
    "z4": 5.4,
    "z5": 1.8
  },
  "hr_avg": 142,
  "hr_max": 188,
  "hr_min": 72,
  "duration_s": 3360
}
```

---

### 4.4 Session TRIMP (Edwards)

**Input:** HR zone distribution from 4.3.

**Computation:**

```
Edwards TRIMP = (z1_minutes * 1) + (z2_minutes * 2) + (z3_minutes * 3) + (z4_minutes * 4) + (z5_minutes * 5)
```

**Longitudinal metrics (computed client-side in dashboard):**

```
acute_load = sum(TRIMP over last 7 days)
chronic_load = mean(daily_TRIMP over last 28 days) * 7

ACWR:
  If chronic_load > 0:
    acwr = acute_load / chronic_load
  Else:
    acwr = null (insufficient data)

ACWR risk zones:
  LOW        — acwr < 0.8  (undertraining)
  OPTIMAL    — 0.8 <= acwr <= 1.3
  ELEVATED   — 1.3 < acwr <= 1.5
  HIGH       — acwr > 1.5  (spike, injury risk)

monotony = mean(daily_TRIMP over 7 days) / sd(daily_TRIMP over 7 days)
strain = sum(daily_TRIMP over 7 days) * monotony
```

**Output (session):**

```json
{
  "type": "training_session",
  "athlete_id": "uuid",
  "session_id": "uuid",
  "date": "2026-03-28",
  "start_time": "2026-03-28T16:00:00Z",
  "end_time": "2026-03-28T17:26:00Z",
  "duration_s": 5160,
  "trimp_edwards": 187,
  "hr_zones": { ... },
  "hr_avg": 142,
  "hr_max": 188
}
```

---

## 5. Data Model

### Cloud Database

```sql
-- Teams and roster
CREATE TABLE teams (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name        TEXT NOT NULL,
    created_at  TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE coaches (
    id          UUID PRIMARY KEY REFERENCES auth.users(id),  -- Supabase Auth user ID
    team_id     UUID REFERENCES teams(id),
    name        TEXT NOT NULL,
    email       TEXT UNIQUE NOT NULL,
    created_at  TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE athletes (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    team_id         UUID REFERENCES teams(id),
    name            TEXT NOT NULL,
    date_of_birth   DATE,
    sensor_id       TEXT,                    -- Polar device ID (e.g., "110DF930")
    hr_max          INT,                     -- auto: highest observed in first 2 weeks, coach can override
    hr_rest         INT,                     -- auto: lowest 7-day morning reading rolling average
    zone_config     JSONB DEFAULT '{}',      -- custom zone boundaries if overridden
    created_at      TIMESTAMPTZ DEFAULT now()
);

-- Daily wellness (morning readiness)
CREATE TABLE daily_wellness (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    athlete_id      UUID REFERENCES athletes(id),
    date            DATE NOT NULL,
    timestamp       TIMESTAMPTZ NOT NULL,
    resting_hr      INT NOT NULL,
    ln_rmssd        REAL NOT NULL,
    rmssd_ms        REAL NOT NULL,
    rr_count        INT NOT NULL,
    readiness       TEXT NOT NULL,            -- green / amber / red
    baseline_mean   REAL,
    baseline_sd     REAL,
    cv_7day         REAL,
    UNIQUE (athlete_id, date)
);

-- Training sessions
CREATE TABLE sessions (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    athlete_id      UUID REFERENCES athletes(id),
    date            DATE NOT NULL,
    start_time      TIMESTAMPTZ NOT NULL,
    end_time        TIMESTAMPTZ NOT NULL,
    duration_s      INT NOT NULL,
    trimp_edwards   REAL NOT NULL,
    hr_avg          INT,
    hr_max          INT,
    hr_zones        JSONB NOT NULL,           -- zone_seconds + zone_percent
    created_at      TIMESTAMPTZ DEFAULT now()
);

-- Indexes for dashboard queries
CREATE INDEX idx_wellness_athlete_date ON daily_wellness(athlete_id, date DESC);
CREATE INDEX idx_sessions_athlete_date ON sessions(athlete_id, date DESC);
CREATE INDEX idx_wellness_team_date ON daily_wellness(athlete_id, date)
    WHERE athlete_id IN (SELECT id FROM athletes);
```

---

## 6. API Surface

### Auth

Supabase Auth handles registration, login, JWT tokens, and password reset.

```
POST /auth/v1/signup          { email, password, data: { name, role } }
POST /auth/v1/token?grant_type=password   { email, password } → { access_token }
```

Roles (`coach` / `athlete`) stored in `auth.users.raw_user_meta_data`. Row-level security (RLS) policies enforce access:
- Athletes can read/write only their own wellness and session rows
- Coaches can read all data for athletes on their team

### Data Access (Supabase auto-generated REST)

```
# Phone app uploads (athlete role)
POST /rest/v1/daily_wellness    { athlete_id, date, resting_hr, ln_rmssd, ... }
POST /rest/v1/sessions          { athlete_id, date, start_time, end_time, trimp, ... }

# Dashboard reads (coach role)
GET /rest/v1/daily_wellness?date=eq.2026-03-28&select=*,athletes(name)
GET /rest/v1/sessions?date=eq.2026-03-28&select=*,athletes(name)
GET /rest/v1/daily_wellness?athlete_id=eq.uuid&date=gte.2026-03-01&order=date
GET /rest/v1/sessions?athlete_id=eq.uuid&date=gte.2026-03-01&order=date
```

### Derived Metrics (computed client-side in dashboard)

The cloud acts as a **relay and storage layer only** — no server-side computation. ACWR, monotony, strain, and baseline scoring are computed in the dashboard from raw daily_wellness + sessions data. The dataset is small enough (30 athletes x 365 days = ~11K rows/year) to fetch and compute in the browser/app.

```
-- Example: readiness grid query (all athletes, today)
GET /rest/v1/daily_wellness?date=eq.2026-03-28&select=*,athletes(name,hr_max,hr_rest)

-- Example: trend data for one athlete (last 60 days)
GET /rest/v1/daily_wellness?athlete_id=eq.uuid&date=gte.2026-01-28&order=date
GET /rest/v1/sessions?athlete_id=eq.uuid&date=gte.2026-01-28&order=date
```

---

## 7. Athlete App

### Screens

**7.1 Home**
- Shows today's readiness status (large traffic light: green/amber/red)
- lnRMSSD value and trend sparkline (7 days)
- Resting HR value and trend sparkline
- "Record Morning Check" button (if not done today)
- Last session summary card

**7.2 Morning Check**
- Instructions: "Lie down or sit still. Stay relaxed."
- Phase 1 — Connecting + warmup (~25s): "Connecting to sensor..." then "Warming up..." with pulse animation. PPI algorithm needs ~25s before first data arrives.
- Phase 2 — Recording (60s): Countdown timer. Real-time HR display (reassures athlete it's working). Pulsing heart icon.
- On completion: shows readiness result + resting HR
- Baseline phasing:
  - Days 1-6: "Building your baseline (X/7 days)" — show resting HR and lnRMSSD value, no traffic light
  - Days 7-13: traffic light appears with "~" indicator (preliminary)
  - Day 14+: full confident traffic light
- Auto-uploads to Supabase
- If < 30 valid samples after warmup: "Not enough data. Stay still and try again."
- If sensor not found within 10s: "Make sure your sensor is on and nearby."

**7.3 Sync Session**
- "Sync Training Data" button
- Connects to sensor via BLE
- Downloads all .REC files from sensor
- Deletes .REC files from sensor after successful download (frees flash for next session)
- Processes HR data → TRIMP, zones
- Stores IMU files (ACC, GYRO, MAG) on phone for future use
- Uploads session summary to Supabase
- Progress indicator: "Downloading... Processing... Uploading..."
- On completion: shows session summary (TRIMP, duration, HR zones bar chart)
- Option to add session label (e.g., "Match", "Training", "Gym")

**7.4 History**
- Calendar view with dots indicating sessions and morning checks
- Tap day → see that day's readiness + session data
- 7/14/28 day trend view: lnRMSSD line + TRIMP bars

**7.5 Settings**
- Sensor pairing (scan + connect)
- Profile (name, date of birth)
- HR zones display (read-only, set by coach)

### UX Constraints

- Morning check must take < 90 seconds total (open app → result shown)
- Session sync must work unattended after tapping "Sync" (athlete can put phone down)
- No sports science terminology in athlete-facing UI. "Readiness" not "lnRMSSD". "Training load" not "TRIMP".
- Traffic light colors follow KINE design system: green = `#16C47F`, amber/yellow = `#FFD65A`, red = `#F93827`

---

## 8. Coach Dashboard

### 8.1 Morning Readiness Grid

Primary view. Shown before training.

```
┌──────────────────────────────────────────────────────┐
│  Team Readiness — Wednesday 28 Mar 2026              │
│                                                      │
│  ● 18/22 checked in                                  │
│                                                      │
│  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐   │
│  │ Kowal   │ │ Nowak   │ │ Wisniew │ │ Lewand  │   │
│  │   🟢    │ │   🟢    │ │   🟡    │ │   🔴    │   │
│  │ HR: 54  │ │ HR: 61  │ │ HR: 68  │ │ HR: 72  │   │
│  │ 4.31    │ │ 4.18    │ │ 3.89    │ │ 3.42    │   │
│  └─────────┘ └─────────┘ └─────────┘ └─────────┘   │
│  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐   │
│  │ Kamins  │ │ Wojcik  │ │ Zielinsk│ │ Szymans │   │
│  │   🟢    │ │   🟢    │ │   🟢    │ │   ──    │   │
│  │ HR: 58  │ │ HR: 55  │ │ HR: 52  │ │ no data │   │
│  └─────────┘ └─────────┘ └─────────┘ └─────────┘   │
│                                                      │
│  Sorted by: readiness (worst first)                  │
│  ● = tap for 7-day trend                             │
└──────────────────────────────────────────────────────┘
```

- Cards sorted: red first, then amber, then green, then missing
- Each card shows: name, traffic light, resting HR, lnRMSSD value
- Tap card → 7-day sparkline of lnRMSSD + resting HR
- Header shows check-in count (athletes who completed morning recording)
- Athletes with no data shown in gray with "no data" label

### 8.2 Session Overview

Shown after training. One row per athlete who synced.

```
┌──────────────────────────────────────────────────────────────────┐
│  Session — Wednesday 28 Mar 2026, 16:00-17:26                   │
│                                                                  │
│  Name       TRIMP   Avg HR   Max HR   Duration   Zones          │
│  ────────   ─────   ──────   ──────   ────────   ──────────     │
│  Lewand.    243     156      192      86 min     ▓▓▓▓▓▒▒░░░    │
│  Kowalski   187     142      188      86 min     ▓▓▓▓▒▒░░░░    │
│  Nowak      175     138      181      86 min     ▓▓▓▓▒░░░░░    │
│  Wisniews.  162     135      178      82 min     ▓▓▓▒▒░░░░░    │
│  ...                                                             │
│                                                                  │
│  Team avg:  178     141      184      85 min                     │
│                                                                  │
│  ● Sorted by TRIMP (highest first)                               │
│  ● Zones bar: Z1░ Z2▒ Z3▓ Z4█ Z5█                               │
└──────────────────────────────────────────────────────────────────┘
```

- Sorted by TRIMP descending (who worked hardest)
- Zone distribution shown as compact horizontal bar
- Tap row → drill-down with full zone breakdown + HR timeline
- Team averages in footer

### 8.3 Weekly Load Trends

Per-athlete longitudinal view.

```
┌──────────────────────────────────────────────────────┐
│  Load Trends — Kowalski, Jan                         │
│  Last 28 days                                        │
│                                                      │
│  TRIMP (daily)         lnRMSSD (morning)             │
│  ╻                     ╻                              │
│  ║ ║   ║║  ║║ ║        ───────────────────           │
│  ║ ║ ║ ║║  ║║ ║║                    ╲  ╱             │
│  ║ ║ ║ ║║║ ║║ ║║║                    ──              │
│  ╹ ╹ ╹ ╹╹╹ ╹╹ ╹╹╹     ╹                             │
│  Mon-Sun  Mon-Sun       (same period)                │
│                                                      │
│  ACWR: 1.24 (optimal)     Monotony: 1.8             │
│  Acute: 612    Chronic: 494    Strain: 1102          │
│                                                      │
│  Readiness: 🟢🟢🟢🟡🟢🟢🟢 (last 7 days)             │
│  Resting HR: 55 → 57 → 54 → 58 → 56 → 55 → 54     │
└──────────────────────────────────────────────────────┘
```

### 8.4 Team Load Summary

Weekly overview for the whole squad.

```
┌──────────────────────────────────────────────────────────────────┐
│  Team Load — Week of 25 Mar 2026                                │
│                                                                  │
│  Name        Week TRIMP   ACWR    Risk       Readiness  Red Days│
│  ────────    ──────────   ────    ────       ─────────  ────────│
│  Lewandow.  823          1.52    ⚠ HIGH     🟡 amber   2       │
│  Kowalski   612          1.24    ✓ optimal  🟢 green   0       │
│  Nowak      580          1.11    ✓ optimal  🟢 green   0       │
│  Wisniews.  445          0.72    ↓ low      🟢 green   0       │
│  ...                                                             │
│                                                                  │
│  ⚠ 1 athlete in HIGH ACWR zone                                  │
│  ↓ 2 athletes in LOW ACWR zone (undertraining)                  │
└──────────────────────────────────────────────────────────────────┘
```

### 8.5 Alerts

Top-of-dashboard alert banner when conditions trigger:

| Alert | Condition | Priority |
|-------|-----------|----------|
| "Lewandowski: RED readiness 3 consecutive days" | readiness == red for 3+ days | High |
| "Lewandowski: ACWR 1.52 — high injury risk" | acwr > 1.5 | High |
| "Wisniewski: elevated resting HR (+7 bpm for 3 days)" | resting_hr > baseline + 5 for 3+ days | Medium |
| "4 athletes have not checked in today" | missing morning_readiness for today | Low |

---

## 9. Technical Stack

| Layer | Technology | Notes |
|-------|-----------|-------|
| Sensor | Polar Verity Sense (bicep) | Offline HR+IMU recording, BLE PPI streaming for morning check |
| Phone app | Flutter (iOS + macOS) + Rust core via flutter_rust_bridge | polar-rs for BLE, polar-engine for session management |
| BLE communication | polar-rs (Rust, btleplug) | Cross-platform, no Polar SDK dependency |
| Signal processing | Rust (HRV, TRIMP, zone classification) | Validated against NeuroKit2 |
| Data visualization | **kine_charts** (Flutter package) | Line, bar, scatter charts. Shared across phone app and dashboard |
| Design system | **KINE Design System v3.0** (`design.md`) | Brand gold #FFCF00, warm grays, BLE state colors, traffic light palette |
| Cloud backend | **Supabase** (PostgreSQL + Auth + REST/Realtime) | Relay + storage only. No server-side computation. Built-in JWT auth, row-level security, realtime subscriptions for dashboard |
| Coach dashboard | **Flutter Web** with kine_charts | Shared codebase with mobile app, reuses KINE design system and charting |
| Auth | Supabase Auth (JWT, email/password) | Coach and athlete roles via Supabase RLS policies |

### Design & Visualization References

**Design system:** `design.md` defines the KINE visual language — colors, typography, spacing, component patterns, and BLE state indicators. All screens (phone app and dashboard) follow this spec.

**Key design tokens:**
- Brand: gold `#FFCF00`, green `#16C47F`, blue `#3081DD`
- Readiness traffic light: green `#16C47F`, amber `#FFD65A`, red `#F93827`
- BLE states: disconnected (gray), scanning (blue pulse), connected (green), error (red)
- Neutrals: warm grays (`#1A1A1A` → `#F5F5F0`)

**kine_charts** is the shared charting package used for:
- lnRMSSD trend line (7/14/28 day sparklines)
- Resting HR trend line
- TRIMP daily bar charts
- HR zone distribution stacked bars
- ACWR timeline
- Readiness traffic light grid (custom widget, not a chart)

---

## 10. Recording Configuration

### Morning Check

```
BLE PPI streaming (real-time, no offline recording):
  - PPI measurement type 0x03, no SDK mode required
  - ~25 second sensor warmup before first PPI batch arrives
  - Then 60 seconds of data collection
  - Total wall-clock: ~90 seconds (warmup doubles as athlete stabilization)
  - Data arrives as BLE notifications, parsed in real-time by Rust core
  - No PFTP file download needed — avoids entire sync pipeline

  Note: PPI is NOT available in SDK mode. Morning check must run
  in normal mode (SDK mode disabled). This is the default state.
```

### Training Session

```
Offline recording:
  polar-cli record start <id> hr,acc,gyro,mag

  - HR: ~1 Hz, bpm values (used for TRIMP/zones in V1)
  - ACC: 52 Hz, 3-axis accelerometer
  - GYRO: 52 Hz, 3-axis gyroscope
  - MAG: 50 Hz, 3-axis magnetometer
  - IMU data recorded for future use (sprint detection, player load) — not processed in V1
  - No SDK mode (HR LED stays active for concurrent HR + IMU)
  - Storage: ~3.4 MB per 90-min session (measured at rest, higher during activity)
  - Battery impact: moderate (HR LED + IMU sensors active)
```

### Trigger Configuration

```
polar-cli trigger setup <id> system-start acc,gyro,mag,hr

  - Configures trigger mode AND recording types in one command
  - Each type configured with default settings (ACC/GYRO 52Hz, MAG 50Hz, HR)
  - One-time setup per sensor — persists across power cycles
  - Sensor auto-starts HR+ACC+GYRO+MAG recording on every power-on
  - Athlete just puts sensor on — no phone interaction needed for training
  - Phone only needed post-session for sync
```

---

## 11. Sensor Management

### Lifecycle

Each Polar Verity Sense goes through this lifecycle:

```
PROVISION (once per sensor)
  ↓
DAILY USE (morning check + training + sync)
  ↓
OFFSEASON (battery dies, re-provision next season)
```

### Provisioning (one-time per sensor)

Done by coach or admin via the athlete app or CLI:

```
1. Scan for sensor
2. Connect
3. Set device time to host clock
4. Configure trigger: polar-cli trigger setup <id> system-start acc,gyro,mag,hr
5. Bind sensor ID to athlete in Supabase (athletes.sensor_id = "110DF930")
6. Verify with: polar-cli trigger get <id>
```

After provisioning, the sensor auto-records HR+ACC+GYRO+MAG on every power-on. No per-session configuration needed.

### Daily Morning Check

```
1. Athlete puts sensor on bicep → sensor powers on → trigger fires, recording starts
2. Athlete opens app → "Morning Check"
3. App connects via BLE
4. App streams PPI for 90s (coexists with the trigger's offline recording)
5. App computes lnRMSSD + resting HR, uploads to Supabase
6. App disconnects → athlete removes sensor → sensor powers off
7. Small orphan recording (~60 KB for ~90s) remains on flash
```

**PPI and offline recording coexist.** Validated on device: PPI online streaming works while HR+ACC+GYRO+MAG record to flash. The trigger recording during morning check is harmless — the orphan files are cleaned up during the next training sync.

### Training Session

```
1. Athlete puts sensor on bicep → sensor powers on → trigger fires, recording starts
2. Training proceeds (no phone needed)
3. Sensor records HR+ACC+GYRO+MAG to flash for entire session
4. Session ends → athlete opens app → "Sync Training Data"
5. App connects via BLE
6. App downloads ALL .REC files from sensor (training + any morning orphans)
7. App processes HR → TRIMP, zones, session summary
8. App stores IMU .REC files on phone (for future processing)
9. App deletes ALL .REC files from sensor → flash freed
10. App uploads session summary to Supabase
11. App disconnects
```

### Flash Storage Budget

```
Total flash:          14.4 MB
Per 90-min session:   ~3.4 MB (HR+ACC+GYRO+MAG at 52Hz, measured)
Morning orphan:       ~60 KB (HR+ACC+GYRO+MAG for ~90 seconds)
Capacity:             ~4 full sessions before sync required
```

**Sync after every training session** is the operational requirement. With ~3.4 MB/session and 14.4 MB total, there's room for ~4 sessions, but syncing after each session is simpler and prevents data loss.

**Memory limit 2 (300 KB remaining):** If flash fills up, the sensor auto-stops all recordings and disables triggers. The athlete would need to sync to free space before the next session. The app should warn if free space is low after sync.

### Failure Modes

| Scenario | Impact | Mitigation |
|----------|--------|------------|
| Athlete forgets to sync for 4+ sessions | Flash fills up, recordings stop | App notification: "Sync soon — X sessions unsaved" |
| Battery dies mid-session | Partial recording on flash | Session pipeline handles short recordings — TRIMP computed from available HR |
| Sensor not found during morning check | No PPI data | "Make sure your sensor is on" after 10s timeout |
| Trigger not configured | No auto-recording | App checks trigger status on connect, offers to configure if disabled |
| Orphan files accumulate | Wastes ~60 KB each | Cleaned up on every training sync — negligible impact |

### Sensor Status Checks

The app performs these checks on each BLE connection:

```
1. Battery level — warn athlete if < 20%
2. Disk space — warn if < 2 MB free (approaching memory limit 1)
3. Recording status — show if recordings are active
4. Trigger configuration — verify trigger is system-start with correct types
```

---

## 12. Processing Pipeline (Rust Core)

### Morning Check Pipeline

```
Input: Vec<PpiSample> from 90s BLE stream
       PpiSample { hr: u8, ppi_ms: u16, error_estimate: u16, flags: u8 }

Steps:
  1. Discard warmup: drop all samples from first 25 seconds (error_estimate typically 30+)
  2. If valid_count < 30 → return Error("not enough data, stay still and try again")
  3. Compute RMSSD, lnRMSSD, mean_RR, resting_HR
  4. Load athlete baseline from local storage (60-day expanding window)
  5. Compute readiness score (green/amber/red) — skip if < 7 days of data
  6. Update local baseline
  7. Upload to Supabase
  8. Return MorningReadiness struct

PPI data at rest is clean — no RR filtering or artifact rejection needed.
Validated: 90s stream → ~47-81 raw samples → ~39-60 clean samples after warmup discard.
lnRMSSD repeatability: within 0.04 across consecutive measurements.
```

### Session Pipeline

```
Input: Downloaded .REC files from sensor (HR + ACC + GYRO + MAG)

Steps:
  1. Parse HR.REC → extract HR time series (bpm values)
  2. Load athlete config (hr_max, hr_rest, zones)
  3. Classify each HR sample into zone
  4. Accumulate time per zone
  5. Compute Edwards TRIMP
  6. Compute HR stats (avg, max, min)
  7. Upload SessionSummary to Supabase
  8. Delete .REC files from sensor (free flash for next session)
  9. Return SessionSummary struct

IMU files (ACC, GYRO, MAG .REC) are downloaded but not parsed in V1.
Kept on phone local storage for future processing pipeline.
Deleted from sensor after download to free flash space.
```

---

## 13. Out of Scope (V1)

| Feature | Why deferred |
|---------|-------------|
| ACC/GYRO player load processing | IMU data is recorded to flash during training but not processed in V1. Processing pipeline (sprint detection, player load, movement classification) is a separate workstream. |
| Live session monitoring | Requires persistent BLE connection during training. Conflicts with offline recording simplicity. |
| PPG analysis (SpO2, respiratory rate) | Needs channel wavelength validation, calibration work. |
| Sprint / movement detection | Requires ACC, custom algorithms, validation. |
| ML activity classification | Needs labeled training data. |
| Android support | iOS/macOS first. Android later. |
| Athlete self-report (RPE, sleep, mood) | Useful complement but separate feature. |
| Multi-team support | Single team per deployment in V1. |

---

## 14. Success Criteria

| Metric | Target |
|--------|--------|
| Morning check completion | >80% of athletes check in on training days within 4 weeks of launch |
| Morning check duration | < 90 seconds from app open to result shown |
| Session sync duration | < 3 minutes for a 90-min recording |
| Coach dashboard load time | < 2 seconds for readiness grid |
| Readiness score validity | lnRMSSD values within 5% of NeuroKit2 reference on same PPI data |
| TRIMP accuracy | Edwards TRIMP within 1% of manual calculation from same HR data |
| System uptime | 99.5% cloud availability |
| Athlete adoption | >70% of squad using system consistently after 6 weeks |

---

## 15. Resolved Decisions

| # | Question | Decision | Rationale |
|---|----------|----------|-----------|
| 1 | PPI streaming for morning check? | **Yes — BLE real-time streaming.** | PPI streams live via PMD type 0x03 without SDK mode. ~25s warmup then 60s collection. Avoids the entire PFTP download pipeline. Confirmed in Polar SDK docs: "PP interval online streaming supported." |
| 3 | Cloud stack? | **Supabase.** | Hosted PostgreSQL + built-in JWT auth + row-level security + realtime subscriptions. Eliminates need to build auth, API layer, and database hosting from scratch. REST API auto-generated from schema. |
| 4 | Dashboard technology? | **Flutter Web with kine_charts.** | Shares codebase, design system, and charting library with the mobile app. Avoids maintaining two UI frameworks. kine_charts already handles line, bar, and scatter charts needed for trends. |
| 5 | Sensor sharing? | **1:1 sensor-athlete binding. No sharing.** | Each athlete is assigned a sensor by serial ID. Simplifies data pipeline — sensor ID in recording maps directly to athlete. Avoids complex multi-user per-device logic. |
| 6 | Minimum baseline period? | **7 days preliminary, 14 days confident.** | Days 1-6: show raw values, no traffic light ("Building baseline: X/7 days"). Days 7-13: preliminary traffic light with caveat marker. Day 14+: full confident scoring. 60-day expanding window for long-term reference. Based on Plews et al. (2012), WHOOP (4-day start, 30-day full), HRV4Training (7-day rolling + 60-day range). |
| 7 | Supabase pricing? | **Free tier is sufficient for years.** | 30 athletes x 365 days x ~1KB = ~11MB/year. Free tier = 500MB DB = ~45 years of headroom. Pro ($25/mo) only needed if adding file storage or exceeding 50K monthly active users. Non-issue for V1. |
| 8 | What to record during training? | **HR + full IMU (ACC, GYRO, MAG). Skip PPI.** | HR is processed in V1 for TRIMP and zones. IMU (ACC+GYRO+MAG at 52Hz, no SDK mode) is recorded to flash for future sprint/load analysis — not processed in V1 but available when pipeline is ready. PPI skipped during training: quality during high-intensity movement is uncertain (blocker flag), and morning PPI at rest is sufficient for readiness metrics. ~3.4 MB per 90-min session (measured). |
| 9 | PPI streaming validated on device? | **Yes — two successful tests.** | Run 1 (90s): 81 samples, lnRMSSD=5.19, HR=63. Run 2 (60s): 47 samples, lnRMSSD=5.15, HR=59. Repeatability within 0.04 lnRMSSD. ~16s warmup, first 8 samples noisy (error_estimate 30+), remaining samples clean (error_estimate 6-20). 60s window yields ~40 clean samples after warmup discard. |
| 10 | HR max for youth athletes? | **Use highest observed HR from first 2 weeks of training.** | 220-age is unreliable for youth. Auto-detect: track max HR per session, set hr_max = highest seen after 2 weeks. Coach can manually override via dashboard. Resting HR auto-updates from lowest 7-day morning reading average. |

---

## 16. Open Questions

No blocking open questions remain for V1 development.

Future investigation (non-blocking):
- PPI quality during training movement — test with `polar-cli stream <id> ppi -d 90` during exercise to assess blocker flag prevalence and data usability
- HR max auto-detection accuracy — validate after first 2-week onboarding period against manual field test results
