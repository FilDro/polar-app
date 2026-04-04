# Coach Dashboard — End-to-End Implementation Plan

**Goal:** Enable a coach to sign in, see their team's real data, and make decisions from 4 dashboard tabs with proper kine_charts visualizations. Target: 10-15 athletes per team.

**PRD reference:** `docs/PRD_team_monitoring_v1.md`

---

## Current State

| Component | Status | Notes |
|-----------|--------|-------|
| 4 coach screens | Built, working with sample data | ReadinessGrid, SessionOverview, Trends, TeamSummary |
| CoachDataService | Built, queries Supabase | Falls back to sample data on error |
| Coach models | Complete | AthleteReadiness, AthleteSession, AthleteTrend, TeamAthleteRow, TeamAlert |
| Coach shell + routing | Built, but blocked | Router treats `/coach/*` as hidden testing route, redirects coaches to `/auth` |
| Supabase schema + RLS | Done | Coach can SELECT all athlete data on their team |
| kine_charts package | Exists at `../kine_charts/` | 35+ chart types, not yet wired into the app |
| Coach auth flow | Missing | No coach sign-up, no team creation/binding |
| Visualizations | Basic | Container-based bars and text, no real charts |

---

## Work Packages (3 agents, parallelizable)

### Agent 1: Auth & Routing

**Files to modify:**
- `lib/services/auth_service.dart`
- `lib/router.dart`
- `lib/screens/auth_screen.dart`

**Tasks:**

1. **Add `canAccessCoachApp` getter** to `AuthService` (line 29):
   ```dart
   bool get canAccessCoachApp => isAuthenticated && isCoach;
   ```

2. **Fix `resolveAppRedirect`** in `router.dart` (lines 155-183):
   - Remove `/coach` from `isHiddenTestingRoute` (line 164)
   - Add coach routing logic:
     ```
     if authenticated && isCoach:
       if on /coach/* → stay (return null)
       if on /loading or /auth → redirect to /coach/readiness
       if on athlete routes → redirect to /coach/readiness
     if authenticated && isAthlete:
       if on /coach/* → redirect to /home
       (existing athlete logic)
     ```
   - Pass `isCoach` through to `resolveAppRedirect` (add parameter)

3. **Update `appRouter` redirect** (line 44-52) to pass `isCoach`:
   ```dart
   redirect: (context, state) {
     final auth = AuthService.instance;
     return resolveAppRedirect(
       location: state.matchedLocation,
       authReady: auth.ready,
       authenticated: auth.isAuthenticated,
       athleteAllowed: auth.canAccessAthleteApp,
       isCoach: auth.isCoach,
     );
   },
   ```

4. **Add role toggle to AuthScreen** (`lib/screens/auth_screen.dart`):
   - Add a role selector (athlete / coach) on the sign-up form
   - Pass `role: 'coach'` in `signUp()` metadata when coach is selected
   - Sign-in works unchanged (role comes from existing user metadata)

5. **Coach profile creation in `_syncSession`** (`auth_service.dart` line 181):
   - After sign-in with coach role, upsert into `coaches` table in Supabase:
     ```dart
     if (isCoach) {
       await _ensureCoachProfile(session.user);
     }
     ```
   - Create method `_ensureCoachProfile` that checks if coach row exists, creates if not
   - For V1: auto-create a team if coach has no `team_id`

**Test:** Sign up as coach → lands on `/coach/readiness`. Sign in as athlete → lands on `/home`. Each role cannot access the other's routes.

---

### Agent 2: kine_charts Integration + Dashboard Visualizations

**Files to modify:**
- `pubspec.yaml` — add kine_charts dependency
- `lib/screens/coach/readiness_grid_screen.dart`
- `lib/screens/coach/session_overview_screen.dart`
- `lib/screens/coach/trends_screen.dart`
- `lib/screens/coach/team_summary_screen.dart`

**Prerequisite:** Read the kine_charts API at `/Users/filip/Developer/kine_charts/lib/kine_charts.dart` and example app at `/Users/filip/Developer/kine_charts/example/`.

**Tasks:**

1. **Add kine_charts dependency** to `pubspec.yaml`:
   ```yaml
   dependencies:
     kine_charts:
       path: ../kine_charts
   ```

2. **ReadinessGridScreen** — add 7-day sparkline on card tap:
   - Use `KineSparkline` for inline lnRMSSD trend (7 data points)
   - Show in a bottom sheet or expanded card when tapped (currently shows snackbar)
   - Load 7-day history via `CoachDataService.loadAthleteTrend(athleteId, days: 7)`

3. **TrendsScreen** — replace Container bars with real charts:
   - **TRIMP bars:** Use `KineBarChart` with daily TRIMP values (color by intensity)
   - **lnRMSSD line:** Use `KineLineChart` with 7/14/28 day trend, show baseline mean as reference line
   - **Readiness streak:** Keep existing dot row (already clean)
   - **Resting HR:** Use `KineSparkline` instead of arrow-separated text
   - Chart heights: 160px for TRIMP bars, 120px for lnRMSSD line

