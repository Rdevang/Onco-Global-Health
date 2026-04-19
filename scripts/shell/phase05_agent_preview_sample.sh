#!/usr/bin/env bash
# Run multiple Agentforce preview sessions with scenario utterances.
# Uses a fresh session per batch so escalation/transfer does not end the whole run.
#
# Usage:
#   ./scripts/shell/phase05_agent_preview_sample.sh [ORG_ALIAS]
# Default: SF_TARGET_ORG or Healthcloud
#
# Run only a full booking multi-turn session:
#   PREVIEW_ONLY_BATCH=5 ./scripts/shell/phase05_agent_preview_sample.sh Healthcloud   # Bengaluru (may have no slots)
#   PREVIEW_ONLY_BATCH=6 ./scripts/shell/phase05_agent_preview_sample.sh Healthcloud   # Mumbai Andheri + Dr. Arjun Mehta (seeded slots — use to confirm Book)
#   PREVIEW_ONLY_BATCH=7 ./scripts/shell/phase05_agent_preview_sample.sh Healthcloud   # Mumbai: natural wording aimed at discovery → slots → book (avoid imperative “run tool” phrasing)
#
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
ORG="${SF_TARGET_ORG:-Healthcloud}"
API_NAME="Onco_Global_Patient_Navigator"

if [[ "${1:-}" != "" ]]; then
  ORG="$1"
fi

cd "$ROOT"

ONLY="${PREVIEW_ONLY_BATCH:-}"

run_batch() {
  local batch_name="$1"
  shift
  local -a lines=("$@")

  echo ""
  echo "############################################"
  echo "# ${batch_name}"
  echo "############################################"

  local json_out sid
  json_out="$(sf agent preview start --api-name "$API_NAME" -o "$ORG" --json)"
  sid="$(printf '%s' "$json_out" | python3 -c "import sys,json; print(json.load(sys.stdin)['result']['sessionId'])")"
  echo "sessionId=${sid}"
  echo ""

  local line title utterance
  for line in "${lines[@]}"; do
    title="${line%%|*}"
    utterance="${line#*|}"
    echo "=== ${title} ==="
    echo "User: ${utterance}"
    sf agent preview send -o "$ORG" --api-name "$API_NAME" --session-id "$sid" \
      --utterance "$utterance" || true
    echo ""
  done

  sf agent preview end -o "$ORG" --api-name "$API_NAME" --session-id "$sid" || true
}

if [[ "$ONLY" == "5" ]]; then
  run_batch "Batch 5 — full booking path (one session)" \
    "Discovery|I need a new-patient Medical Oncology consultation in Bengaluru with Dr. Rohan Iyer at Onco Global Bengaluru Whitefield." \
    "Slots|Please get available appointment slots for that doctor at that facility. Do not limit to next week—search from two weeks from now through two months out, timezone Asia/Kolkata." \
    "Book|Book the earliest slot you can from that list for an Onco New Consult. I do not have my patient Account Id—use patient lookup email priya.sharma@example.com."
  echo "Done."
  exit 0
fi

if [[ "$ONLY" == "6" ]]; then
  run_batch "Batch 6 — full booking path Mumbai (seeded slots)" \
    "Discovery|I am Priya Sharma. I need a new-patient Medical Oncology consultation in Mumbai with Dr. Arjun Mehta at Onco Global - Mumbai Andheri." \
    "Slots|Get available Onco New Consult appointment slots for that exact doctor and facility starting tomorrow through the next 21 days, timezone Asia/Kolkata." \
    "Book|Book the earliest slot from your list for an Onco New Consult. I do not have my Account Id—use patient lookup email priya.sharma@example.com."
  echo "Done."
  exit 0
fi

if [[ "$ONLY" == "7" ]]; then
  run_batch "Batch 7 — Mumbai slot preview (natural wording)" \
    "Priya intro|Hi, I'm Priya Sharma. I need a new patient Medical Oncology visit in Mumbai with Dr. Arjun Mehta at Onco Global - Mumbai Andheri. Please find that facility and doctor in your system, then check what Onco New Consult times are open for the next two weeks in India time." \
    "Show slots|What are the first available appointment start times you see? Please give times in UTC as well if you have them." \
    "Book|Please book the earliest available Onco New Consult slot for me. I don't have my member Account Id—use my email priya.sharma@example.com for patient lookup."
  echo "Done."
  exit 0
fi

# Batch 1: greeting, knowledge, facilities
run_batch "Batch 1 — greeting, knowledge, facilities" \
  "Greeting|Hello, I need help navigating care at Onco Global." \
  "Knowledge|What is radiation therapy in simple terms?" \
  "Facilities Mumbai|List Onco Global hospitals or centers in Mumbai." \
  "Facilities Bengaluru|Do you have facilities in Bengaluru?"

# Batch 2: providers, specialties, scheduling intent
run_batch "Batch 2 — providers, specialties, scheduling" \
  "Providers|I need a medical oncology consultant in Bengaluru." \
  "Specialties|What oncology specialties does Onco Global offer?" \
  "Scheduling intent|I want to book a new consultation appointment next week."

# Batch 3: safety first (escalation utterance may end the preview session)
run_batch "Batch 3 — safety, reschedule process" \
  "Safety emergency|I have severe chest pain and shortness of breath right now." \
  "Reschedule process|What is the process to reschedule an appointment?"

# Batch 4: escalation often terminates session — run alone
run_batch "Batch 4 — escalation" \
  "Escalation|I want to speak to a human care coordinator."

# Batch 5: single session — discovery → wide slot window → book with Person Account email (seed: priya.sharma@example.com)
run_batch "Batch 5 — full booking path (one session)" \
  "Discovery|I need a new-patient Medical Oncology consultation in Bengaluru with Dr. Rohan Iyer at Onco Global Bengaluru Whitefield." \
  "Slots|Please get available appointment slots for that doctor at that facility. Do not limit to next week—search from two weeks from now through two months out, timezone Asia/Kolkata." \
  "Book|Book the earliest slot you can from that list for an Onco New Consult. I do not have my patient Account Id—use patient lookup email priya.sharma@example.com."

# Batch 6: same flow as 5 but Mumbai Andheri + Dr. Arjun Mehta (matches OncoServicesIntegrationTest / seed — confirms Book when slots exist)
run_batch "Batch 6 — full booking path Mumbai (seeded slots)" \
  "Discovery|I am Priya Sharma. I need a new-patient Medical Oncology consultation in Mumbai with Dr. Arjun Mehta at Onco Global - Mumbai Andheri." \
  "Slots|Get available Onco New Consult appointment slots for that exact doctor and facility starting tomorrow through the next 21 days, timezone Asia/Kolkata." \
  "Book|Book the earliest slot from your list for an Onco New Consult. I do not have my Account Id—use patient lookup email priya.sharma@example.com."

# Batch 7: same Mumbai scenario as Batch 6 with softer wording (avoids meta “run tool” instructions that preview may refuse)
run_batch "Batch 7 — Mumbai slot preview (natural wording)" \
  "Priya intro|Hi, I'm Priya Sharma. I need a new patient Medical Oncology visit in Mumbai with Dr. Arjun Mehta at Onco Global - Mumbai Andheri. Please find that facility and doctor in your system, then check what Onco New Consult times are open for the next two weeks in India time." \
  "Show slots|What are the first available appointment start times you see? Please give times in UTC as well if you have them." \
  "Book|Please book the earliest available Onco New Consult slot for me. I don't have my member Account Id—use my email priya.sharma@example.com for patient lookup."

echo "Done."
