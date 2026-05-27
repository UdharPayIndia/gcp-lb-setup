#!/bin/bash
# ==============================================================================
# 02_rules.sh — Patch URL Map with RPG path matcher and host rule
# ==============================================================================

set -euo pipefail

PROJECT_ID="${GCP_PROJECT_ID:?Set GCP_PROJECT_ID env var}"
URL_MAP_NAME="stage-lb-as1-udharpay-api"
PATH_MATCHER_NAME="pg-paths"
NEW_HOST="stage-api-pg.rocketpay.co.in"
DEFAULT_BUCKET="stage-bb-as1-default-503"

echo "=== Patching URL Map: $URL_MAP_NAME ==="

# We use add-path-matcher to define a new host and its path mappings.
# Note: The fallback for this host is the default 503 bucket.

gcloud compute url-maps add-path-matcher "$URL_MAP_NAME" \
  --project="$PROJECT_ID" \
  --global \
  --path-matcher-name="$PATH_MATCHER_NAME" \
  --default-backend-bucket="$DEFAULT_BUCKET" \
  --new-hosts="$NEW_HOST" \
  --path-rules="\
/payment-account/*=stage-bs-as1-pg-payment-account,\
/payment-order/*=stage-bs-as1-pg-payment-order,\
/payment-gateway/*=stage-bs-as1-pg-payment-gateway,\
/payment-mandate/*=stage-bs-as1-pg-payment-mandate,\
/payment-instrument/*=stage-bs-as1-pg-payment-instrument" \
  --quiet

echo "=== URL Map Patched ==="
echo "Added host '$NEW_HOST' and routing for /payment-*/ paths"
echo "Verify with: gcloud compute url-maps describe $URL_MAP_NAME --project=$PROJECT_ID --global"
