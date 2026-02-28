# Service Port Remapping & Routing Matrix

This document lists all services migrated to the unified GCP environment, highlighting those that required port remapping to avoid host-level conflicts.

## Unified Service Port Table

### From: `stage-udharpay-api-lb`

| Service Name | Old Port (AWS) | New Port (GCP) | Status | Routing Rule (Path/Host) | GCP LB is Healthy |
| :--- | :---: | :---: | :---: | :--- | :--- |
| `udharpay-api` | 8000 | 8000 | ✅ OK | `/v2/merchant/*`, `/api/*`, etc. | Y |
| `users-verifications` | 8081 | 8081 | ✅ OK | `/verification/*`, `/auth/*`, etc. | Y |
| `payments-billing` | 8082 | 8082 | ✅ OK | `/payments-and-billing/*`, etc. | Y |
| `superkey` | 8083 | 8083 | ✅ OK | `/superkey/*`, `/rocketscore/*`, etc. | Y |
| `account-preference` | 8086 | 8086 | ✅ OK | `/account/*`, `/account-preference/*` | Y |
| `crm` | 8087 | 8087 | ✅ OK | `/crm/*` | Y |
| `lending` | 8088 | 8088 | ✅ OK | `/lending/*` | AWS Unhealthy |
| `support-service` | 8089 | 8089 | ✅ OK | `/support-service/*` | AWS Unhealthy |
| `kyc` | 8246 | 8246 | ✅ OK | `/kyc/*`, `/workflow/*` | Y |
| `key` | 8077 | 8077 | ✅ OK | `/key/*` | AWS Unhealthy |
| `distributor-app` | 3000 | 3000 | ✅ OK | Host: `gcp-staging-distributor.rocketpay.co.in` | Y |
| `rule-engine` | 8081 | **8084** | ⚠️ Remapped | `/rule/*` | !!AWS Unhealthy |
| `dlt` | 8082 | **8085** | ⚠️ Remapped | `/dlt/*` | Y |
| `product-order` | 8089 | **8090** | ⚠️ Remapped | `/product-order/*` | Y |
| `key-gateway` | 8086 | **8091** | ⚠️ Remapped | `/key-gateway/*` | Y |
| `charge-service` | 8082 | **8092** | ⚠️ Remapped | `/charge-service/*` | AWS Unhealthy |
| `party-service` | 8083 | **8093** | ⚠️ Remapped | `/party/*` | AWS Unhealthy |
| `platform-common` | 8083 | **8094** | ⚠️ Remapped | `/book/*` | Y |
| `ai-apps` | 3000 | **3001** | ⚠️ Remapped | `/support-agent/*`, `/analytics-agent/*` | AWS Unhealthy |

---

### From: `stage-rpg-lb`

| Service Name | Old Port (AWS) | New Port (GCP) | Status | Routing Rule (Path/Host) |
| :--- | :---: | :---: | :---: | :--- |
| `pg-payment-account` | 8081 | **8101** | ⚠️ Remapped | Host: `gcp-staging-api-pg` + `/payment-account/*` |
| `pg-payment-order` | 8083 | **8102** | ⚠️ Remapped | Host: `gcp-staging-api-pg` + `/payment-order/*` |
| `pg-payment-gateway` | 8084 | **8103** | ⚠️ Remapped | Host: `gcp-staging-api-pg` + `/payment-gateway/*` |
| `pg-payment-mandate` | 8086 | **8104** | ⚠️ Remapped | Host: `gcp-staging-api-pg` + `/payment-mandate/*` |
| `pg-payment-instrument` | 8085 | **8105** | ⚠️ Remapped | Host: `gcp-staging-api-pg` + `/payment-instrument/*` |

---

### From: `staging-udharpay-admin-lb`

| Service Name | Old Port (AWS) | New Port (GCP) | Status | Routing Rule (Path/Host) |
| :--- | :---: | :---: | :---: | :--- |
| `udharpay-admin` | 80 | **8095** | ⚠️ Remapped | Host: `admin-staging.udharpay.com` (catch-all) |

---

## Summary of Remappings
The services marked as **Remapped** are those that previously ran on different physical instances using overlapping ports (like 80, 8081, 8082, 8083). In the new single-VM GCP setup, they have been assigned unique ports — `809x` for general services, `81xx` for payment-gateway services — to ensure coexistence.
