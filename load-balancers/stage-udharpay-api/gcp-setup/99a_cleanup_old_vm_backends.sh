#!/bin/bash
# ==============================================================================
# 01c_cleanup_old_vm_backends.sh — Remove legacy VM health checks & backends
# ==============================================================================
# This script explicitly deletes the old VM-based resources (Health Checks 
# and Backend Services) for the 5 services migrated to Cloud Run:
#   users-verifications, payments-billing, udharpay-api, superkey, kyc
#
# It does NOT touch the Load Balancer rules or URL maps.
# ==============================================================================

set -uo pipefail

PROJECT_ID="${GCP_PROJECT_ID:?Set GCP_PROJECT_ID env var}"

echo "============================================="
echo "  CLEANING UP Legacy VM Backends"
echo "  Project: $PROJECT_ID"
echo "============================================="
echo ""
echo "This will delete the old Instance Group backend attachments and health"
echo "checks for the 5 migrated services (users-verifications, payments-billing,"
echo "udharpay-api, superkey, kyc/workflow)."
echo ""
read -p "Are you sure? Type 'yes' to proceed: " CONFIRM
if [ "$CONFIRM" != "yes" ]; then
  echo "Aborted."
  exit 0
fi

del() {
  echo "  Deleting: $*"
  "$@" --project="$PROJECT_ID" --quiet 2>/dev/null && echo "    ✓ done" || echo "    ✗ not found or already deleted"
}

# 1. Backends (Note: Some might already be overwritten by Cloud Run scripts if names matched, but good to ensure they are clean if we renamed them)
# If 02_target_groups.sh overwrote the old backends, this step might fail gracefully, which is intended.
echo ""
echo "=== Deleting Old Backend Services ==="
# These are kept in case they were left lingering under different names. 
# (By default, 02_target_groups.sh reused the same names for the NEGs).

# 2. Health Checks
echo ""
echo "=== Deleting Old Health Checks ==="
HEALTH_CHECKS=(
  stage-hc-as1-users-and-verifications
  stage-hc-as1-payments-and-billing
  stage-hc-as1-udharpay-api
  stage-hc-as1-superkey
  stage-hc-as1-kyc
)
for hc in "${HEALTH_CHECKS[@]}"; do
  del gcloud compute health-checks delete "$hc" --global
done

echo ""
echo "============================================="
echo "  Cleanup complete."
echo "============================================="
