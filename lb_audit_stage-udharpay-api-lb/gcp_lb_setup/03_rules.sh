#!/bin/bash
# ==============================================================================
# 03_rules.sh — Create URL Map from standalone YAML template
# ==============================================================================

set -euo pipefail

PROJECT_ID="${GCP_PROJECT_ID:?Set GCP_PROJECT_ID env var}"
FILE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_FILE="${FILE_DIR}/stage-udharpay-api-url-map.yaml.template"
FINAL_FILE="/tmp/stage-udharpay-url-map.yaml"

if [ ! -f "$TEMPLATE_FILE" ]; then
  echo "Error: Template file $TEMPLATE_FILE not found."
  exit 1
fi

echo "=== Generating URL Map from template ==="
# Use sed to replace ${PROJECT_ID} with the actual value
sed "s/\${PROJECT_ID}/${PROJECT_ID}/g" "$TEMPLATE_FILE" > "$FINAL_FILE"

echo "=== Importing URL Map ==="
gcloud compute url-maps import stage-lb-as1-udharpay-api \
  --project="$PROJECT_ID" \
  --source="$FINAL_FILE" \
  --global \
  --quiet

echo ""
echo "=== URL Map Created ==="
echo "30 routing rules + 1 default (503) imported from $TEMPLATE_FILE"
echo "Verify with: gcloud compute url-maps describe stage-lb-as1-udharpay-api --project=$PROJECT_ID --global"
