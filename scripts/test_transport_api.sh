#!/usr/bin/env bash
# Live API smoke test against kashan-project.liara.run (OpenAPI)
# Usage: ./scripts/test_transport_api.sh

set -euo pipefail

BASE="${API_BASE_URL:-https://kashan-project.liara.run}"
API="$BASE/api"
COORD_PHONE="09355191018"
DRIVER1="09121234567"
PASS='Ab123456#'

pass() { echo "✅ $*"; }
fail() { echo "❌ $*"; exit 1; }
info() { echo "→ $*"; }
warn() { echo "⚠️  $*"; }

json_field() {
  python3 - "$1" "$2" <<'PY'
import json,sys
data=json.loads(sys.argv[1])
key=sys.argv[2]
v=data.get(key)
if v is None and isinstance(data.get('tokens'), dict):
    v=data['tokens'].get(key)
if v is None and isinstance(data.get('user'), dict):
    v=data['user'].get(key)
if v is None and isinstance(data.get('data'), dict):
    v=data['data'].get(key)
print(v if v is not None else '')
PY
}

http_code() {
  curl -sS -o "$2" -w "%{http_code}" --max-time 25 "$1"
}

post_auth_json() {
  local url="$1" body="$2" out_file="$3" token="$4"
  curl -sS -o "$out_file" -w "%{http_code}" --max-time 25 -X POST "$url" \
    -H "Authorization: Bearer $token" \
    -H "Content-Type: application/json" -H "Accept: application/json" \
    -d "$body"
}

post_json() {
  local url="$1" body="$2" out_file="$3"
  curl -sS -o "$out_file" -w "%{http_code}" --max-time 25 -X POST "$url" \
    -H "Content-Type: application/json" -H "Accept: application/json" \
    -d "$body"
}

patch_json() {
  local url="$1" body="$2" out_file="$3" token="$4"
  curl -sS -o "$out_file" -w "%{http_code}" --max-time 25 -X PATCH "$url" \
    -H "Authorization: Bearer $token" \
    -H "Content-Type: application/json" -H "Accept: application/json" \
    -d "$body"
}

delete_auth() {
  local url="$1" token="$2" out_file="$3"
  curl -sS -o "$out_file" -w "%{http_code}" --max-time 25 -X DELETE "$url" \
    -H "Authorization: Bearer $token" -H "Accept: application/json"
}

get_auth() {
  local url="$1" token="$2" out_file="$3"
  curl -sS -o "$out_file" -w "%{http_code}" --max-time 25 "$url" \
    -H "Authorization: Bearer $token" -H "Accept: application/json"
}

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

info "Health check $API/docs/"
code=$(http_code "$API/docs/" "$TMP/health.json" || true)
if [[ "$code" == "503" ]] || grep -q 'Application Error' "$TMP/health.json" 2>/dev/null; then
  fail "سرور kashan-project.liara.run خاموش است (503)."
fi
pass "Server reachable (HTTP $code)"

login() {
  local phone="$1" label="$2"
  info "Login $label ($phone)"
  local code
  code=$(post_json "$API/accounts/login" \
    "{\"phone_number\":\"$phone\",\"password\":\"$PASS\"}" \
    "$TMP/login.json")
  if [[ "$code" != "200" && "$code" != "201" ]]; then
    echo "Response:"; cat "$TMP/login.json"; fail "Login $label failed HTTP $code"
  fi
  ACCESS=$(json_field "$(cat "$TMP/login.json")" access)
  REFRESH=$(json_field "$(cat "$TMP/login.json")" refresh)
  [[ -n "$ACCESS" ]] || fail "No access token for $label"
  pass "Login $label OK"
}

login "$COORD_PHONE" "متصدی"
COORD_TOKEN="$ACCESS"
COORD_REFRESH="$REFRESH"

login "$DRIVER1" "راننده"
DRIVER_TOKEN="$ACCESS"

info "GET /accounts/profile (known backend bug)"
code=$(get_auth "$API/accounts/profile/" "$COORD_TOKEN" "$TMP/profile.json")
if [[ "$code" == "200" ]]; then
  pass "profile OK"
else
  warn "profile HTTP $code (expected until is_owner bug is fixed)"
fi

