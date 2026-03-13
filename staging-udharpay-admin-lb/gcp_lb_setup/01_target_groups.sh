#!/bin/bash
# ==============================================================================
# 01_target_groups.sh — Create Health Check, Instance Group Named Port &
# Backend Service for staging-udharpay-admin-lb target.
# ==============================================================================
# This LB has a single target group (staging-udharpay-admin-tg).
# AWS port 80 conflicts on the shared GCP VM → reassigned to 8095.
# ==============================================================================

set -euo pipefail

PROJECT_ID="${GCP_PROJECT_ID:?Set GCP_PROJECT_ID env var}"
REGION="asia-south1"
ZONE="${REGION}-a"
IG_NAME="stage-ig-as1-staging-apps-and-services"

echo "=== Step 1: Append named port to Instance Group ==="
# Fetch existing named ports (JSON + jq for correct NAME:PORT formatting)
EXISTING_PORTS=$(gcloud compute instance-groups unmanaged describe "$IG_NAME" \
  --project="$PROJECT_ID" --zone="$ZONE" \
  --format="json" | jq -r '.namedPorts[]? | "\(.name):\(.port)"' | paste -sd "," -)

NEW_PORT="udharpay-admin:8095"

if [ -n "$EXISTING_PORTS" ]; then
  ALL_PORTS="${EXISTING_PORTS},${NEW_PORT}"
else
  ALL_PORTS="${NEW_PORT}"
fi

gcloud compute instance-groups unmanaged set-named-ports "$IG_NAME" \
  --project="$PROJECT_ID" --zone="$ZONE" \
  --named-ports="$ALL_PORTS" \
  --quiet

echo "Named port 'udharpay-admin:8095' added."

echo "=== Step 2: Create Health Check ==="
gcloud compute health-checks create http "stage-hc-as1-udharpay-admin" \
  --project="$PROJECT_ID" \
  --port=8095 \
  --request-path="/admin/login/" \
  --check-interval=30s \
  --timeout=10s \
  --healthy-threshold=2 \
  --unhealthy-threshold=3 \
  --quiet || echo "Health check stage-hc-as1-udharpay-admin already exists"

echo "=== Step 3: Create Backend Service ==="
gcloud compute backend-services create "stage-bs-as1-udharpay-admin" \
  --project="$PROJECT_ID" \
  --protocol=HTTP \
  --health-checks="stage-hc-as1-udharpay-admin" \
  --port-name="udharpay-admin" \
  --global \
  --enable-logging \
  --logging-sample-rate=1 \
  --quiet || echo "Backend service stage-bs-as1-udharpay-admin already exists"

gcloud compute backend-services add-backend "stage-bs-as1-udharpay-admin" \
  --project="$PROJECT_ID" \
  --instance-group="$IG_NAME" \
  --instance-group-zone="$ZONE" \
  --global \
  --quiet || echo "Backend already added to stage-bs-as1-udharpay-admin"

echo "=== Target Group Setup Complete ==="
