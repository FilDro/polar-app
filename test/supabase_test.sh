#!/usr/bin/env bash
# KINE — Supabase backend integration tests
# Run: bash test/supabase_test.sh

URL="https://mjuarcnwygnpkywtmzlq.supabase.co"
ANON_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1qdWFyY253eWducGt5d3RtemxxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ4NzkyNDMsImV4cCI6MjA5MDQ1NTI0M30.uX9Qu13Zj8bMVWVo8G2hcJxcFRcDGZz8fJR6UeG3ztQ"

TS=$(date +%s)
EMAIL1="kine_test_${TS}a@example.com"
EMAIL2="kine_test_${TS}b@example.com"
PASS="TestKine123!"
TODAY=$(date -u +%Y-%m-%d)
NOW=$(date -u +%Y-%m-%dT%H:%M:%SZ)

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

pass=0
fail=0

ok() {
  echo -e "${GREEN}PASS${NC}  $1"
  pass=$((pass + 1))
}

fail() {
  echo -e "${RED}FAIL${NC}  $1"
  echo "       got: $2"
  fail=$((fail + 1))
}

contains() { [[ "$1" == *"$2"* ]]; }
is_empty_array() { [[ "$1" == "[]" ]]; }

echo ""
echo "KINE Supabase Integration Tests"
echo "================================"
echo "Project: $URL"
echo "Date:    $TODAY"
echo ""

# ── 1. REST endpoint reachable ────────────────────────────────────
HTTP=$(curl -s -o /dev/null -w "%{http_code}" "$URL/auth/v1/settings" \
  -H "apikey: $ANON_KEY")
if [[ "$HTTP" == "200" ]]; then ok "1. REST endpoint reachable"; else fail "1. REST endpoint reachable" "HTTP $HTTP"; fi

# ── 2. Sign up athlete 1 ──────────────────────────────────────────
R=$(curl -s -X POST "$URL/auth/v1/signup" \
  -H "apikey: $ANON_KEY" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$EMAIL1\",\"password\":\"$PASS\",\"data\":{\"name\":\"Test Athlete A\",\"role\":\"athlete\"}}")
if contains "$R" '"id"'; then ok "2. Athlete signup"; else fail "2. Athlete signup" "$R"; fi

# ── 3. Sign in athlete 1 → JWT ────────────────────────────────────
R=$(curl -s -X POST "$URL/auth/v1/token?grant_type=password" \
  -H "apikey: $ANON_KEY" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$EMAIL1\",\"password\":\"$PASS\"}")
JWT1=$(python3 -c "import sys,json; print(json.load(sys.stdin).get('access_token',''))" <<< "$R" 2>/dev/null || echo "")
UID1=$(python3 -c "import sys,json; print(json.load(sys.stdin).get('user',{}).get('id',''))" <<< "$R" 2>/dev/null || echo "")
if [[ -n "$JWT1" && -n "$UID1" ]]; then ok "3. Athlete sign in → JWT"; else fail "3. Athlete sign in → JWT" "$R"; fi

if [[ -z "$JWT1" ]]; then
  echo ""
  echo -e "${RED}Cannot continue without JWT. Check that email confirmation is disabled:${NC}"
  echo "  Supabase → Authentication → Settings → uncheck 'Enable email confirmations'"
  exit 1
fi

# ── 4. Create athlete row (athlete.id = auth.uid) ─────────────────
R=$(curl -s -X POST "$URL/rest/v1/athletes" \
  -H "apikey: $ANON_KEY" \
  -H "Authorization: Bearer $JWT1" \
  -H "Content-Type: application/json" \
  -H "Prefer: return=representation" \
  -d "{\"id\":\"$UID1\",\"name\":\"Test Athlete A\",\"hr_max\":195,\"hr_rest\":55}")
if contains "$R" '"id"'; then ok "4. Create athlete row"; else fail "4. Create athlete row" "$R"; fi

# ── 5. Read own athlete row ───────────────────────────────────────
R=$(curl -s "$URL/rest/v1/athletes?id=eq.$UID1" \
  -H "apikey: $ANON_KEY" \
  -H "Authorization: Bearer $JWT1")
if contains "$R" '"hr_max"'; then ok "5. Read own athlete row"; else fail "5. Read own athlete row" "$R"; fi

# ── 6. Insert wellness entry ──────────────────────────────────────
R=$(curl -s -X POST "$URL/rest/v1/daily_wellness" \
  -H "apikey: $ANON_KEY" \
  -H "Authorization: Bearer $JWT1" \
  -H "Content-Type: application/json" \
  -H "Prefer: return=representation" \
  -d "{
    \"athlete_id\":\"$UID1\",
    \"date\":\"$TODAY\",
    \"timestamp\":\"$NOW\",
    \"resting_hr\":58,
    \"ln_rmssd\":4.21,
    \"rmssd_ms\":67.4,
    \"rr_count\":42,
    \"readiness\":\"green\",
    \"baseline_mean\":4.15,
    \"baseline_sd\":0.22,
    \"cv_7day\":0.07
  }")
