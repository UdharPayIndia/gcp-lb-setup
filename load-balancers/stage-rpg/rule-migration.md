# Side-by-Side Migration Mapping: stage-rpg-lb (AWS ALB) to GCP URL Map (shared LB)

This table shows how each AWS Listener Rule for `stage-rpg-lb` was translated into a GCP URL Map configuration.

**Note on Port Conflicts**: 
The AWS ALB routed traffic to a distinct EC2 instance. However, in GCP, we are sharing the single `stage-vm-as1-staging-apps-and-services` VM. The ports configured in AWS (8081, 8083-8086) conflicted with existing services on the GCP VM (users-verifications, superkey, rule-engine, dlt, account-preference). Resultingly, new unique ports (8101-8105) have been assigned to these RPG services mapped to the VM.

### Routing Table

| AWS Target Group | AWS Port | Reassigned GCP Port | AWS Path | GCP Host Rule | GCP Path Rule | GCP Backend Service |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `stage-pg-payment-account` | 8081 | **8101** | `/payment-account/*` | `gcp-staging-api-pg` | `/payment-account/*`  | `stage-bs-as1-pg-payment-account` |
| `stage-pg-payment-order` | 8083 | **8102** | `/payment-order/*` | `gcp-staging-api-pg` | `/payment-order/*` | `stage-bs-as1-pg-payment-order` |
| `stage-pg-payment-gateway` | 8084 | **8103** | `/payment-gateway/*` | `gcp-staging-api-pg` | `/payment-gateway/*` | `stage-bs-as1-pg-payment-gateway` |
| `stage-pg-payment-mandate` | 8086 | **8104** | `/payment-mandate/*` | `gcp-staging-api-pg` | `/payment-mandate/*` | `stage-bs-as1-pg-payment-mandate` |
| `stage-pg-payment-instrument` | 8085 | **8105** | `/payment-instrument/*` | `gcp-staging-api-pg` | `/payment-instrument/*` | `stage-bs-as1-pg-payment-instrument` |

## GCP Config Details

In GCP, the rules are scoped specifically to the `gcp-staging-api-pg` hostname using a new `hostRule` and `pathMatcher` (`pg-paths`) added to the globally shared `stage-lb-as1-udharpay-api` load balancer.

### Relatable GCP Command
The rule translation is automated using the following `add-path-matcher` command:

```bash
gcloud compute url-maps add-path-matcher stage-lb-as1-udharpay-api \
  --path-matcher-name="pg-paths" \
  --default-backend-bucket="stage-bb-as1-default-503" \
  --new-hosts="gcp-staging-api-pg" \
  --path-rules="\
/payment-account/*=stage-bs-as1-pg-payment-account,\
/payment-order/*=stage-bs-as1-pg-payment-order,\
/payment-gateway/*=stage-bs-as1-pg-payment-gateway,\
/payment-mandate/*=stage-bs-as1-pg-payment-mandate,\
/payment-instrument/*=stage-bs-as1-pg-payment-instrument"
```
