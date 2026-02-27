#!/bin/bash
# ==============================================================================
# 99_destroy_all.sh — Tear down ALL GCP resources created by the setup scripts
# ==============================================================================
# Deletes everything in REVERSE order of creation to respect dependencies:
#   1. Forwarding rules (frontends)
#   2. Target proxies
#   3. SSL certificate
#   4. URL maps
#   5. Static IP
#   6. Backend services
#   7. Backend bucket + GCS bucket
#   8. Health checks
#   9. Instance group
#  10. VM
#  11. Firewall rules
#
# Safe: uses --quiet to skip confirmations, but each command is independent
#       so partial failures won't block the rest.
# ==============================================================================

set -uo pipefail  # no -e, we want to continue on individual failures

PROJECT_ID="${GCP_PROJECT_ID:?Set GCP_PROJECT_ID env var}"
REGION="asia-south1"
ZONE="${REGION}-a"

echo "============================================="
echo "  DESTROYING all stage-udharpay-api-lb resources"
echo "  Project: $PROJECT_ID"
echo "============================================="
echo ""
read -p "Are you sure? This is irreversible. Type 'yes' to proceed: " CONFIRM
if [ "$CONFIRM" != "yes" ]; then
  echo "Aborted."
  exit 0
fi

del() {
  echo "  Deleting: $*"
  "$@" --project="$PROJECT_ID" --quiet 2>/dev/null && echo "    ✓ done" || echo "    ✗ not found or already deleted"
}

# ─── 1. Forwarding Rules ─────────────────────────────────────────────────────
echo ""
echo "=== 1/11: Forwarding Rules ==="
del gcloud compute forwarding-rules delete stage-forwardingrule-as1-udharpay-api-https --global
del gcloud compute forwarding-rules delete stage-forwardingrule-as1-udharpay-api-http --global

# ─── 2. Target Proxies ───────────────────────────────────────────────────────
echo ""
echo "=== 2/11: Target Proxies ==="
del gcloud compute target-https-proxies delete stage-targetproxy-as1-udharpay-api-https --global
del gcloud compute target-http-proxies delete stage-targetproxy-as1-udharpay-api-http --global

# ─── 3. SSL Certificate ──────────────────────────────────────────────────────
echo ""
echo "=== 3/11: SSL Certificate ==="
del gcloud compute ssl-certificates delete stage-ssl-as1-udharpay-api --global

# ─── 4. URL Maps ─────────────────────────────────────────────────────────────
echo ""
echo "=== 4/11: URL Maps ==="
del gcloud compute url-maps delete stage-lb-as1-udharpay-api --global
del gcloud compute url-maps delete stage-lb-as1-udharpay-api-redirect --global

# ─── 5. Static IP ────────────────────────────────────────────────────────────
echo ""
echo "=== 5/11: Static IP ==="
del gcloud compute addresses delete stage-lbip-as1-udharpay-api --global

# ─── 6. Backend Services ─────────────────────────────────────────────────────
echo ""
echo "=== 6/11: Backend Services (19) ==="
BACKEND_SERVICES=(
  stage-bs-as1-support-service
  stage-bs-as1-users-and-verifications
  stage-bs-as1-account-preference
  stage-bs-as1-payments-and-billing
  stage-bs-as1-udharpay-api
  stage-bs-as1-superkey
  stage-bs-as1-dlt
  stage-bs-as1-platform-rule-engine
  stage-bs-as1-platform-charge-service
  stage-bs-as1-platform-party-service
  stage-bs-as1-kyc
  stage-bs-as1-key
  stage-bs-as1-key-gateway
  stage-bs-as1-platform-common
  stage-bs-as1-product-order
  stage-bs-as1-distributor-app
  stage-bs-as1-lending
  stage-bs-as1-crm
  stage-bs-as1-ai-apps
)
for bs in "${BACKEND_SERVICES[@]}"; do
  del gcloud compute backend-services delete "$bs" --global
done

# ─── 7. Backend Bucket + GCS Bucket ──────────────────────────────────────────
echo ""
echo "=== 7/11: Default 503 Backend Bucket ==="
del gcloud compute backend-buckets delete stage-bb-as1-default-503
BUCKET_NAME="rp-static-assets"
echo "  Deleting GCS bucket: gs://${BUCKET_NAME}/"
gsutil rm -r "gs://${BUCKET_NAME}/" 2>/dev/null && echo "    ✓ done" || echo "    ✗ not found or already deleted"

# ─── 8. Health Checks ────────────────────────────────────────────────────────
echo ""
echo "=== 8/11: Health Checks (19) ==="
HEALTH_CHECKS=(
  stage-hc-as1-support-service
  stage-hc-as1-users-and-verifications
  stage-hc-as1-account-preference
  stage-hc-as1-payments-and-billing
  stage-hc-as1-udharpay-api
  stage-hc-as1-superkey
  stage-hc-as1-dlt
  stage-hc-as1-platform-rule-engine
  stage-hc-as1-platform-charge-service
  stage-hc-as1-platform-party-service
  stage-hc-as1-kyc
  stage-hc-as1-key
  stage-hc-as1-key-gateway
  stage-hc-as1-platform-common
  stage-hc-as1-product-order
  stage-hc-as1-distributor-app
  stage-hc-as1-lending
  stage-hc-as1-crm
  stage-hc-as1-ai-apps
)
for hc in "${HEALTH_CHECKS[@]}"; do
  del gcloud compute health-checks delete "$hc" --global
done

# ─── 9. Instance Group ───────────────────────────────────────────────────────
echo ""
echo "=== 9/11: Instance Group ==="
del gcloud compute instance-groups unmanaged delete stage-ig-as1-staging-apps-and-services --zone="$ZONE"

# ─── 10. VM ──────────────────────────────────────────────────────────────────
echo ""
echo "=== 10/11: VM ==="
# Disable deletion protection before deleting
gcloud compute instances update stage-vm-as1-staging-apps-and-services --no-deletion-protection --project="$PROJECT_ID" --zone="$ZONE" --quiet 2>/dev/null
del gcloud compute instances delete stage-vm-as1-staging-apps-and-services --zone="$ZONE"

# ─── 11. Firewall Rules ──────────────────────────────────────────────────────
echo ""
echo "=== 11/11: Firewall Rules ==="
del gcloud compute firewall-rules delete stage-firewallrule-as1-allow-health-checks
del gcloud compute firewall-rules delete stage-lb-as1-allow-traffic

echo ""
echo "============================================="
echo "  Teardown complete."
echo "============================================="
