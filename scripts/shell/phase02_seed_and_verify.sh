#!/usr/bin/env bash
# Phase 02: seed the Onco Global data model and run verification counts.
# Usage: ./scripts/shell/phase02_seed_and_verify.sh [TARGET_ORG_ALIAS]
# Example: ./scripts/shell/phase02_seed_and_verify.sh Healthcloud

set -euo pipefail

TARGET_ORG="${1:-Healthcloud}"
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

echo "Target org: ${TARGET_ORG}"
echo ""
echo "--- Running seed script ---"
sf apex run --file "${ROOT}/scripts/apex/seed_onco_data.apex" --target-org "${TARGET_ORG}"
echo ""
echo "--- Verification counts ---"

QUERIES=(
  "Facility Accounts|SELECT COUNT() FROM Account WHERE Name LIKE 'Onco Global - %'"
  "HealthcareFacility|SELECT COUNT() FROM HealthcareFacility WHERE Name LIKE 'Onco Global - %'"
  "HealthcareProvider|SELECT COUNT() FROM HealthcareProvider WHERE Name LIKE 'Dr. %'"
  "HealthcarePractitionerFacility|SELECT COUNT() FROM HealthcarePractitionerFacility WHERE HealthcareProvider.Name LIKE 'Dr. %'"
  "OperatingHours|SELECT COUNT() FROM OperatingHours WHERE Name LIKE 'Onco OH - %'"
  "TimeSlot|SELECT COUNT() FROM TimeSlot WHERE OperatingHours.Name LIKE 'Onco OH - %'"
  "ServiceTerritory|SELECT COUNT() FROM ServiceTerritory WHERE Name LIKE 'Onco Territory - %'"
  "ServiceResource|SELECT COUNT() FROM ServiceResource WHERE Name LIKE 'Dr. %'"
  "ServiceTerritoryMember|SELECT COUNT() FROM ServiceTerritoryMember WHERE ServiceResource.Name LIKE 'Dr. %'"
  "WorkTypeGroup|SELECT COUNT() FROM WorkTypeGroup WHERE Name LIKE 'Onco %'"
  "WorkType|SELECT COUNT() FROM WorkType WHERE Name LIKE 'Onco %'"
  "ServiceAppointment (seed)|SELECT COUNT() FROM ServiceAppointment WHERE Subject LIKE 'Onco seed%'"
)

for row in "${QUERIES[@]}"; do
  label="${row%%|*}"
  q="${row#*|}"
  count=$(sf data query -q "$q" -o "$TARGET_ORG" --json 2>/dev/null \
    | python3 -c "import sys,json;d=json.load(sys.stdin);print(d['result']['totalSize'])" 2>/dev/null \
    || echo "ERR")
  printf "%-30s %s\n" "${label}:" "${count}"
done
