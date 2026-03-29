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
        ▼                                        │ HR + PPI to flash
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
1. Filter PPI: remove intervals < 300ms or > 2000ms (artifact rejection)
2. Remove ectopic beats: if successive difference > 20% of local mean, interpolate
3. RMSSD = sqrt(mean(successive_differences²))
4. lnRMSSD = ln(RMSSD)
5. Resting HR = 60000 / mean(valid_RR_intervals)
```

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
  "rr_count": 58,
  "artifact_percent": 3.4,
  "readiness": "green",
  "baseline_mean": 4.15,
  "baseline_sd": 0.22,
  "cv_7day": 0.07
}
```

**Minimum data quality:** Recording must have >= 50 valid RR intervals after artifact removal. If artifact_percent > 15%, discard and prompt athlete to re-record.

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

**Longitudinal metrics (computed in cloud):**

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
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    team_id     UUID REFERENCES teams(id),
    name        TEXT NOT NULL,
    email       TEXT UNIQUE NOT NULL,
    password    TEXT NOT NULL,
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
    artifact_pct    REAL NOT NULL,
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

ACWR, monotony, strain, and baseline scoring are computed in the dashboard from raw daily_wellness + sessions data. No server-side computation needed — the dataset is small enough (30 athletes x 365 days = ~11K rows/year) to fetch and compute in the browser/app.

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
- If artifact > 15%: "Recording quality too low. Please try again."
- If sensor not found within 10s: "Make sure your sensor is on and nearby."

**7.3 Sync Session**
- "Sync Training Data" button
- Connects to sensor via BLE
- Downloads all .REC files
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
| Sensor | Polar Verity Sense (bicep) | Offline HR+PPI recording, BLE PPI streaming for morning check |
| Phone app | Flutter (iOS + macOS) + Rust core via flutter_rust_bridge | polar-rs for BLE, polar-engine for session management |
| BLE communication | polar-rs (Rust, btleplug) | Cross-platform, no Polar SDK dependency |
| Signal processing | Rust (HRV, TRIMP, zone classification) | Validated against NeuroKit2 |
| Cloud backend | **Supabase** (PostgreSQL + Auth + REST/Realtime) | Hosted PostgreSQL, built-in JWT auth, row-level security, realtime subscriptions for dashboard |
| Coach dashboard | **Flutter Web** with kine_charts | Shared codebase with mobile app, reuses KINE design system and charting |
| Auth | Supabase Auth (JWT, email/password) | Coach and athlete roles via Supabase RLS policies |

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
  polar-cli record start <id> hr

  - HR: ~1 Hz, bpm values
  - No PPI during training for V1 (quality during movement unvalidated)
  - No ACC/GYRO needed for V1 cardiovascular metrics
  - Storage: ~11 KB per 90-min session
  - Battery impact: minimal (HR LED already active)
```

### Trigger Configuration

```
polar-cli trigger set <id> system-start

  - Sensor auto-starts HR+PPI recording on power-on
  - Athlete just puts sensor on — no phone interaction needed for training
  - Phone only needed post-session for sync
```

---

## 11. Processing Pipeline (Rust Core)

### Morning Check Pipeline

```
Input: Vec<PpiSample> from 90s BLE stream
       PpiSample { hr: u8, ppi_ms: u16, error_estimate: u16, flags: u8 }

Steps:
  1. Discard warmup: drop all samples from first 25 seconds (error_estimate typically 30+)
  2. Quality filter: drop samples with error_estimate > 30
  3. Blocker filter: drop samples where flags bit 0 is set (motion detected)
  4. Range filter: drop RR < 300ms or > 2000ms
  5. Ectopic detection: flag if |RR[i] - RR[i-1]| > 0.20 * mean(RR[i-2..i+2])
  6. Interpolate ectopic beats (linear interpolation from neighbors)
  7. If valid_count < 30 → return Error("insufficient data quality")
  8. If artifact_percent > 20% → return Error("too many artifacts, try again")
  9. Compute RMSSD, lnRMSSD, mean_RR, resting_HR
 10. Load athlete baseline from local storage (60-day expanding window)
 11. Compute readiness score (green/amber/red) — skip if < 7 days of data
 12. Update local baseline
 13. Upload to Supabase
 14. Return MorningReadiness struct

Validated: 90s stream → ~47-81 raw samples → ~39-60 clean samples after warmup discard.
lnRMSSD repeatability: within 0.04 across consecutive measurements.
```

### Session Pipeline

```
Input: OfflineRecording (parsed .REC file with HR + PPI frames)

