#!/usr/bin/env bash
# Phase 01: verify Health Cloud + Salesforce Scheduler standard objects exist in the org.
# Usage: ./scripts/shell/phase01_verify_standard_objects.sh [TARGET_ORG_ALIAS]
# Example: ./scripts/shell/phase01_verify_standard_objects.sh Healthcloud

set -euo pipefail

TARGET_ORG="${1:-Healthcloud}"
OBJECTS=(
  HealthcareFacility
  HealthcareProvider
  HealthcarePractitionerFacility
  ServiceAppointment
  ServiceResource
  ServiceTerritory
  WorkType
  WorkTypeGroup
)

echo "Target org: ${TARGET_ORG}"
echo ""

FAILED=0
for s in "${OBJECTS[@]}"; do
  if sf sobject describe -s "$s" -o "$TARGET_ORG" --json 2>/dev/null | python3 -c "
import sys, json
d = json.load(sys.stdin)
r = d.get('result') or {}
name = r.get('name')
status = d.get('status', -1)
if status == 0 and name == '${s}':
    print('OK  ', '${s}')
    sys.exit(0)
print('FAIL', '${s}', d.get('message', d))
sys.exit(1)
" 2>/dev/null; then
    :
  else
    FAILED=1
  fi
done

echo ""
if [[ "$FAILED" -ne 0 ]]; then
  echo "One or more objects failed. Enable Health Cloud / Field Service / Scheduler as needed."
  exit 1
fi
echo "All ${#OBJECTS[@]} standard objects are present."
