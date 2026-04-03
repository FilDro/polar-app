# Athlete Testing Build

## Purpose

This build is intentionally scoped to the athlete workflow for user testing.
It is no longer an always-open app with optional sign-in in Settings. Sign-in is
the front door, and the runtime experience is limited to the athlete journey.

## Runtime Flow

### Logged out

- The app starts on a loading route while auth state is synchronized.
- Unauthenticated users are redirected to `/auth`.
- `/auth` exposes two actions only:
  - `Sign in`
  - `Create account`

### Logged in

- Authenticated athlete users are redirected into the athlete shell at `/home`.
- The visible athlete surface is:
  - `Home`
  - `History`
  - `Settings`
- `Morning Check` and `Sync Session` remain full-screen subflows launched from `Home`.

### Hidden paths

- Coach and developer screens are still present in the codebase.
- The testing build does not expose them from Settings or normal navigation.
- Router redirects `/coach/*` and `/dev` back to `/home` for authenticated athletes.

## Auth and Athlete Bootstrap

- `AuthService` is the source of truth for auth initialization and session changes.
- App startup initializes Supabase first, then `AuthService`.
- `AuthService` subscribes to Supabase auth state changes and synchronizes the
  athlete profile before the app is considered ready.
- `AthleteService` binds the local athlete row to `auth.uid()`.
- The app must not use “first athlete in the database” as active identity in the
  testing flow.

## Signup Assumptions

- Self-signup remains enabled.
- Signup is athlete-only.
- Email confirmation is assumed to be disabled in Supabase for testing.
- If Supabase does not immediately return a session after signup, the app signs
  the athlete in explicitly with the submitted credentials.

## Athlete Settings Scope

`Settings` is intentionally reduced to:

- account summary
- profile name
- HR max / HR rest
- sensor pairing
- sign out

Theme switching, coach entry points, and developer tools are intentionally not
part of the testing build UX.

## Data Persistence Rules

- Morning check and session sync remain local-first:
  - save to Drift first
  - attempt cloud sync afterward
- Mandatory sign-in means these flows should not silently degrade into guest mode.
- If the athlete profile is unavailable, the flow should stop and surface the issue.

## `polar-rs` Protocol Alignment

`polar-engine` should use `polar-rs` abstractions wherever they already exist:

- `workflow::*` for offline recording start/stop/status and trigger mode operations
- `listing::list_recordings` for file discovery
- `download_recording` for offline recording downloads
- `PftpClient` for sync lifecycle, file operations, restart, factory reset,
  cleanup, and clock sync
- `parse_pmd_frame` for live PMD stream parsing

### Low-level exception

The per-type trigger settings sequence is still implemented with direct PMD
control-point commands because `polar-rs` does not yet expose a composed helper
for that exact CP `0x09` workflow.

Rule for future edits:

- keep low-level trigger-setting command construction centralized in one helper
- do not duplicate raw PMD CP command assembly across multiple handlers
- migrate to a higher-level `polar-rs` helper if one is added later
