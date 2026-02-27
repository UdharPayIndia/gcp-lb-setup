# Side-by-Side Migration Mapping: AWS ALB to GCP URL Map

This table shows exactly how each AWS Listener Rule was translated into a GCP URL Map configuration for the `stage-lb-as1-udharpay-api` migration.

| AWS Priority | AWS Condition (Glob) | AWS Target Group | GCP Priority | GCP Match Logic | GCP Backend Service |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **P1** | `/support-service/*` | `staging-support-service` | **100** | `prefixMatch: "/support-service/"` | `stage-bs-as1-support-service` |
| **P2** | `/account/v2/authenticate` | `stage-users-and-verifications` | **110** | `fullPathMatch: "/account/v2/authenticate"` | `stage-bs-as1-users-and-verifications` |
| **P3** | `/account/*` | `staging-account-preference` | **120** | `prefixMatch: "/account/"` | `stage-bs-as1-account-preference` |
| **P4** | `/account-preference/*` | `staging-account-preference` | **130** | `prefixMatch: "/account-preference/"` | `stage-bs-as1-account-preference` |
| **P5-1** | `/payments-and-billing/*` | `stage-payments-and-billing` | **140** | `prefixMatch: "/payments-and-billing/"` | `stage-bs-as1-payments-and-billing` |
| **P5-2** | `/ab-experiment/*` | `stage-payments-and-billing` | **140** | `prefixMatch: "/ab-experiment/"` | `stage-bs-as1-payments-and-billing` |
| **P6** | `/common/wallets/*`, `/common/party/*`, etc. | `stage-payments-and-billing` | **150** | `prefixMatch: [multiple]` | `stage-bs-as1-payments-and-billing` |
| **P7** | `/v1/merchant/kyc*`, `/api/banks*`, etc. | `stage-payments-and-billing` | **160** | `prefixMatch: [multiple]` | `stage-bs-as1-payments-and-billing` |
| **P8** | `/api/mas/*`, `/api/system-status`, etc. | `stage-payments-and-billing` | **170** | `prefixMatch` / `fullPathMatch` | `stage-bs-as1-payments-and-billing` |
| **P9** | `/v1/merchant/*`, `/api/merchant/auth*`, etc. | `staging-udharpay-api` | **180** | `prefixMatch` / `fullPathMatch` | `stage-bs-as1-udharpay-api` |
| **P10** | `/api/merchant/*` | `stage-payments-and-billing` | **190** | `prefixMatch: "/api/merchant/"` | `stage-bs-as1-payments-and-billing` |
| **P11** | `/superkey/*`, `/rocketscore/*`, etc. | `staging-superkey` | **200** | `prefixMatch: [multiple]` | `stage-bs-as1-superkey` |
| **P12** | `/verification/*`, `/auth/*`, `/acl/*`, etc. | `stage-users-and-verifications` | **210** | `prefixMatch: [multiple]` | `stage-bs-as1-users-and-verifications` |
| **P13** | `/dlt/*` | `stage-dlt` | **220** | `prefixMatch: "/dlt/"` | `stage-bs-as1-dlt` |
| **P14** | `/v2/merchant/*`, `/api/*`, etc. | `staging-udharpay-api` | **230** | `prefixMatch: [multiple]` | `stage-bs-as1-udharpay-api` |
| **P15** | `/v4/mandates*`, `/v4/installments*` | `staging-udharpay-api` | **240** | `prefixMatch: [multiple]` | `stage-bs-as1-udharpay-api` |
| **P18** | `/rule/*` | `staging-platform-rule-engine` | **250** | `prefixMatch: "/rule/"` | `stage-bs-as1-platform-rule-engine` |
| **P19** | `/charge-service/*` | `staging-platform-charge-service` | **260** | `prefixMatch: "/charge-service/"` | `stage-bs-as1-platform-charge-service` |
| **P21** | `/party/*` | `staging-platform-party-service` | **270** | `prefixMatch: "/party/"` | `stage-bs-as1-platform-party-service` |
| **P22** | `/kyc/*`, `/workflow/*` | `stage-kyc` | **280** | `prefixMatch: [multiple]` | `stage-bs-as1-kyc` |
| **P24** | `/key/*` | `stage-key` | **290** | `prefixMatch: "/key/"` | `stage-bs-as1-key` |
| **P25** | `/key-gateway/*` | `stage-key-gateway` | **300** | `prefixMatch: "/key-gateway/"` | `stage-bs-as1-key-gateway` |
| **P26** | `/cus/*` | `stage-payments-and-billing` | **310** | `prefixMatch: "/cus/"` | `stage-bs-as1-payments-and-billing` |
| **P27** | `/book/*` | `stage-platform-common` | **320** | `prefixMatch: "/book/"` | `stage-bs-as1-platform-common` |
| **P28** | `/product-order/*` | `stage-product-order` | **330** | `prefixMatch: "/product-order/"` | `stage-bs-as1-product-order` |
| **P33** | `/lending/*` | `stage-lending` | **340** | `prefixMatch: "/lending/"` | `stage-bs-as1-lending` |
| **P34** | `/crm/*` | `stage-crm` | **350** | `prefixMatch: "/crm/"` | `stage-bs-as1-crm` |
| **P35** | `/agreement/*` | `stage-payments-and-billing` | **360** | `prefixMatch: "/agreement/"` | `stage-bs-as1-payments-and-billing` |
| **P36** | `/support-agent/*`, `/analytics-agent/*` | `staging-ai-apps` | **370** | `prefixMatch: [multiple]` | `stage-bs-as1-ai-apps` |
| **P37** | `/common/charges/*` | `stage-payments-and-billing` | **380** | `prefixMatch: "/common/charges/"` | `stage-bs-as1-payments-and-billing` |
| **P30** | `Host: staging-distributor.rocketpay.co.in` | `staging-distributor-app` | **Host Rule** | `hosts: ["staging-distributor..."]` | `stage-bs-as1-distributor-app` |

## Relatable Config Snippets (Example: Rule P1)

### Original AWS Config (approximate Terraform/CLI style):
```hcl
resource "aws_lb_listener_rule" "support_service" {
  priority     = 1
  condition {
    path_pattern { values = ["/support-service/*"] }
  }
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.support_service.arn
  }
}
```

### Relatable GCP Config (from our YAML template):
```yaml
- priority: 100
  matchRules:
  - prefixMatch: /support-service/
  service: https://www.googleapis.com/compute/v1/projects/${PROJECT_ID}/global/backendServices/stage-bs-as1-support-service
```

---
*Note: In AWS, Star patterns (`*`) are glob-based. In GCP, we use `prefixMatch` to achieve the identical "starts-with" behavior safely across all sub-paths.*
