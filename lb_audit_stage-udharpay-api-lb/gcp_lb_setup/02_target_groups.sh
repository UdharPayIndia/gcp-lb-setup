#!/bin/bash
# ==============================================================================
# 02_target_groups.sh — Create Health Checks, Instance Group & Backend Services
# ==============================================================================
# Naming Convention: [env]-[resource-type-short-code]-[region-short-code]-[name]
# ==============================================================================

set -euo pipefail

PROJECT_ID="${GCP_PROJECT_ID:?Set GCP_PROJECT_ID env var}"
REGION="asia-south1"
ZONE="${REGION}-a"
VM_NAME="stage-vm-as1-staging-apps-and-services"
IG_NAME="stage-ig-as1-staging-apps-and-services"

# ─── Step 1: Create Single Instance Group ─────────────────────────────────────
# echo "=== Step 1: Create Instance Group with all named ports ==="

# gcloud compute instance-groups unmanaged create "$IG_NAME" \
#   --project="$PROJECT_ID" --zone="$ZONE" --quiet || echo "Instance group already exists"

# gcloud compute instance-groups unmanaged add-instances "$IG_NAME" \
#   --project="$PROJECT_ID" --zone="$ZONE" --instances="$VM_NAME" --quiet || echo "Instance already in group"

# Set ALL named ports (one per service)
gcloud compute instance-groups unmanaged set-named-ports "$IG_NAME" \
  --project="$PROJECT_ID" --zone="$ZONE" \
  --named-ports="\
support-service:8089,\
users-verifications:8081,\
account-preference:8086,\
payments-billing:8082,\
udharpay-api:8000,\
superkey:8083,\
dlt:8085,\
rule-engine:8084,\
charge-service:8092,\
party-service:8093,\
kyc:8246,\
key:8077,\
key-gateway:8091,\
platform-common:8094,\
product-order:8090,\
distributor-app:3000,\
lending:8088,\
crm:8087,\
ai-apps:3001" \
  --quiet

# echo "Instance group $IG_NAME updated with 19 named ports"

# # ─── Step 2: Create Health Checks (1 per service) ────────────────────────────
# echo "=== Step 2: Create Health Checks ==="

# create_hc() {
#   local HC_NAME=$1 REQUEST_PATH=$2 PORT=$3
#   echo "  Health check: $HC_NAME → $REQUEST_PATH :$PORT"
#   gcloud compute health-checks create http "$HC_NAME" \
#     --project="$PROJECT_ID" \
#     --port="$PORT" \
#     --request-path="$REQUEST_PATH" \
#     --check-interval=30s \
#     --timeout=10s \
#     --healthy-threshold=2 \
#     --unhealthy-threshold=3 \
#     --quiet || echo "Health check $HC_NAME already exists"
# }

# # Mapping: AWS Target Group -> GCP Health Check (stage-hc-as1-...)
# create_hc "stage-hc-as1-support-service"             "/support-service"                8089
# create_hc "stage-hc-as1-users-and-verifications"     "/"                               8081
# create_hc "stage-hc-as1-account-preference"          "/"                               8086
# create_hc "stage-hc-as1-payments-and-billing"        "/"                               8082
# create_hc "stage-hc-as1-udharpay-api"                "/"                               8000
# create_hc "stage-hc-as1-superkey"                    "/superkey"                       8083
# create_hc "stage-hc-as1-dlt"                         "/dlt/actuator/health"            8085
# create_hc "stage-hc-as1-platform-rule-engine"        "/rule/actuator/health"           8084
# create_hc "stage-hc-as1-platform-charge-service"     "/"                               8092
# create_hc "stage-hc-as1-platform-party-service"      "/"                               8093
# create_hc "stage-hc-as1-kyc"                         "/"                               8246
# create_hc "stage-hc-as1-key"                         "/key"                            8077
# create_hc "stage-hc-as1-key-gateway"                 "/key-gateway/"                   8091
# create_hc "stage-hc-as1-platform-common"             "/book/actuator/health"           8094
# create_hc "stage-hc-as1-product-order"               "/product-order/actuator/health"  8090
# create_hc "stage-hc-as1-distributor-app"             "/"                               3000
# create_hc "stage-hc-as1-lending"                     "/lending/actuator/health"        8088
# create_hc "stage-hc-as1-crm"                         "/crm/"                           8087
# create_hc "stage-hc-as1-ai-apps"                     "/support-agent/health"           3001

