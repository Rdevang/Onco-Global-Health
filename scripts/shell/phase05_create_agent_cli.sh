#!/usr/bin/env bash
# Phase 05 — Create Onco Care Concierge via Salesforce CLI (agent spec + agent create).
# Docs: https://developer.salesforce.com/docs/atlas.en-us.sfdx_cli_reference.meta/sfdx_cli_reference/cli_reference_agent_commands_unified.htm
#
# Usage:
#   ./scripts/shell/phase05_create_agent_cli.sh [ORG_ALIAS] [--preview]
#
# Default ORG_ALIAS: SF_TARGET_ORG env, else "Healthcloud".
# --preview: runs sf agent create --preview (writes JSON locally; does not persist in org).
#
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SPEC_REL="specs/onco_care_concierge_agent_spec.yaml"
SPEC="${ROOT}/${SPEC_REL}"
ORG="${SF_TARGET_ORG:-Healthcloud}"
PREVIEW=0

for arg in "$@"; do
  if [[ "$arg" == "--preview" ]]; then
    PREVIEW=1
  elif [[ "$arg" != --* ]]; then
    ORG="$arg"
  fi
done

if [[ ! -f "$SPEC" ]]; then
  echo "Missing agent spec: ${SPEC_REL}" >&2
  exit 1
fi

cd "$ROOT"

CMD=(sf agent create
  --name "Onco Care Concierge"
  --api-name Onco_Care_Concierge
  --spec "$SPEC"
  --target-org "$ORG")

if [[ "$PREVIEW" -eq 1 ]]; then
  CMD+=(--preview)
fi

echo "Running: ${CMD[*]}"
"${CMD[@]}"

if [[ "$PREVIEW" -eq 0 ]]; then
  echo ""
  echo "Open in Agent Builder:"
  echo "  sf org open agent --api-name Onco_Care_Concierge -o $ORG"
  echo ""
  echo "Then wire Apex actions per docs/implementation-plan/phase-05-agentforce/ACTION_CATALOG.md"
fi
