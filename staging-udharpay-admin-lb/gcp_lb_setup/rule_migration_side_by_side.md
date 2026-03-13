# Side-by-Side Migration Mapping: staging-udharpay-admin-lb (AWS ALB) to GCP URL Map (shared LB)

This table shows how the AWS ALB `staging-udharpay-admin-lb` was translated to GCP.

## Port Conflict Resolution

The AWS admin service runs on port **80** of its dedicated EC2 instance. On the shared GCP VM (`stage-vm-as1-staging-apps-and-services`), port 80 is not available as a named port. To avoid future conflicts and keep things consistent with our port allocation scheme, we assign port **8095** (next available after 8105 used by pg-payment-instrument).

## Routing Table

| AWS Rule | AWS Condition | AWS Target Group | AWS Port | GCP Port | GCP Host Rule | GCP Routing | GCP Backend Service |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| Default (HTTPS:443) | All traffic | `staging-udharpay-admin-tg` | 80 | **8095** | `admin-staging.udharpay.com` | defaultService (catch-all) | `stage-bs-as1-udharpay-admin` |
| Default (HTTP:80) | All traffic | — | — | — | — | 301 → HTTPS (handled by GCP HTTPS proxy) | — |

## Key Differences

| Aspect | AWS | GCP |
| :--- | :--- | :--- |
| **LB** | Dedicated ALB `staging-udharpay-admin-lb` | Shared URL Map `stage-lb-as1-udharpay-api` |
| **Host Routing** | Implicit (dedicated LB DNS) | Explicit host rule: `admin-staging.udharpay.com` |
| **Target Port** | 80 (dedicated EC2) | 8095 (shared VM, reassigned) |
| **Health Check** | `/health` on port 80 | `/health` on port 8095 |
| **HTTP→HTTPS** | Listener rule redirect | Handled by GCP HTTPS target proxy |

## GCP Command Summary

```bash
# 1. Add named port
gcloud compute instance-groups unmanaged set-named-ports stage-ig-as1-staging-apps-and-services \
  --named-ports="...,udharpay-admin:8095"

# 2. Health check
gcloud compute health-checks create http stage-hc-as1-udharpay-admin \
  --port=8095 --request-path="/health"

# 3. Backend service
gcloud compute backend-services create stage-bs-as1-udharpay-admin \
  --health-checks=stage-hc-as1-udharpay-admin --port-name=udharpay-admin \
  --enable-logging --logging-sample-rate=1

# 4. URL map patch (host rule, default service)
gcloud compute url-maps add-path-matcher stage-lb-as1-udharpay-api \
  --path-matcher-name=admin-paths \
  --default-service=stage-bs-as1-udharpay-admin \
  --new-hosts="admin-staging.udharpay.com"
```
