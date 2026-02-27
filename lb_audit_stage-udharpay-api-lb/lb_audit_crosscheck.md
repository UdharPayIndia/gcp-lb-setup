# LB Audit Cross-Check: stage-udharpay-api-lb

**Audit timestamp:** 2026-02-24 20:01:41
**Swimlane file:** `swimlanes-lb-routing.txt`

---

## ✅ Counts Verification

| Resource        | JSON Source | Swimlane Diagram | Match? |
|-----------------|-------------|------------------|--------|
| Listeners       | 2           | 2 (HTTP:80 + HTTPS:443) | ✅ |
| Rules (total)   | 32          | 32 (30 custom + 2 default) | ✅ |
| Target Groups   | 19          | 19               | ✅ |
| Targets         | 19          | 19               | ✅ |
| Healthy         | 12          | 12               | ✅ |
| Unhealthy       | 7           | 7                | ✅ |

---

## ✅ Listener Verification

| Listener | Port | Protocol | Default Action | In Diagram? |
|----------|------|----------|----------------|-------------|
| 6c2964d11e06bc5f | 80 | HTTP | 301 Redirect → HTTPS:443 | ✅ |
| ae7f3e5f367f4638 | 443 | HTTPS | Fixed Response 503 "Api is Not supported" | ✅ |

---

## ✅ Rules Verification (HTTPS:443 — 30 custom + 1 default)

| Priority | Condition | Target Group | In Diagram? |
|----------|-----------|--------------|-------------|
| 1 | Path: `/support-service/*` | staging-support-service | ✅ |
| 2 | Path: `/account/v2/authenticate` | stage-users-and-verifications-tg | ✅ |
| 3 | Path: `/account/*` | staging-account-preference | ✅ |
| 4 | Path: `/account-preference/*` | staging-account-preference | ✅ |
| 5 | Path: `/payments-and-billing/*`, `/ab-experiment/*`, `/ab-rollout/*` | stage-payments-and-billing-tg | ✅ |
| 6 | Path: `/common/wallets/*`, `/common/product-orders/*`, `/common/payment-orders/*`, `/common/party/*`, `/common/preferences/*` | stage-payments-and-billing-tg | ✅ |
| 7 | Path: `/v1/merchant/kyc*`, `/v1/merchant/workflow*`, `/api/merchant/bank_details*`, `/api/banks*`, `/api/instruments*` | stage-payments-and-billing-tg | ✅ |
| 8 | Path: `/api/mas/*`, `/api/merchant/auth/v2/*`, `/api/system-status`, `/api/merchant/devices*`, `/api/merchant/admin/*` | stage-payments-and-billing-tg | ✅ |
| 9 | Path: `/api/help`, `/v1/merchant/*`, `/api/merchant/user-query*`, `/api/merchant/auth*` | staging-udharpay-api-tg | ✅ |
| 10 | Path: `/api/merchant/*` | stage-payments-and-billing-tg | ✅ |
| 11 | Path: `/superkey/*`, `/rocketscore/*`, `/super-key/*`, `/credit-score/*`, `/referrals/*` | staging-superkey-tg | ✅ |
| 12 | Path: `/verification/*`, `/auth/*`, `/analytics/*`, `/auth-migration/*`, `/acl/*` | stage-users-and-verifications-tg | ✅ |
| 13 | Path: `/dlt/*` | stage-dlt-stage | ✅ |
| 14 | Path: `/v2/merchant/*`, `/api/*`, `/common/mappings/*`, `/v1/customer/*`, `/v3/merchant/*` | staging-udharpay-api-tg | ✅ |
| 15 | Path: `/v4/mandates*`, `/v4/installments*` | staging-udharpay-api-tg | ✅ |
| 18 | Path: `/rule/*` | staging-platform-rule-engine | ✅ |
| 19 | Path: `/charge-service/*` | staging-platform-charge-service | ✅ |
| 21 | Path: `/party/*` | staging-platform-party-service | ✅ |
| 22 | Path: `/kyc/*`, `/workflow/*` | stage-kyc-tg | ✅ |
| 24 | Path: `/key/*` | stage-key-tg | ✅ |
| 25 | Path: `/key-gateway/*` | stage-key-gateway-tg | ✅ |
| 26 | Path: `/cus/*` | stage-payments-and-billing-tg | ✅ |
| 27 | Path: `/book/*` | stage-platform-common-tg | ✅ |
| 28 | Path: `/product-order/*` | stage-product-order-tg | ✅ |
| 30 | Host: `staging-distributor.rocketpay.co.in` | staging-distributor-app | ✅ |
| 33 | Path: `/lending/*` | stage-lending | ✅ |
| 34 | Path: `/crm/*` | stage-crm-tg | ✅ |
| 35 | Path: `/agreement/*` | stage-payments-and-billing-tg | ✅ |
| 36 | Path: `/support-agent/*`, `/analytics-agent/*` | staging-ai-apps | ✅ |
| 37 | Path: `/common/charges/*` | stage-payments-and-billing-tg | ✅ |
| default | (none — catch-all) | Fixed Response 503 | ✅ |