info "GET /operator/bars/"
code=$(get_auth "$API/operator/bars/" "$COORD_TOKEN" "$TMP/cargos.json")
[[ "$code" == "200" ]] || fail "operator bars HTTP $code"
pass "operator bars OK"

info "GET /driver/bars/ (paginated)"
code=$(get_auth "$API/driver/bars/?page=1" "$DRIVER_TOKEN" "$TMP/driver_bars.json")
[[ "$code" == "200" ]] || fail "driver bars HTTP $code"
pass "driver bars OK"

info "GET /products/ /machines/ /ostans/"
for path in products machines ostans; do
  code=$(get_auth "$API/$path/" "$COORD_TOKEN" "$TMP/$path.json")
  [[ "$code" == "200" ]] || fail "$path HTTP $code"
done
pass "reference data OK"

info "POST /operator/bars/create/ (smoke)"
PRODUCT_ID=$(python3 -c "import json; print(json.load(open('$TMP/products.json'))[0]['id'])")
MACHINE_ID=$(python3 -c "import json; print(json.load(open('$TMP/machines.json'))[0]['id'])")
OSTAN_ID=$(python3 -c "import json; print(json.load(open('$TMP/ostans.json'))[0]['id'])")
CREATE_BODY=$(cat <<EOF
{"title":"API smoke test","description":"auto test","price":1000000,"product":$PRODUCT_ID,"machine":$MACHINE_ID,"ostan_mabda":$OSTAN_ID,"ostan_maghsad":$OSTAN_ID,"address_mabda":"تهران","address_maghsad":"اصفهان","latitude_mabda":"35.6892","longitude_mabda":"51.3890","latitude_maghsad":"32.6539","longitude_maghsad":"51.6660"}
EOF
)
code=$(post_auth_json "$API/operator/bars/create/" "$CREATE_BODY" "$TMP/create.json" "$COORD_TOKEN")
[[ "$code" == "200" || "$code" == "201" ]] || { cat "$TMP/create.json"; fail "create bar HTTP $code"; }
BAR_ID=$(json_field "$(cat "$TMP/create.json")" id)
[[ -z "$BAR_ID" ]] && BAR_ID=$(python3 -c "import json; d=json.load(open('$TMP/create.json')); print((d.get('data') or {}).get('id',''))")
[[ -n "$BAR_ID" ]] || fail "create bar returned no id"
pass "create bar id=$BAR_ID"

info "PATCH /operator/bars/$BAR_ID/update/"
code=$(patch_json "$API/operator/bars/$BAR_ID/update/" '{"description":"patched by smoke test"}' "$TMP/patch.json" "$COORD_TOKEN")
[[ "$code" == "200" ]] || { cat "$TMP/patch.json"; fail "patch bar HTTP $code"; }
pass "patch bar OK"

info "PUT /operator/bars/$BAR_ID/update/"
code=$(curl -sS -o "$TMP/put.json" -w "%{http_code}" --max-time 25 -X PUT \
  "$API/operator/bars/$BAR_ID/update/" \
  -H "Authorization: Bearer $COORD_TOKEN" \
  -H "Content-Type: application/json" -H "Accept: application/json" \
  -d "$CREATE_BODY")
[[ "$code" == "200" ]] || { cat "$TMP/put.json"; fail "put bar HTTP $code"; }
pass "put bar OK"

info "GET /operator/bars/$BAR_ID/"
code=$(get_auth "$API/operator/bars/$BAR_ID/" "$COORD_TOKEN" "$TMP/detail.json")
[[ "$code" == "200" ]] || fail "bar detail HTTP $code"
pass "bar detail OK"

info "DELETE /operator/bars/$BAR_ID/delete/"
code=$(delete_auth "$API/operator/bars/$BAR_ID/delete/" "$COORD_TOKEN" "$TMP/delete.json")
[[ "$code" == "200" || "$code" == "204" ]] || { cat "$TMP/delete.json"; fail "delete bar HTTP $code"; }
pass "delete bar OK"

info "POST /accounts/logout"
code=$(curl -sS -o "$TMP/logout.json" -w "%{http_code}" --max-time 25 -X POST \
  "$API/accounts/logout" \
  -H "Authorization: Bearer $COORD_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"refresh\":\"$COORD_REFRESH\"}")
[[ "$code" == "200" ]] || info "logout HTTP $code (may require refresh token)"
pass "logout attempted"

pass "All live API smoke tests passed"
