#!/usr/bin/env bash
# Phase 05 — Pull existing Agentforce definitions from an org (Bot + GenAiPlannerBundle).
# The `Agent` metadata type is not used for Studio-created agents in many orgs; use list + retrieve below.
#
# Usage:
#   ./scripts/shell/phase05_retrieve_agents.sh [ORG_ALIAS]
# Default ORG_ALIAS: SF_TARGET_ORG, else Healthcloud.
#
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
ORG="${SF_TARGET_ORG:-Healthcloud}"
if [[ "${1:-}" != "" ]]; then
  ORG="$1"
fi

cd "$ROOT"

echo "=== Bots in $ORG ==="
sf org list metadata --metadata-type Bot --target-org "$ORG" 2>&1 || true
echo ""
echo "=== GenAiPlannerBundle in $ORG ==="
sf org list metadata --metadata-type GenAiPlannerBundle --target-org "$ORG" 2>&1 || true
echo ""
echo "=== Retrieving Bot:* and GenAiPlannerBundle:* ==="
sf project retrieve start \
  -m "Bot:*" \
  -m "GenAiPlannerBundle:*" \
  -m "GenAiPlugin:*" \
  -m "GenAiFunction:*" \
  -m "GenAiPromptTemplate:*" \
  -o "$ORG" \
  --ignore-conflicts

echo ""
echo "Done. Source under force-app/main/default/bots/ and genAiPlannerBundles/."
