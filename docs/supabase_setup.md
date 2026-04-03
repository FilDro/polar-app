# Supabase Setup — KINE Team Monitoring

## 1. Create Project

1. Go to [supabase.com](https://supabase.com) → New project
2. Name it `kine` (or whatever you like)
3. Set a strong database password — save it somewhere
4. Region: choose closest to you
5. Wait for provisioning (~1 min)

---

## 2. Run Schema

Go to **SQL Editor** (left sidebar) → **New query** → paste and run:

```sql
CREATE TABLE teams (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name       TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE coaches (
    id         UUID PRIMARY KEY REFERENCES auth.users(id),
    team_id    UUID REFERENCES teams(id),
    name       TEXT NOT NULL,
    email      TEXT UNIQUE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE athletes (
    id            UUID PRIMARY KEY,
    team_id       UUID REFERENCES teams(id),
    name          TEXT NOT NULL,
    date_of_birth DATE,
    sensor_id     TEXT,
    hr_max        INT,
    hr_rest       INT,
    zone_config   JSONB DEFAULT '{}',
    created_at    TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE daily_wellness (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    athlete_id    UUID REFERENCES athletes(id),
    date          DATE NOT NULL,
    timestamp     TIMESTAMPTZ NOT NULL,
    resting_hr    INT NOT NULL,
    ln_rmssd      REAL NOT NULL,
    rmssd_ms      REAL NOT NULL,
    rr_count      INT NOT NULL,
    readiness     TEXT NOT NULL,
    baseline_mean REAL,
    baseline_sd   REAL,
    cv_7day       REAL,
    UNIQUE (athlete_id, date)
);

CREATE TABLE sessions (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    athlete_id    UUID REFERENCES athletes(id),
    date          DATE NOT NULL,
    start_time    TIMESTAMPTZ NOT NULL,
    end_time      TIMESTAMPTZ NOT NULL,
    duration_s    INT NOT NULL,
    trimp_edwards REAL NOT NULL,
    hr_avg        INT,
    hr_max        INT,
    hr_zones      JSONB NOT NULL,
    label         TEXT,
    created_at    TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_wellness_athlete_date ON daily_wellness(athlete_id, date DESC);
CREATE INDEX idx_sessions_athlete_date ON sessions(athlete_id, date DESC);
```

---

## 3. Enable Row-Level Security

In the same SQL Editor, run a **second query**:

```sql
-- Enable RLS on all data tables
ALTER TABLE athletes      ENABLE ROW LEVEL SECURITY;
ALTER TABLE daily_wellness ENABLE ROW LEVEL SECURITY;
ALTER TABLE sessions       ENABLE ROW LEVEL SECURITY;

-- Athletes: full access to their own row
-- (athlete.id == auth.uid(), set at signup time)
CREATE POLICY "athletes_own_row" ON athletes
  FOR ALL USING (id = auth.uid());

-- Athletes: full access to their own wellness entries
CREATE POLICY "athlete_own_wellness" ON daily_wellness
  FOR ALL USING (athlete_id = auth.uid());

-- Athletes: full access to their own sessions
CREATE POLICY "athlete_own_sessions" ON sessions
  FOR ALL USING (athlete_id = auth.uid());

-- Coaches: read all athletes on their team
CREATE POLICY "coaches_read_athletes" ON athletes
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM coaches
      WHERE coaches.id = auth.uid()
        AND coaches.team_id = athletes.team_id
    )
  );

-- Coaches: read all wellness for their team's athletes
CREATE POLICY "coaches_read_wellness" ON daily_wellness
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM athletes a
      JOIN coaches c ON c.team_id = a.team_id
      WHERE a.id = daily_wellness.athlete_id
        AND c.id = auth.uid()
    )
  );

-- Coaches: read all sessions for their team's athletes
CREATE POLICY "coaches_read_sessions" ON sessions
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM athletes a
      JOIN coaches c ON c.team_id = a.team_id
      WHERE a.id = sessions.athlete_id
        AND c.id = auth.uid()
    )
  );
```

---

## 4. Get Your Credentials

Go to **Settings** (gear icon, bottom-left) → **API**

Copy these two values:

| Field | Where |
|-------|-------|
| **Project URL** | "Project URL" — looks like `https://abcdefgh.supabase.co` |
| **Anon public key** | Under "Project API keys" → `anon` `public` — long JWT string |

---

## 5. Paste Into App

Open `lib/config/supabase_config.dart` and replace:

```dart
static const String url = 'https://YOUR_PROJECT.supabase.co';
static const String anonKey = 'YOUR_ANON_KEY';
```

with your actual values.

---

## Notes

- `athletes.id` is set to `auth.uid()` at signup — this is how RLS connects a user to their data row. The app creates the athlete row in Supabase immediately after sign-up.
- `coaches.id` is also `auth.uid()` — same pattern.
- Teams are created manually (or via a later admin flow). For V1 testing, create a team row directly in the Table Editor.
- The `label` column on `sessions` was added here (not in the PRD schema) to store Training/Match/Gym/Other.