4. **SessionOverviewScreen** — keep table, enhance ZoneBar:
   - The existing `ZoneBar` widget is already clean and purpose-built
   - Optional: add team-level zone distribution chart (stacked bar)

5. **TeamSummaryScreen** — add ACWR gauge or risk distribution:
   - Use `KineGaugeChart` for team-average ACWR
   - Or simple risk distribution bar (count of LOW/OPTIMAL/ELEVATED/HIGH)

**Design tokens** (from `lib/theme/colors.dart`):
- Readiness: green=KineColors.green2, amber=KineColors.yellow0, red=KineColors.red3
- Zones: Z0=gray, Z1=blue, Z2=green, Z3=yellow, Z4=orange, Z5=red
- Chart background: use `colors.surfaceCard` from theme

**Test:** All 4 tabs render with charts. No overflow on mobile or tablet widths. Charts adapt to theme (light/dark).

---

### Agent 3: Coach-Athlete Team Binding

**Files to create/modify:**
- `lib/services/coach_data_service.dart` — add team management methods
- `lib/screens/coach/team_summary_screen.dart` — add roster management UI
- Possibly: `lib/screens/coach/add_athlete_screen.dart` (new)

**Tasks:**

1. **Team creation** — when a coach signs up with no team:
   - Auto-create a team in Supabase `teams` table
   - Set `coaches.team_id` to the new team ID
   - This can be handled in Agent 1's `_ensureCoachProfile`

2. **Athlete assignment** — coach needs to link athletes to their team:
   - Add method to `CoachDataService`: `assignAthleteToTeam(athleteId, teamId)`
   - Updates `athletes.team_id` in Supabase
   - RLS note: need an INSERT/UPDATE policy on athletes for coaches (or use a Supabase function)

3. **Roster management UI** — on TeamSummaryScreen or separate screen:
   - Show current team roster with athlete names
   - "Add Athlete" flow: enter athlete email or ID to link them
   - "Remove Athlete" option (sets `team_id = null`)

4. **RLS consideration** — coaches currently can only SELECT athletes on their team. To UPDATE `athletes.team_id`, you need either:
   - A Supabase RPC function: `assign_athlete_to_team(athlete_id, team_id)` with `SECURITY DEFINER`
   - Or a coach UPDATE policy on `athletes` for `team_id` column
   - **Recommended:** Supabase RPC function (safer, explicit)

**Supabase SQL needed:**
```sql
-- Allow coaches to assign unaffiliated athletes to their team
CREATE OR REPLACE FUNCTION assign_athlete_to_team(
  p_athlete_id UUID,
  p_team_id UUID
) RETURNS VOID AS $$
BEGIN
  -- Verify caller is a coach on this team
  IF NOT EXISTS (
    SELECT 1 FROM coaches WHERE id = auth.uid() AND team_id = p_team_id
  ) THEN
    RAISE EXCEPTION 'Not authorized';
  END IF;
  
  -- Only assign if athlete has no team (prevent stealing)
  UPDATE athletes SET team_id = p_team_id
  WHERE id = p_athlete_id AND team_id IS NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

**Test:** Coach creates team on first sign-up. Coach adds an athlete by ID. Dashboard shows that athlete's wellness/session data.

---

## Dependency Order

```
Agent 1 (Auth & Routing) ──┐
                           ├──→ Integration test: full flow
Agent 2 (Charts)  ─────────┤
                           │
Agent 3 (Team Binding) ────┘
```

Agents 1, 2, and 3 can work **in parallel** — they touch different files. Integration happens after all three complete.

---

## Key Files Reference

| File | Purpose |
|------|---------|
| `lib/router.dart` | Route definitions + redirect logic |
| `lib/services/auth_service.dart` | Auth state, role checks, session sync |
| `lib/screens/auth_screen.dart` | Sign-in / sign-up UI |
| `lib/services/coach_data_service.dart` | All Supabase queries for coach dashboard |
| `lib/models/coach_models.dart` | Data classes for dashboard |
| `lib/screens/coach/*.dart` | 4 dashboard screens + shell |
| `lib/widgets/zone_bar.dart` | HR zone stacked bar widget |
| `lib/widgets/readiness_indicator.dart` | Traffic light dot/badge |
| `lib/theme/colors.dart` | Design tokens (KineColors) |
| `lib/theme/spacing.dart` | Spacing + radius tokens |
| `/Users/filip/Developer/kine_charts/` | Chart library (path dep) |
| `docs/PRD_team_monitoring_v1.md` | Full product requirements |

---

## Supabase Schema (already deployed)

Tables: `teams`, `coaches`, `athletes`, `daily_wellness`, `sessions`

RLS policies already allow:
- Athletes: full CRUD on own rows
- Coaches: SELECT on their team's athletes, wellness, sessions

Missing: coach ability to UPDATE `athletes.team_id` (see Agent 3 for RPC solution)

---

## Out of Scope

- Real-time updates (Supabase Realtime subscriptions) — pull-to-refresh is sufficient for V1
- Athlete detail drill-down screens — card tap shows snackbar for now
- PDF/CSV export of team reports
- Multi-team support (one team per coach in V1)
