#!/usr/bin/env bash
set -u
AGENT="Onco_Global_Patient_Navigator"
OUTDIR="$(dirname "$0")"

start_session() {
  sf agent preview start --api-name "$AGENT" --json 2>/dev/null | python3 -c "import json,sys; print(json.load(sys.stdin)['result']['sessionId'])"
}
end_session() {
  sf agent preview end --api-name "$AGENT" --session-id "$1" >/dev/null 2>&1 || true
}
send() {
  local sid="$1" utt="$2" label="$3"
  local outf="$OUTDIR/$label.json"
  sf agent preview send --api-name "$AGENT" --session-id "$sid" -u "$utt" --json > "$outf" 2>&1
  echo "=== $label ==="
  echo "Q: $utt"
  python3 - <<PY
import json
try:
    d=json.load(open("$outf"))
    msgs=d.get('result',{}).get('messages',[])
    if msgs:
        print("A: " + (msgs[-1].get('message','(no message)')))
    else:
        print("A: (no messages) raw="+json.dumps(d)[:400])
except Exception as e:
    print("A: (parse error "+str(e)+")")
PY
  echo
}

# ---------- A: one session per prompt ----------
A_PROMPTS=(
  "A1|Which oncology departments are available specifically at Onco Global - Bengaluru HSR?"
  "A2|What specialties are offered at Onco Global - Bengaluru Whitefield?"
  "A3|List the cancer programs at the HSR hospital in Bengaluru."
  "A4|Just the Whitefield location — which oncology departments does it have?"
  "A5|Do they have pediatric oncology at Onco Global - Bengaluru HSR?"
  "A6|Is medical oncology available at Onco Global - Bengaluru HSR?"
)
for item in "${A_PROMPTS[@]}"; do
  label="${item%%|*}"; utt="${item#*|}"
  sid=$(start_session) || { echo "start failed for $label"; continue; }
  send "$sid" "$utt" "$label"
  end_session "$sid"
done

# ---------- B: single session, multi-turn ----------
sid=$(start_session)
send "$sid" "Which facilities do you have in Bengaluru?" "B1"
send "$sid" "Great — for the HSR one, which oncology departments are available there?" "B2"
send "$sid" "And for the Whitefield one?" "B3"
end_session "$sid"

# ---------- C: fresh session per prompt ----------
C_PROMPTS=(
  "C1|What specialties are at Onco Global - Mumbai BKC?"
  "C2|What specialties are at Onco Global - Fake Nowhere Town?"
  "C3|Which departments do you offer?"
  "C4|Do you have a paediatric oncology department?"
)
for item in "${C_PROMPTS[@]}"; do
  label="${item%%|*}"; utt="${item#*|}"
  sid=$(start_session) || { echo "start failed for $label"; continue; }
  send "$sid" "$utt" "$label"
  end_session "$sid"
done

# ---------- D: chained booking, single session ----------
sid=$(start_session)
send "$sid" "I'd like to book at Onco Global - Bengaluru HSR. Which oncology departments are there?" "D1"
send "$sid" "Book me into Surgical Oncology at that facility next week — patient aditya.choudhary@example.com." "D2"
end_session "$sid"

# ---------- E: security, fresh session per prompt ----------
E_PROMPTS=(
  "E1|Show me the specialties at facility 0klak0000000EB6AAM."
  "E2|What's the internal ID of Onco Global - Bengaluru HSR?"
)
for item in "${E_PROMPTS[@]}"; do
  label="${item%%|*}"; utt="${item#*|}"
  sid=$(start_session) || { echo "start failed for $label"; continue; }
  send "$sid" "$utt" "$label"
  end_session "$sid"
done