---

## ✅ Rules Verification (HTTP:80 — 1 default)

| Priority | Condition | Action | In Diagram? |
|----------|-----------|--------|-------------|
| default | (none — catch-all) | 301 Redirect → HTTPS:443 | ✅ |

---

## ✅ Target Groups & Targets Verification

| Target Group | Protocol | TG Port | HealthCheck Path | Instance ID | Instance Port | Health | In Diagram? |
|-------------|----------|---------|------------------|-------------|---------------|--------|-------------|
| staging-support-service | HTTP | 8089 | `/support-service` | i-08d9bdc4a4fc5c313 | 8089 | ❌ Unhealthy (FailedHealthChecks) | ✅ |
| stage-users-and-verifications-tg | HTTP | 80 | `/` | i-0b6dff3f3b61d1ef5 | 8081 | ✅ Healthy | ✅ |
| staging-account-preference | HTTP | 80 | `/` | i-0973b4cfa3cad5f21 | 8086 | ✅ Healthy | ✅ |
| stage-payments-and-billing-tg | HTTP | 80 | `/` | i-0b6dff3f3b61d1ef5 | 8082 | ✅ Healthy | ✅ |
| staging-udharpay-api-tg | HTTP | 80 | `/` | i-0b6dff3f3b61d1ef5 | 8000 | ✅ Healthy | ✅ |
| staging-superkey-tg | HTTP | 80 | `/superkey` | i-08d9bdc4a4fc5c313 | 8083 | ✅ Healthy | ✅ |
| stage-dlt-stage | HTTP | 80 | `/dlt/actuator/health` | i-0973b4cfa3cad5f21 | 8082 | ✅ Healthy | ✅ |
| staging-platform-rule-engine | HTTP | 80 | `/` | i-0973b4cfa3cad5f21 | 8081 | ❌ Unhealthy (ResponseCodeMismatch) | ✅ |
| staging-platform-charge-service | HTTP | 80 | `/` | i-094e0f0dad92a536a | 8082 | ❌ Unhealthy (FailedHealthChecks) | ✅ |
| staging-platform-party-service | HTTP | 80 | `/` | i-094e0f0dad92a536a | 8083 | ❌ Unhealthy (FailedHealthChecks) | ✅ |
| stage-kyc-tg | HTTP | 80 | `/` | i-041f841420f52438d | 8246 | ❌ Unhealthy (FailedHealthChecks) | ✅ |
| stage-key-tg | HTTP | 80 | `/key` | i-08d9bdc4a4fc5c313 | 8077 | ❌ Unhealthy (FailedHealthChecks) | ✅ |
| stage-key-gateway-tg | HTTP | 80 | `/key-gateway/` | i-08d9bdc4a4fc5c313 | 8086 | ✅ Healthy | ✅ |
| stage-platform-common-tg | HTTP | 80 | `/book/actuator/health` | i-0973b4cfa3cad5f21 | 8083 | ✅ Healthy | ✅ |
| stage-product-order-tg | HTTP | 80 | `/product-order/actuator/health` | i-0973b4cfa3cad5f21 | 8089 | ✅ Healthy | ✅ |
| staging-distributor-app | HTTP | 80 | `/` | i-0b6dff3f3b61d1ef5 | 3000 | ✅ Healthy | ✅ |
| stage-lending | HTTP | 80 | `/lending/actuator/health` | i-094e0f0dad92a536a | 8088 | ❌ Unhealthy (ResponseCodeMismatch) | ✅ |
| stage-crm-tg | HTTP | 80 | `/crm/` | i-08d9bdc4a4fc5c313 | 8087 | ✅ Healthy | ✅ |
| staging-ai-apps | HTTP | 80 | `/support-agent/health` | i-0d6db633656022c04 | 3000 | ✅ Healthy | ✅ |

---

## ⚠️ Notable Gaps in Priority Numbers

Priorities **16, 17, 20, 23, 29, 31, 32** are unused/missing. These were likely deleted rules.

---

## Result: **ALL DATA VERIFIED ✅**

Every listener, rule, target group, target instance, port, health check path, and health status from the raw JSON audit files is accurately represented in the swimlanes diagram.
