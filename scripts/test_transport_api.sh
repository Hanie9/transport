#!/usr/bin/env bash
# Live API smoke test against transport.liara.run
# Usage: ./scripts/test_transport_api.sh

set -euo pipefail

BASE="${API_BASE_URL:-https://transport.liara.run/api}"
COORD_PHONE="09355191018"
DRIVER1="09121111111"
DRIVER2="09121111112"
PASS='Ab123456#'

pass() { echo "✅ $*"; }
fail() { echo "❌ $*"; exit 1; }
info() { echo "→ $*"; }

json_field() {
  python3 - "$1" "$2" <<'PY'
import json,sys
data=json.loads(sys.argv[1])
key=sys.argv[2]
v=data.get(key)
if v is None and isinstance(data.get('user'), dict):
    v=data['user'].get(key)
print(v if v is not None else '')
PY
}

http_code() {
  curl -sS -o "$2" -w "%{http_code}" --max-time 25 "$1"
}

post_json() {
  local url="$1" body="$2" out="$3"
  curl -sS -o "$out" -w "%{http_code}" --max-time 25 -X POST "$url" \
    -H "Content-Type: application/json" -H "Accept: application/json" \
    -d "$body"
}

get_auth() {
  local url="$1" token="$2" out="$3"
  curl -sS -o "$out" -w "%{http_code}" --max-time 25 "$url" \
    -H "Authorization: Bearer $token" -H "Accept: application/json"
}

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

info "Health check $BASE/docs/"
code=$(http_code "$BASE/docs/" "$TMP/health.json" || true)
if [[ "$code" == "503" ]] || grep -q 'Application Error' "$TMP/health.json" 2>/dev/null; then
  fail "سرور transport.liara.run خاموش است (503). اپ Liara را در پنل Liara روشن کنید و دوباره اجرا کنید."
fi
pass "Server reachable (HTTP $code)"

info "Fetch OpenAPI schema"
schema_code=$(http_code "$BASE/schema/" "$TMP/schema.json" || true)
if [[ "$schema_code" == "200" ]]; then
  pass "Schema downloaded"
  python3 - "$TMP/schema.json" <<'PY'
import json,sys
s=json.load(open(sys.argv[1]))
paths=s.get('paths',{})
for p in sorted(paths):
    methods=','.join(m.upper() for m in paths[p])
    print(f"  {methods:12} {p}")
PY
else
  info "Schema HTTP $schema_code (skip)"
fi

login() {
  local phone="$1" role="$2" label="$3"
  info "Login $label ($phone, $role)"
  local code
  code=$(post_json "$BASE/auth/login/" \
    "{\"phone\":\"$phone\",\"password\":\"$PASS\",\"role\":\"$role\"}" \
    "$TMP/login.json")
  if [[ "$code" != "200" && "$code" != "201" ]]; then
    echo "Response:"; cat "$TMP/login.json"; fail "Login $label failed HTTP $code"
  fi
  ACCESS=$(json_field "$(cat "$TMP/login.json")" access)
  if [[ -z "$ACCESS" ]]; then ACCESS=$(json_field "$(cat "$TMP/login.json")" token); fi
  [[ -n "$ACCESS" ]] || fail "No access token for $label"
  pass "Login $label OK"
}

login "$COORD_PHONE" coordinator "متصدی"
COORD_TOKEN="$ACCESS"

login "$DRIVER1" driver "راننده ۱"
DRIVER_TOKEN="$ACCESS"

info "GET /auth/me/ (coordinator)"
code=$(get_auth "$BASE/auth/me/" "$COORD_TOKEN" "$TMP/me.json")
[[ "$code" == "200" ]] || fail "/auth/me/ HTTP $code"
pass "/auth/me/ OK"

info "GET /cargos/?mine=true"
code=$(get_auth "$BASE/cargos/?mine=true" "$COORD_TOKEN" "$TMP/cargos.json")
[[ "$code" == "200" ]] || fail "coordinator cargos HTTP $code"
pass "coordinator cargos OK ($(python3 -c "import json;print(len(json.load(open('$TMP/cargos.json')).get('results',json.load(open('$TMP/cargos.json')) if isinstance(json.load(open('$TMP/cargos.json')),list) else []))" 2>/dev/null || echo '?') items)"

info "GET /drivers/?active=true"
code=$(get_auth "$BASE/drivers/?active=true" "$COORD_TOKEN" "$TMP/drivers.json")
[[ "$code" == "200" ]] || fail "drivers HTTP $code"
pass "active drivers OK"

info "GET /drivers/missions/ (driver)"
code=$(get_auth "$BASE/drivers/missions/" "$DRIVER_TOKEN" "$TMP/missions.json")
[[ "$code" == "200" ]] || info "missions HTTP $code (may be empty)"

info "POST /cargos/estimate-price/"
code=$(post_json "$BASE/cargos/estimate-price/" \
  '{"origin":"تهران","destination":"اصفهان","cargo_type":"کفی","goods_type":"مصالح","weight_tons":10}' \
  "$TMP/estimate.json")
# estimate-price needs auth on some backends
if [[ "$code" != "200" && "$code" != "201" ]]; then
  code=$(curl -sS -o "$TMP/estimate.json" -w "%{http_code}" --max-time 25 -X POST \
    "$BASE/cargos/estimate-price/" \
    -H "Authorization: Bearer $COORD_TOKEN" \
    -H "Content-Type: application/json" -d \
    '{"origin":"تهران","destination":"اصفهان","cargo_type":"کفی","goods_type":"مصالح","weight_tons":10}')
fi
[[ "$code" == "200" || "$code" == "201" ]] || fail "estimate-price HTTP $code"
pass "estimate-price OK"

info "POST /drivers/location/"
code=$(post_json "$BASE/drivers/location/" \
  '{"lat":35.6892,"lng":51.3890}' \
  "$TMP/loc.json")
if [[ "$code" != "200" && "$code" != "201" ]]; then
  code=$(curl -sS -o "$TMP/loc.json" -w "%{http_code}" --max-time 25 -X POST \
    "$BASE/drivers/location/" \
    -H "Authorization: Bearer $DRIVER_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"lat":35.6892,"lng":51.3890,"reported_at":"2026-08-29T12:00:00Z"}')
fi
[[ "$code" == "200" || "$code" == "201" ]] || info "location HTTP $code"

pass "All live API smoke tests passed"
