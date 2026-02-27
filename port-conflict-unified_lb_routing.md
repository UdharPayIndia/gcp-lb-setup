# Service Port Remapping & Routing Matrix

This document lists all services migrated to the unified GCP environment, highlighting those that required port remapping to avoid host-level conflicts.

## Unified Service Port Table

| Service Name | Old Port (AWS/Usual) | New Port (GCP/Host) | Status | Routing Rule (Path/Host) |
| :--- | :---: | :---: | :---: | :--- |
| `pg-payment-account` | 8081 | **8101** | ⚠️ Remapped | `/payment-account/*` |
| `pg-payment-order` | 8083 | **8102** | ⚠️ Remapped | `/payment-order/*` |
| `pg-payment-gateway` | 8084 | **8103** | ⚠️ Remapped | `/payment-gateway/*` |
| `pg-payment-mandate` | 8086 | **8104** | ⚠️ Remapped | `/payment-mandate/*` |
| `pg-payment-instrument` | 8085 | **8105** | ⚠️ Remapped | `/payment-instrument/*` |
| `rule-engine` | 8081 | **8084** | ⚠️ Remapped | `/rule/*` |
| `dlt` | 8082 | **8085** | ⚠️ Remapped | `/dlt/*` |
| `product-order` | 8089 | **8090** | ⚠️ Remapped | `/product-order/*` |
| `key-gateway` | 8086 | **8091** | ⚠️ Remapped | `/key-gateway/*` |
| `charge-service` | 8082 | **8092** | ⚠️ Remapped | `/charge-service/*` |
| `party-service` | 8083 | **8093** | ⚠️ Remapped | `/party/*` |
| `platform-common` | 8083 | **8094** | ⚠️ Remapped | `/book/*` |
| `ai-apps` | 3000 | **3001** | ⚠️ Remapped | `/support-agent/*`, etc. |
| `udharpay-api` | 8000 | 8000 | ✅ OK | `/v2/merchant/*`, `/api/*`, etc. |
| `users-verifications` | 8081 | 8081 | ✅ OK | `/verification/*`, `/auth/*`, etc. |
| `payments-billing` | 8082 | 8082 | ✅ OK | `/payments-and-billing/*`, etc. |
| `superkey` | 8083 | 8083 | ✅ OK | `/superkey/*`, `/rocketscore/*`, etc. |
| `account-preference` | 8086 | 8086 | ✅ OK | `/account/*`, `/account-preference/*` |
| `crm` | 8087 | 8087 | ✅ OK | `/crm/*` |
| `lending` | 8088 | 8088 | ✅ OK | `/lending/*` |
| `support-service` | 8089 | 8089 | ✅ OK | `/support-service/*` |
| `kyc` | 8246 | 8246 | ✅ OK | `/kyc/*`, `/workflow/*` |
| `key` | 8077 | 8077 | ✅ OK | `/key/*` |
| `distributor-app` | 3000 | 3000 | ✅ OK | `staging-distributor.rocketpay.co.in` |

## Summary of Remappings
The services marked as **Remapped** are those that previously ran on different physical instances using overlapping ports (like 8081, 8082, 8083). In the new single-VM GCP setup, they have been assigned unique ports in the `809x` and `81xx` ranges to ensure coexistence.
