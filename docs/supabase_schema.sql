-- KINE Team Monitoring — Supabase Schema
-- Run this in the Supabase SQL editor to create tables.

-- Teams and roster
CREATE TABLE teams (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name        TEXT NOT NULL,
    created_at  TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE coaches (
    id          UUID PRIMARY KEY REFERENCES auth.users(id),
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
    sensor_id       TEXT,
    hr_max          INT,
    hr_rest         INT,
    zone_config     JSONB DEFAULT '{}',
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
    readiness       TEXT NOT NULL,
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
    hr_zones        JSONB NOT NULL,
    created_at      TIMESTAMPTZ DEFAULT now()
);

-- Indexes
CREATE INDEX idx_wellness_athlete_date ON daily_wellness(athlete_id, date DESC);
CREATE INDEX idx_sessions_athlete_date ON sessions(athlete_id, date DESC);

-- Row Level Security
ALTER TABLE daily_wellness ENABLE ROW LEVEL SECURITY;
ALTER TABLE sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE athletes ENABLE ROW LEVEL SECURITY;
ALTER TABLE teams ENABLE ROW LEVEL SECURITY;
ALTER TABLE coaches ENABLE ROW LEVEL SECURITY;

-- Athletes can read/write only their own data
CREATE POLICY "Athletes own data" ON daily_wellness
    FOR ALL USING (
        athlete_id IN (
            SELECT id FROM athletes WHERE id = auth.uid()
        )
    );

CREATE POLICY "Athletes own sessions" ON sessions
    FOR ALL USING (
        athlete_id IN (
            SELECT id FROM athletes WHERE id = auth.uid()
        )
    );

-- Coaches can read all data for their team
CREATE POLICY "Coaches read team wellness" ON daily_wellness
    FOR SELECT USING (
        athlete_id IN (
            SELECT a.id FROM athletes a
            JOIN coaches c ON c.team_id = a.team_id
            WHERE c.id = auth.uid()
        )
    );

CREATE POLICY "Coaches read team sessions" ON sessions
    FOR SELECT USING (
        athlete_id IN (
            SELECT a.id FROM athletes a
            JOIN coaches c ON c.team_id = a.team_id
            WHERE c.id = auth.uid()
        )
    );
