# Networking Test Plan for GCP Load Balancer

This directory contains resources to test the end-to-end networking of your GCP Load Balancer before deploying actual production containers.

## 1. Preparation
1. Ensure your VM (`stage-vm-as1-staging-apps-and-services`) is running.
2. ssh into the VM.
3. Install Docker and Docker Compose (the startup script in `01_vms.sh` handles this).

## 2. Deploy Dummy Services
Copy `test-docker-compose.yaml` to the VM and run:
```bash
docker compose -f test-docker-compose.yaml up -d
```

This will spin up 19 lightweight containers (`traefik/whoami`). Each container:
- Listens on a specific port assigned in `02_target_groups.sh`.
- Returns its own hostname and request headers.
- Responds with `200 OK` to **any** path (satisfying all health check requirements like `/dlt/actuator/health`, `/key-gateway/`, etc.).

## 3. Verify Health Checks
On your local machine or via GCP Console, check health status:
```bash
# Example for udharpay-api
gcloud compute backend-services get-health stage-bs-as1-udharpay-api --global --project=$GCP_PROJECT_ID
```
Wait about 30-60 seconds for GCP to mark them as `HEALTHY`.

## 4. Test Routing
Once healthy, you can curl your Load Balancer IP (or domain if DNS is set):

| Test Route | Target Service |
| :--- | :--- |
| `curl -H "Host: gcp-staging-api.rocketpay.co.in" http://<LB_IP>/support-service/` | support-service |
| `curl -H "Host: gcp-staging-api.rocketpay.co.in" http://<LB_IP>/account/v2/authenticate` | users-and-verifications |
| `curl -H "Host: gcp-staging-distributor.rocketpay.co.in" http://<LB_IP>/` | distributor-app |

## 5. Cleanup
```bash
docker compose -f test-docker-compose.yaml down
```
