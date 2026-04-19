#!/usr/bin/env bash
# Phase 03: deploy data category group (if changed) and publish Knowledge articles.
# Usage: ./scripts/shell/phase03_publish_knowledge.sh [TARGET_ORG_ALIAS]
# Example: ./scripts/shell/phase03_publish_knowledge.sh Healthcloud

set -euo pipefail

TARGET_ORG="${1:-Healthcloud}"
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

echo "Target org: ${TARGET_ORG}"
echo ""
echo "--- Deploy DataCategoryGroup (Onco_Care) ---"
sf project deploy start --source-dir "${ROOT}/force-app/main/default/dataCategoryGroups" --target-org "${TARGET_ORG}"
echo ""
echo "--- Publish articles (Apex) ---"
sf apex run --file "${ROOT}/scripts/apex/publish_knowledge.apex" --target-org "${TARGET_ORG}"
echo ""
echo "--- Online KA article count ---"
sf data query -q "SELECT COUNT() FROM Knowledge__kav WHERE PublishStatus = 'Online' AND UrlName LIKE 'ka-%'" -o "${TARGET_ORG}" --json \
  | python3 -c "import sys,json;d=json.load(sys.stdin);print('Count:', d['result']['totalSize'])"
