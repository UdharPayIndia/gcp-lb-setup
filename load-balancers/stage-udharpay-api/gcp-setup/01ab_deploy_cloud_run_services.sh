#!/bin/bash
# ==============================================================================
# deploy_cloud_run_services.sh — Deploy backend services to Cloud Run
# ==============================================================================

set -euo pipefail

PROJECT_ID="${GCP_PROJECT_ID:?Set GCP_PROJECT_ID env var}"
REGION="asia-south1"

echo "=== Deploying Services to Cloud Run ==="
echo "Note: The services use internal ingress to only allow traffic from the Load Balancer."
echo "They allow unauthenticated access from the LB itself."
echo "--------------------------------------------------------"

deploy_service() {
  local SERVICE_NAME=$1
  local PORT=$2
  local IMAGE_NAME=$3
  local IMAGE_VERSION=$4
  local SERVICE_ENV_VARS=${5:-""}
  
  echo ">>> Deploying ${SERVICE_NAME} (Port: ${PORT}, Image: ${IMAGE_NAME}:${IMAGE_VERSION}) <<<"
  
  # ==============================================================================
  # INSTRUCTIONS FOR USER:
  # 1. The image name and version are now passed directly as arguments to this function.
  # 2. To set environment variables, pass them as the 5th argument.
  # 3. For Volume Mounts (e.g. for credentials/env details):
  #    - We added a volume mount from a Secret Manager secret below.
  #    - Adjust 'my-credentials-secret' to your actual secret name.
  # ==============================================================================
  
  local IMAGE_URI="${REGION}-docker.pkg.dev/${PROJECT_ID}/rp-dockerreg/${IMAGE_NAME}:${IMAGE_VERSION}"

  local CONTAINER_ARGS=(
      "--container=${SERVICE_NAME}"
      "--image=${IMAGE_URI}"
      "--port=${PORT}"
      "--cpu=2"
      "--memory=2Gi"
      "--set-env-vars=ENV=stage,SERVICE_NAME=${SERVICE_NAME},${SERVICE_ENV_VARS}"
  )  
  if [ "$SERVICE_NAME" != "udharpay-api" ]; then
    CONTAINER_ARGS+=(
      "--update-secrets=/app/server/assets/config.json5=rp-stage-secret-${SERVICE_NAME}-config-json5:latest,/app/ecosystem.config.js=rp-stage-secret-${SERVICE_NAME}-pm2-ecosystem-config:latest"
    )
  else
    # udharpay-api needs AWS + NewRelic credentials as env vars (not file mounts).
    # Source from Secret Manager — never inline these values into this script.
    # Prereq: create these secrets (see scripts/lb_apply.sh follow-up task for rotation):
    #   rp-stage-secret-api-aws-access-key-id
    #   rp-stage-secret-api-aws-secret-access-key
    #   rp-stage-secret-api-newrelic-license-key
    CONTAINER_ARGS+=(
      "--set-secrets=AWS_ACCESS_KEY_ID=rp-stage-secret-api-aws-access-key-id:latest,AWS_SECRET_ACCESS_KEY=rp-stage-secret-api-aws-secret-access-key:latest,NEWRELIC_LICENSE_KEY=rp-stage-secret-api-newrelic-license-key:latest"
    )
  fi
  
  if [[ "$SERVICE_NAME" == "udharpay-api" || "$SERVICE_NAME" == "payments-billing" || "$SERVICE_NAME" == "superkey" ]]; then 
    # Multi-container deployment: Redis Sidecar
    CONTAINER_ARGS+=(
      "--container=redis"
      "--image=redis:alpine"
      "--cpu=1"
      "--memory=512Mi"
    )
  fi
  
  gcloud run deploy "$SERVICE_NAME" \
    --project="$PROJECT_ID" \
    --region="$REGION" \
    --ingress=internal-and-cloud-load-balancing \
    --allow-unauthenticated \
    --min-instances=1 \
    --max-instances=5 \
    --concurrency=200 \
    --timeout=300 \
    --service-account="581889672100-compute@developer.gserviceaccount.com" \
    --network="stage-vpc-as1-general" \
    --subnet="stage-subnet-as1-vm" \
    --vpc-egress="private-ranges-only" \
    --labels="service_name=${SERVICE_NAME},env=stage" \
    --cpu-boost \
    --quiet \
    "${CONTAINER_ARGS[@]}"
    
  echo "✓ Successfully deployed ${SERVICE_NAME}."
  echo "  Note: Review networking and service accounts to ensure they are available in this project."
  echo ""
}

# The 5 services to migrate
# Add any specific ENV vars as the 5th argument (Format: "KEY1=value1,KEY2=value2")
deploy_service "users-verifications" 8081 "users-and-verifications" "g-feature-referrals-with-ci" "NODE_ENV=production,NEW_RELIC_APP_NAME=users-and-verifications"
deploy_service "payments-billing" 8082 "payments-and-billing" "g-stage-common-with-ci" "NODE_ENV=production,NEW_RELIC_APP_NAME=payments-and-billing"
deploy_service "udharpay-api" 8000 "api" "g-stage-common-with-ci2" "NODE_ENV=production,MODE=stage,NEW_RELIC_APP_NAME=udharpay-api"
deploy_service "superkey" 8083 "key-managemet-service" "g-stage-common-with-ci" "NODE_ENV=production,NEW_RELIC_APP_NAME=superkey"
deploy_service "workflow" 8246 "workflow-service" "g-aws-staging-code-with-ci" "NODE_ENV=production,NEW_RELIC_APP_NAME=workflow"

echo "=== All Services Deployed to Cloud Run ==="