if contains "$R" '"ln_rmssd"'; then ok "6. Insert wellness entry"; else fail "6. Insert wellness entry" "$R"; fi

# ── 7. Read back wellness ─────────────────────────────────────────
R=$(curl -s "$URL/rest/v1/daily_wellness?athlete_id=eq.$UID1&date=eq.$TODAY" \
  -H "apikey: $ANON_KEY" \
  -H "Authorization: Bearer $JWT1")
if contains "$R" '4.21'; then ok "7. Read back wellness (lnRMSSD matches)"; else fail "7. Read back wellness" "$R"; fi

# ── 8. Upsert same wellness date (idempotent) ─────────────────────
R=$(curl -s -X POST "$URL/rest/v1/daily_wellness?on_conflict=athlete_id,date" \
  -H "apikey: $ANON_KEY" \
  -H "Authorization: Bearer $JWT1" \
  -H "Content-Type: application/json" \
  -H "Prefer: resolution=merge-duplicates,return=representation" \
  -d "{
    \"athlete_id\":\"$UID1\",
    \"date\":\"$TODAY\",
    \"timestamp\":\"$NOW\",
    \"resting_hr\":59,
    \"ln_rmssd\":4.30,
    \"rmssd_ms\":73.0,
    \"rr_count\":44,
    \"readiness\":\"green\"
  }")
if contains "$R" '4.3'; then ok "8. Upsert wellness (UNIQUE constraint, merge-duplicates)"; else fail "8. Upsert wellness" "$R"; fi

# ── 9. Insert session ─────────────────────────────────────────────
R=$(curl -s -X POST "$URL/rest/v1/sessions" \
  -H "apikey: $ANON_KEY" \
  -H "Authorization: Bearer $JWT1" \
  -H "Content-Type: application/json" \
  -H "Prefer: return=representation" \
  -d "{
    \"athlete_id\":\"$UID1\",
    \"date\":\"$TODAY\",
    \"start_time\":\"$NOW\",
    \"end_time\":\"$NOW\",
    \"duration_s\":3600,
    \"trimp_edwards\":187.0,
    \"hr_avg\":142,
    \"hr_max\":188,
    \"hr_zones\":{\"zone_seconds\":[120,1800,900,300,180,60],\"zone_percent\":[3.6,53.6,26.8,8.9,5.4,1.8]},
    \"label\":\"Training\"
  }")
if contains "$R" '"trimp_edwards"'; then ok "9. Insert session"; else fail "9. Insert session" "$R"; fi

# ── 10. Read back session ─────────────────────────────────────────
R=$(curl -s "$URL/rest/v1/sessions?athlete_id=eq.$UID1&date=eq.$TODAY" \
  -H "apikey: $ANON_KEY" \
  -H "Authorization: Bearer $JWT1")
if contains "$R" '187'; then ok "10. Read back session (TRIMP matches)"; else fail "10. Read back session" "$R"; fi

# ── 11. RLS — athlete 2 cannot read athlete 1's wellness ──────────
R=$(curl -s -X POST "$URL/auth/v1/signup" \
  -H "apikey: $ANON_KEY" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$EMAIL2\",\"password\":\"$PASS\",\"data\":{\"name\":\"Test Athlete B\",\"role\":\"athlete\"}}")

R=$(curl -s -X POST "$URL/auth/v1/token?grant_type=password" \
  -H "apikey: $ANON_KEY" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$EMAIL2\",\"password\":\"$PASS\"}")
JWT2=$(python3 -c "import sys,json; print(json.load(sys.stdin).get('access_token',''))" <<< "$R" 2>/dev/null || echo "")

if [[ -n "$JWT2" ]]; then
  R=$(curl -s "$URL/rest/v1/daily_wellness?athlete_id=eq.$UID1" \
    -H "apikey: $ANON_KEY" \
    -H "Authorization: Bearer $JWT2")
  if is_empty_array "$R"; then ok "11. RLS blocks cross-athlete wellness read"; else fail "11. RLS blocks cross-athlete wellness read" "$R"; fi

  R=$(curl -s "$URL/rest/v1/sessions?athlete_id=eq.$UID1" \
    -H "apikey: $ANON_KEY" \
    -H "Authorization: Bearer $JWT2")
  if is_empty_array "$R"; then ok "12. RLS blocks cross-athlete session read"; else fail "12. RLS blocks cross-athlete session read" "$R"; fi
else
  echo -e "${YELLOW}SKIP${NC}  11. RLS test (athlete 2 signup/signin failed)"
  echo -e "${YELLOW}SKIP${NC}  12. RLS test (athlete 2 signup/signin failed)"
fi

# ── Summary ───────────────────────────────────────────────────────
echo ""
echo "================================"
echo -e "  ${GREEN}$pass passed${NC}   ${RED}$fail failed${NC}"
echo "================================"
echo ""
if [[ $fail -gt 0 ]]; then
  exit 1
fi