# ─── Step 3: Create Backend Services ─────────────────────────────────────────
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
    --quiet || echo "Backend service $BS_NAME already exists"
    
  gcloud compute backend-services add-backend "$BS_NAME" \
    --project="$PROJECT_ID" \
    --instance-group="$IG_NAME" \
    --instance-group-zone="$ZONE" \
    --global \
    --quiet || echo "Backend already added to $BS_NAME"
}

# Mapping: AWS Target Group -> GCP Backend Service (stage-bs-as1-...)
# create_bs "stage-bs-as1-support-service"                 "stage-hc-as1-support-service"            "support-service"
# create_bs "stage-bs-as1-users-and-verifications"         "stage-hc-as1-users-and-verifications"    "users-verifications"
# create_bs "stage-bs-as1-account-preference"              "stage-hc-as1-account-preference"         "account-preference"
# create_bs "stage-bs-as1-payments-and-billing"            "stage-hc-as1-payments-and-billing"       "payments-billing"
# create_bs "stage-bs-as1-udharpay-api"                    "stage-hc-as1-udharpay-api"               "udharpay-api"
# create_bs "stage-bs-as1-superkey"                        "stage-hc-as1-superkey"                   "superkey"
# create_bs "stage-bs-as1-dlt"                             "stage-hc-as1-dlt"                        "dlt"
# create_bs "stage-bs-as1-platform-rule-engine"            "stage-hc-as1-platform-rule-engine"       "rule-engine"
# create_bs "stage-bs-as1-platform-charge-service"         "stage-hc-as1-platform-charge-service"    "charge-service"
# create_bs "stage-bs-as1-platform-party-service"          "stage-hc-as1-platform-party-service"     "party-service"
# create_bs "stage-bs-as1-kyc"                             "stage-hc-as1-kyc"                        "kyc"
# create_bs "stage-bs-as1-key"                             "stage-hc-as1-key"                        "key"
# create_bs "stage-bs-as1-key-gateway"                     "stage-hc-as1-key-gateway"                "key-gateway"
# create_bs "stage-bs-as1-platform-common"                 "stage-hc-as1-platform-common"            "platform-common"
# create_bs "stage-bs-as1-product-order"                   "stage-hc-as1-product-order"              "product-order"
# create_bs "stage-bs-as1-distributor-app"                 "stage-hc-as1-distributor-app"            "distributor-app"
# create_bs "stage-bs-as1-lending"                         "stage-hc-as1-lending"                    "lending"
# create_bs "stage-bs-as1-crm"                             "stage-hc-as1-crm"                        "crm"
# create_bs "stage-bs-as1-ai-apps"                         "stage-hc-as1-ai-apps"                    "ai-apps"

# ─── Step 4: Default 503 Backend ─────────────────────────────────────────────
echo "=== Step 4: Create default 503 backend (Cloud Storage) ==="

# Using identification name 'rp-static-assets'
BUCKET_NAME="rp-static-assets"
echo "  Creating GCS bucket: gs://${BUCKET_NAME}/"
gsutil mb -p "$PROJECT_ID" -l "$REGION" "gs://${BUCKET_NAME}/"
echo '<html><body><h1>503 - Api is Not supported</h1></body></html>' | \
  gsutil cp - "gs://${BUCKET_NAME}/index.html"
gsutil iam ch allUsers:objectViewer "gs://${BUCKET_NAME}"

# Configure bucket as a website so it serves index.html for unknown paths (NoSuchKey)
gsutil web set -m index.html -e index.html "gs://${BUCKET_NAME}"

gcloud compute backend-buckets create stage-bb-as1-default-503 \
  --project="$PROJECT_ID" \
  --gcs-bucket-name="$BUCKET_NAME" \
  --quiet || echo "Backend bucket already exists"

echo ""
echo "=== Target Groups Setup Complete ==="
echo "Created: $IG_NAME, 19 health checks, 19 backend services, 1 backend bucket"
