#!/bin/bash
# ==============================================================================
# 01_vms.sh — Create a single GCP Compute Engine VM for staging services
# ==============================================================================
# One general-purpose VM hosts the kotlin (java) staging services on different ports.
# In AWS, these were spread across 6 EC2 instances — here we consolidate.
#
# Services & Ports on this VM (14 total):
#   staging-support-service        → 8089
#   staging-account-preference     → 8086
#   stage-dlt                      → 8082  (adjust if needed)
#   staging-platform-rule-engine   → 8081  (adjust if needed)
#   staging-platform-charge-service→ 8082
#   staging-platform-party-service → 8083
#   stage-key                      → 8077
#   stage-key-gateway              → 8086
#   stage-platform-common          → 8083
#   stage-product-order            → 8089
#   staging-distributor-app        → 3000
#   stage-lending                  → 8088
#   stage-crm                      → 8087
#   staging-ai-apps                → 3000
#
# ⚠️  NOTE: Cloud Run Services (workflow, users-verifications, udharpay-api, 
# superkey, payments-billing) are EXCLUDED from this VM and are deployed
# via Serverless NEGs.
# ==============================================================================

set -euo pipefail

# ─── Configuration ────────────────────────────────────────────────────────────
PROJECT_ID="${GCP_PROJECT_ID:?Set GCP_PROJECT_ID env var}"
REGION="asia-south1"                    # Mumbai
ZONE="${REGION}-a"
NETWORK="stage-vpc-as1-general"
SUBNET="stage-subnet-as1-vm"
VM_NAME="stage-vm-as1-staging-apps-and-services"
MACHINE_TYPE="n4-highcpu-8"            # 4 vCPU, 16 GB RAM
IMAGE_FAMILY="ubuntu-2204-lts"          # Compatible with N4
IMAGE_PROJECT="ubuntu-os-cloud"
TAG="stage-apps-and-services"

echo "=== Step 1: Create firewall rules ==="
# Note: Firewall rules are now associated with the specific VPC

# Allow GCP health check probes
gcloud compute firewall-rules create stage-firewallrule-as1-allow-health-checks \
  --project="$PROJECT_ID" \
  --network="$NETWORK" \
  --action=ALLOW \
  --direction=INGRESS \
  --rules=tcp:80,tcp:3000,tcp:8000-8999 \
  --source-ranges="35.191.0.0/16,130.211.0.0/22" \
  --target-tags="$TAG" \
  --description="Allow GCP LB health check probes" \
  --quiet || echo "Firewall rule 'stage-firewallrule-as1-allow-health-checks' may already exist"

# Allow LB traffic to backend
gcloud compute firewall-rules create stage-lb-as1-allow-traffic \
  --project="$PROJECT_ID" \
  --network="$NETWORK" \
  --action=ALLOW \
  --direction=INGRESS \
  --rules=tcp:80,tcp:3000,tcp:8000-8999 \
  --source-ranges="0.0.0.0/0" \
  --target-tags="$TAG" \
  --description="Allow traffic from LB to backend" \
  --quiet || echo "Firewall rule 'stage-lb-as1-allow-traffic' may already exist"

echo "=== Step 2: Create VM ==="

gcloud compute instances create "$VM_NAME" \
  --project="$PROJECT_ID" \
  --zone="$ZONE" \
  --network="$NETWORK" \
  --subnet="$SUBNET" \
  --machine-type="$MACHINE_TYPE" \
  --image-family="$IMAGE_FAMILY" \
  --image-project="$IMAGE_PROJECT" \
  --tags="$TAG" \
  --deletion-protection \
  --shielded-secure-boot \
  --metadata=startup-script='#!/bin/bash
    # 1. Update and install prerequisites
    sudo apt update
    sudo apt install -y ca-certificates curl gnupg

    # 2. Setup Dockers GPG Key
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg

    # 3. Add the repository to Apt sources
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    # 4. Install Docker Engine
    sudo apt update
    sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    # 5. Manage Docker as a non-root user
    sudo usermod -aG docker $USER

    # Note: Run `newgrp docker` or log out/in to apply group changes without a full reboot.
    ' \
  --boot-disk-size=150GB \
  --boot-disk-type=hyperdisk-balanced \
  --quiet

echo ""
echo "=== VM Created ==="
echo "VM Name:      $VM_NAME"
echo "Zone:         $ZONE"
echo "Machine Type: $MACHINE_TYPE"
echo ""
echo "NOTE: Deploy all 14 legacy staging services (Docker containers) on this VM,"
echo "      each listening on its designated port."
gcloud compute instances list --project="$PROJECT_ID" --filter="name=$VM_NAME"