Steps:
  1. Extract HR time series from HR frames (bpm values)
  2. Load athlete config (hr_max, hr_rest, zones)
  3. Classify each HR sample into zone
  4. Accumulate time per zone
  5. Compute Edwards TRIMP
  6. Compute HR stats (avg, max, min)
  7. Return SessionSummary struct
```

---

## 12. Out of Scope (V1)

| Feature | Why deferred |
|---------|-------------|
| ACC/GYRO player load | Valuable but independent workstream. HR-based load is sufficient for V1. |
| Live session monitoring | Requires persistent BLE connection during training. Conflicts with offline recording simplicity. |
| PPG analysis (SpO2, respiratory rate) | Needs channel wavelength validation, calibration work. |
| Sprint / movement detection | Requires ACC, custom algorithms, validation. |
| ML activity classification | Needs labeled training data. |
| Android support | iOS/macOS first. Android later. |
| Athlete self-report (RPE, sleep, mood) | Useful complement but separate feature. |
| Multi-team support | Single team per deployment in V1. |

---

## 13. Success Criteria

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

## 14. Resolved Decisions

| # | Question | Decision | Rationale |
|---|----------|----------|-----------|
| 1 | PPI streaming for morning check? | **Yes — BLE real-time streaming.** | PPI streams live via PMD type 0x03 without SDK mode. ~25s warmup then 60s collection. Avoids the entire PFTP download pipeline. Confirmed in Polar SDK docs: "PP interval online streaming supported." |
| 3 | Cloud stack? | **Supabase.** | Hosted PostgreSQL + built-in JWT auth + row-level security + realtime subscriptions. Eliminates need to build auth, API layer, and database hosting from scratch. REST API auto-generated from schema. |
| 4 | Dashboard technology? | **Flutter Web with kine_charts.** | Shares codebase, design system, and charting library with the mobile app. Avoids maintaining two UI frameworks. kine_charts already handles line, bar, and scatter charts needed for trends. |
| 5 | Sensor sharing? | **1:1 sensor-athlete binding. No sharing.** | Each athlete is assigned a sensor by serial ID. Simplifies data pipeline — sensor ID in recording maps directly to athlete. Avoids complex multi-user per-device logic. |
| 6 | Minimum baseline period? | **7 days preliminary, 14 days confident.** | Days 1-6: show raw values, no traffic light ("Building baseline: X/7 days"). Days 7-13: preliminary traffic light with caveat marker. Day 14+: full confident scoring. 60-day expanding window for long-term reference. Based on Plews et al. (2012), WHOOP (4-day start, 30-day full), HRV4Training (7-day rolling + 60-day range). |

---

| 1b | PPI streaming validated on device? | **Yes — two successful tests.** | Run 1 (90s): 81 samples, lnRMSSD=5.19, HR=63. Run 2 (60s): 47 samples, lnRMSSD=5.15, HR=59. Repeatability within 0.04 lnRMSSD. ~16s warmup, first 8 samples noisy (error_estimate 30+), remaining samples clean (error_estimate 6-20). 60s window yields ~40 clean samples after warmup discard. |
| 2 | HR max for youth athletes? | **Use highest observed HR from first 2 weeks of training.** | 220-age is unreliable for youth. Auto-detect: track max HR per session, set hr_max = highest seen after 2 weeks. Coach can manually override via dashboard. Resting HR auto-updates from lowest 7-day morning reading average. |
| 7 | Supabase pricing? | **Free tier is sufficient for years.** | 30 athletes x 365 days x ~1KB = ~11MB/year. Free tier = 500MB DB = ~45 years of headroom. Pro ($25/mo) only needed if adding file storage or exceeding 50K monthly active users. Non-issue for V1. |
| 8 | PPI during training sessions? | **Record HR only for V1 sessions. Skip PPI during training.** | Session TRIMP and HR zones use HR bpm, not PPI. PPI quality during high-intensity movement is uncertain (blocker flag). Morning PPI at rest is validated and sufficient for readiness metrics. Training PPI can be added in V2 after on-field quality testing. |

---

## 15. Open Questions

No blocking open questions remain for V1 development.

Future investigation (non-blocking):
- PPI quality during training movement — test with `polar-cli stream <id> ppi -d 90` during exercise to assess blocker flag prevalence and data usability
- HR max auto-detection accuracy — validate after first 2-week onboarding period against manual field test results
