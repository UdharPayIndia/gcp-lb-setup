#!/bin/bash
# ==============================================================================
# 02_rules.sh — Patch URL Map with admin host rule
# ==============================================================================
# The admin LB has NO path-based rules — all traffic on the host goes
# to staging-udharpay-admin-tg. We model this as a host rule where the
# pathMatcher's defaultService IS the admin backend service.
# ==============================================================================

set -euo pipefail

PROJECT_ID="${GCP_PROJECT_ID:?Set GCP_PROJECT_ID env var}"
URL_MAP_NAME="stage-lb-as1-udharpay-api"
PATH_MATCHER_NAME="admin-paths"
NEW_HOST="gcp-admin-staging.udharpay.com"
BACKEND_SERVICE="stage-bs-as1-udharpay-admin"

echo "=== Patching URL Map: $URL_MAP_NAME ==="
# Since ALL traffic for this host goes to the same backend,
# we just set the defaultService of the path matcher to the admin backend.
# No path-rules needed.

gcloud compute url-maps add-path-matcher "$URL_MAP_NAME" \
  --project="$PROJECT_ID" \
  --global \
  --path-matcher-name="$PATH_MATCHER_NAME" \
  --default-service="$BACKEND_SERVICE" \
  --new-hosts="$NEW_HOST" \
  --quiet

echo "=== URL Map Patched ==="
echo "Added host '$NEW_HOST' → all traffic → $BACKEND_SERVICE"
echo "Verify with: gcloud compute url-maps describe $URL_MAP_NAME --project=$PROJECT_ID --global"
