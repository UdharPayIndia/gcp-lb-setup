#!/bin/bash
set -e

# ==============================================================================
# Script to Enable/Disable Logging for 25 Specific GCP Backend Services
# ==============================================================================

# Replace with your actual GCP Project ID
PROJECT_ID="${GCP_PROJECT_ID:?Set GCP_PROJECT_ID env var}"

# Set to "global" or the specific region (e.g., "asia-south1")
SCOPE="global"

ACTION=""
SAMPLE_RATE_VAL="1.0"

usage() {
    echo "Usage: $0 --action <enable|disable> [--sample-rate <0.0-1.0>]"
    echo "Example: $0 --action enable --sample-rate 0.5"
    echo "Example: $0 --action disable"
    exit 1
}

while [[ $# -gt 0 ]]; do
  case $1 in
    --action)
      ACTION="$2"
      shift 2
      ;;
    --sample-rate)
      SAMPLE_RATE_VAL="$2"
      shift 2
      ;;
    -h|--help)
      usage
      ;;
    *)
      echo "Unknown option $1"
      usage
      ;;
  esac
done

if [[ "$ACTION" != "enable" && "$ACTION" != "disable" ]]; then
    echo "Error: --action must be 'enable' or 'disable'"
    usage
fi

if [ "$ACTION" = "enable" ]; then
    LOGGING_FLAG="--enable-logging"
    SAMPLE_RATE="--logging-sample-rate=${SAMPLE_RATE_VAL}"
elif [ "$ACTION" = "disable" ]; then
    LOGGING_FLAG="--no-enable-logging"
    SAMPLE_RATE=""
fi

# Build the scope flag
if [ "$SCOPE" = "global" ]; then
    SCOPE_FLAG="--global"
else
    SCOPE_FLAG="--region=${SCOPE}"
fi

# Explicit list of 25 backend services parsed from provided configurations
BACKEND_SERVICES=(
    # --- RPG LB Backends ---
    "stage-bs-as1-pg-payment-account"
    "stage-bs-as1-pg-payment-order"
    "stage-bs-as1-pg-payment-gateway"
    "stage-bs-as1-pg-payment-mandate"
    "stage-bs-as1-pg-payment-instrument"

    # --- Admin LB Backend ---
    "stage-bs-as1-udharpay-admin"

    # --- API LB Backends ---
    "stage-bs-as1-distributor-app"
    "stage-bs-as1-support-service"
    "stage-bs-as1-users-and-verifications"
    "stage-bs-as1-account-preference"
    "stage-bs-as1-payments-and-billing"
    "stage-bs-as1-udharpay-api"
    "stage-bs-as1-superkey"
    "stage-bs-as1-dlt"
    "stage-bs-as1-platform-rule-engine"
    "stage-bs-as1-platform-charge-service"
    "stage-bs-as1-platform-party-service"
    "stage-bs-as1-kyc"
    "stage-bs-as1-key"
    "stage-bs-as1-key-gateway"
    "stage-bs-as1-platform-common"
    "stage-bs-as1-product-order"
    "stage-bs-as1-lending"
    "stage-bs-as1-crm"
    "stage-bs-as1-ai-apps"
)

echo "Found the following 25 backend services to $ACTION logging for:"
for bs in "${BACKEND_SERVICES[@]}"; do
    echo " - $bs"
done

echo ""
read -p "Are you sure you want to $ACTION logging for these backend services? (y/n) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Operation cancelled."
    exit 1
fi

echo "Applying changes..."

for bs in "${BACKEND_SERVICES[@]}"; do
    echo "Updating backend service: $bs"
    
    # We suppress standard output and only show errors, as the update command implies success if it returns 0
    gcloud compute backend-services update "$bs" \
        --project="${PROJECT_ID}" \
        ${SCOPE_FLAG} \
        ${LOGGING_FLAG} \
        ${SAMPLE_RATE} > /dev/null
        
    echo " -> Success."
done

echo "All 25 backend services successfully updated."
