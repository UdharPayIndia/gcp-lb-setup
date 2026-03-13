#!/bin/bash
# ==============================================================================
# 01_target_groups.sh — Create Health Checks, Instance Group & Backend Services
# for stage-rpg-lb targets.
# ==============================================================================

set -euo pipefail

PROJECT_ID="${GCP_PROJECT_ID:?Set GCP_PROJECT_ID env var}"
REGION="asia-south1"
ZONE="${REGION}-a"
IG_NAME="stage-ig-as1-staging-apps-and-services"

echo "=== Step 1: Append named ports to Instance Group ==="
# Fetch existing named ports since set-named-ports OVERWRITES
EXISTING_PORTS=$(gcloud compute instance-groups unmanaged describe "$IG_NAME" \
  --project="$PROJECT_ID" --zone="$ZONE" \
  --format="json" | jq -r '.namedPorts[]? | "\(.name):\(.port)"' | paste -sd "," -)

NEW_PORTS="pg-payment-account:8101,pg-payment-order:8102,pg-payment-gateway:8103,pg-payment-mandate:8104,pg-payment-instrument:8105"

if [ -n "$EXISTING_PORTS" ]; then
  ALL_PORTS="${EXISTING_PORTS},${NEW_PORTS}"
else
  ALL_PORTS="${NEW_PORTS}"
fi

gcloud compute instance-groups unmanaged set-named-ports "$IG_NAME" \
  --project="$PROJECT_ID" --zone="$ZONE" \
  --named-ports="$ALL_PORTS" \
  --quiet

echo "Named ports updated."

echo "=== Step 2: Create Health Checks ==="
create_hc() {
  local HC_NAME=$1 REQUEST_PATH=$2 PORT=$3
  echo "  Health check: $HC_NAME → $REQUEST_PATH :$PORT"
  gcloud compute health-checks create http "$HC_NAME" \
    --project="$PROJECT_ID" \
    --port="$PORT" \
    --request-path="$REQUEST_PATH" \
    --check-interval=30s \
    --timeout=10s \
    --healthy-threshold=2 \
    --unhealthy-threshold=3 \
    --quiet || echo "Health check $HC_NAME already exists"
}

# New health checks on unique ports
create_hc "stage-hc-as1-pg-payment-account"     "/payment-account/actuator/health" 8101
create_hc "stage-hc-as1-pg-payment-order"       "/payment-order/actuator/health" 8102
create_hc "stage-hc-as1-pg-payment-gateway"     "/payment-gateway/actuator/health" 8103
create_hc "stage-hc-as1-pg-payment-mandate"     "/payment-mandate/actuator/health" 8104
create_hc "stage-hc-as1-pg-payment-instrument"  "/payment-instrument/actuator/health" 8105

echo "=== Step 3: Create Backend Services ==="
create_bs() {
  local BS_NAME=$1 HC_NAME=$2 NAMED_PORT=$3
  echo "  Backend service: $BS_NAME (port=$NAMED_PORT)"
  gcloud compute backend-services create "$BS_NAME" \
    --project="$PROJECT_ID" \
    --protocol=HTTP \
    --health-checks="$HC_NAME" \
    --port-name="$NAMED_PORT" \
    --global \
    --enable-logging \
    --logging-sample-rate=1 \
    --quiet || echo "Backend service $BS_NAME already exists"
    
  gcloud compute backend-services add-backend "$BS_NAME" \
    --project="$PROJECT_ID" \
    --instance-group="$IG_NAME" \
    --instance-group-zone="$ZONE" \
    --global \
    --quiet || echo "Backend already added to $BS_NAME"
}

create_bs "stage-bs-as1-pg-payment-account"     "stage-hc-as1-pg-payment-account"     "pg-payment-account"
create_bs "stage-bs-as1-pg-payment-order"       "stage-hc-as1-pg-payment-order"       "pg-payment-order"
create_bs "stage-bs-as1-pg-payment-gateway"     "stage-hc-as1-pg-payment-gateway"     "pg-payment-gateway"
create_bs "stage-bs-as1-pg-payment-mandate"     "stage-hc-as1-pg-payment-mandate"     "pg-payment-mandate"
create_bs "stage-bs-as1-pg-payment-instrument"  "stage-hc-as1-pg-payment-instrument"  "pg-payment-instrument"

echo "=== Target Groups Setup Complete ==="
