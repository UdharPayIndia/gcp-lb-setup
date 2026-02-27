# Comparison: AWS Application Load Balancer vs. GCP External HTTP(S) Load Balancer

This document compares the routing and rule management logic between AWS ALB and GCP Global External HTTP(S) Load Balancer, specifically in the context of the `stage-udharpay-api-lb` migration.

## 1. High-Level Terminology

| Component | AWS ALB | GCP Load Balancer |
| :--- | :--- | :--- |
| **Routing Body** | Listener Rules | URL Map |
| **Target Group equivalent** | Target Group (TG) | Backend Service (BS) |
| **Health Check** | Defined on Target Group | Global Health Check Resource |
| **Default Action** | Default Rule (always priority 'last') | `defaultService` / `defaultRouteAction` |
| **SSL Management** | ACM Certificates | Google-managed or Self-managed SSL Certs |

## 2. Rule Evaluation & Priority

### AWS (Listener Rules)
- Rules are evaluated **sequentially** based on a numerical priority.
- The first rule that matches "wins."
- **Note**: AWS uses a very strict 1-50,000 priority range.

### GCP (URL Map)
- GCP also uses numerical priorities within `routeRules`.
- **Lower numbers take precedence** (evaluated first).
- **Architecture Difference**: In GCP, **Host Rules** are matched *before* Path Matchers. You cannot interleave host-based rules with general path rules in a single list like you can in AWS.

## 3. Path Matching Logic

One of the most critical differences is how strings are matched.

| Feature | AWS ALB | GCP URL Map |
| :--- | :--- | :--- |
| **Style** | Glob-style patterns (e.g., `/api/*`) | Prefix/Full/Regex matches |
| **Prefix Match** | `/api*` or `/api/*` | `prefixMatch: "/api/"` |
| **Exact Match** | Path = `/health` | `fullPathMatch: "/health"` |
| **Regex Support**| Supported in Path conditions | Supported in `pathMatchers` (requires advanced Tier) |

**Migration Tip**: In AWS, `/api*` matches both `/api` and `/api/v1`. In GCP, `prefixMatch: "/api/"` only matches paths starting with the directory. For the migration, we transitioned your AWS star patterns to GCP **prefixMatch** to ensure identical behavior for subdirectory routing.

## 4. Host-Based Routing

### AWS
- Host headers are just another "condition" within a rule.
- A rule can combine `Host: abc.com` AND `Path: /api/*`.

### GCP
- Host rules are a top-level property of the URL Map.
- They map a hostname (e.g., `staging-distributor.rocketpay.co.in`) to a **Path Matcher**.
- **Impact**: Traffic for your distributor domain bypasses the entire "Main" path table and goes straight to its own dedicated path logic, which is more performant but slightly less flexible if you wanted to mix domains in one path list.

## 5. Operations & State Management

### AWS (Individual Rules)
- Rules are typically managed as individual resources (e.g., via Terraform `aws_lb_listener_rule` or CLI commands).
- Changing one rule doesn't usually require re-sending the others.

### GCP (Monolithic YAML/JSON)
- The URL Map is a single, unified resource.
- **Import/Export**: You typically manage the entire map of 30+ rules as a single YAML file (like the one we created).
- **Atomic Updates**: When you run `gcloud compute url-maps import`, the entire routing table is replaced atomically. This prevents "partial state" where some rules are updated but others aren't.

## 6. Port Management (Single VM Consolidation)

In your specific migration:
- **AWS**: Used 6 EC2 instances. Port 8081 on `VM_A` didn't conflict with Port 8081 on `VM_B`.
- **GCP**: Using 1 consolidated VM. We had to shift conflicting services to new ports (e.g., `rule-engine` moved to `8084`) while keeping the Load Balancer "Named Ports" mapped to these new values.

---
*Created for the RocketPay Staging Environment Migration (Feb 2026)*
