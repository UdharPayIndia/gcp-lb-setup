# gcp-networking-setup

Single source of truth for our GCP global load-balancer URL maps.
Engineers edit YAML state files; a Cloud Build pipeline applies them to live.

The GCP console has no built-in change-review or change-history flow for URL
maps, and running `gcloud compute url-maps import` from a laptop is unsafe at
team scale. This repo is the fix.

---

## Layout

```
.
├── lb-state/                              # IaC state — edit these to change routing
│   ├── registry.yaml                      #   which YAML → which live URL map
│   ├── stage/                             #   per-env state files
│   │   └── api-services-and-apps.yaml
│   └── prod/                              #   placeholder for future
│
├── scripts/                               # IaC tooling (run locally)
│   ├── _registry.sh                       #   shared helper, sourced by the others
│   ├── lb_export.sh  <state_file>         #   live → repo  (snapshot)
│   ├── lb_diff.sh    <state_file>         #   diff repo vs live (read-only)
│   └── lb_apply.sh   <state_file> [--yes] #   repo → live  (apply)
│
├── ci/
│   └── cloudbuild.yaml                    # pipeline that runs on push to main
│
├── load-balancers/                        # per-LB scaffolding from the AWS→GCP migration
│   ├── stage-udharpay-api/                #   (AWS: stage-udharpay-api-lb)
│   │   ├── gcp-setup/                     #     one-time scripts that built the GCP equivalent
│   │   │   ├── 01_vms.sh
│   │   │   ├── 01aa_create_secrets.sh
│   │   │   ├── 01ab_deploy_cloud_run_services.sh
│   │   │   ├── 01ac_update_cloud_run_image.sh
│   │   │   ├── 02_target_groups.sh
│   │   │   ├── 03_rules.sh
│   │   │   ├── 04_load_balancer.sh
│   │   │   ├── 05_test_routing.sh
│   │   │   ├── 99_destroy_all.sh
│   │   │   └── README.md
│   │   ├── comparison-aws-vs-gcp.md
│   │   └── swimlanes.txt
│   ├── stage-rpg/                         #   (AWS: stage-rpg-lb)
│   │   ├── gcp-setup/
│   │   │   ├── 01_target_groups.sh
│   │   │   └── 02_rules.sh
│   │   ├── rule-migration.md
│   │   └── swimlanes.txt
│   └── stage-udharpay-admin/              #   (AWS: staging-udharpay-admin-lb)
│       ├── gcp-setup/
│       │   ├── 01_target_groups.sh
│       │   └── 02_rules.sh
│       ├── rule-migration.md
│       └── swimlanes.txt
│   # Note: aws-audit/ directories are gitignored (local-only AWS snapshots)
│
├── infra/                                 # shared GCP infrastructure setup
│   ├── ssl-cert-setup/                    #   GCP managed-cert provisioning
│   │   ├── 01_dns_auth.sh
│   │   ├── 02_create_cert.sh
│   │   ├── 03_attach_cert.sh
│   │   └── README.md
│   ├── cloudbuild-triggers/               #   triggers for service repos (not this one)
│   │   └── service-repo-triggers.sh
│   └── vm-setup/                          #   JRE / Docker / arm64 migration helpers
│       ├── jdk-jre-env-setup.sh
│       ├── setup-jre.sh
│       ├── from-gcp1-to-gcp-arm64.sh
│       └── demo-docker-compose.yaml
│   # Note: nginx-proxy-to-gcp/ (AWS cutover bridge) is not tracked — see local-docs/
│
├── docs/                                  # cross-cutting documentation
│   ├── lb-audit-crosscheck.md             #   AWS↔GCP audit verification
│   ├── port-conflict-unified-routing.md   #   port remapping rationale
│   └── swimlanes-io-syntax.txt
│
└── pre-migration-apis-testing/            # API coverage tooling
    ├── all-requests.txt
    ├── extract_unique_apis.py
    └── generate_postman_collection.py
    # Note: HAR captures, Postman exports, and env files are gitignored
```

**Gitignored (local-only, never committed):**
- `load-balancers/*/aws-audit/` — raw AWS LB JSON snapshots
- `local-docs/` — local reference material (nginx configs, architecture notes, etc.)
- `temp/` — scratch exports; may contain plaintext secrets from GCP resource dumps
- `*.har`, Postman exports, `*.env`, `*.pem`, `*.key`, credential files

Only `lb-state/`, `scripts/`, and `ci/` are consumed by the live-update
pipeline. Everything else is migration documentation and one-time setup
scripts kept for reference.

---

## Engineer workflow

### Change LB routing (most common)

1. Find the right state file under `lb-state/<env>/` (see registry).
2. Edit the YAML. Add/remove/reorder `routeRules`, change `service:` URLs, etc.
3. Preview the diff against live (read-only, safe):

   ```bash
   ./scripts/lb_diff.sh stage/api-services-and-apps
   ```
4. Open a PR. The reviewer checks the YAML diff.
5. Merge to `main`. Cloud Build picks it up and applies it within a couple of
   minutes. Watch the build in the GCP console.

### Snapshot live state into the repo

Use after an out-of-band change (console / one-off gcloud) you want to capture:

```bash
./scripts/lb_export.sh stage/api-services-and-apps
git diff -- lb-state/stage/api-services-and-apps.yaml   # review
git add lb-state/stage/api-services-and-apps.yaml
git commit -m "snapshot stage URL map"
```

### Add a new LB

1. Create the LB and URL map in GCP (via the existing per-LB setup scripts, or
   the console).
2. Append an entry to `lb-state/registry.yaml`:

   ```yaml
   - state_file: prod/api-services-and-apps.yaml
     project: rocketpay-gcp-prod   # or wherever it lives
     url_map: prod-lb-as1-api-services-and-apps
     scope: global                 # or "region:asia-south1" for regional LBs
     env: prod
   ```
3. Snapshot it:

   ```bash
   ./scripts/lb_export.sh prod/api-services-and-apps
   ```
4. Commit registry + state file together.

---

## Prerequisites (one-time)

### Local

```bash
brew install yq                              # macOS — required for the scripts
gcloud auth application-default login         # if not already
gcloud config set project rocketpay-gcp-setup
```

### CloudBuild trigger

1. Push this repo to your chosen remote (GitHub / Cloud Source Repositories).
2. Create a service account dedicated to LB IaC:

   ```bash
   gcloud iam service-accounts create lb-iac-cloudbuild \
     --project=rocketpay-gcp-setup \
     --display-name="LB IaC Cloud Build"
   ```
3. Grant it the minimum roles **on every project that hosts an LB referenced
   in registry.yaml**:

   ```bash
   gcloud projects add-iam-policy-binding rocketpay-gcp-setup \
     --member="serviceAccount:lb-iac-cloudbuild@rocketpay-gcp-setup.iam.gserviceaccount.com" \
     --role="roles/compute.loadBalancerAdmin"
   gcloud projects add-iam-policy-binding rocketpay-gcp-setup \
     --member="serviceAccount:lb-iac-cloudbuild@rocketpay-gcp-setup.iam.gserviceaccount.com" \
     --role="roles/logging.logWriter"
   ```
4. Create the trigger (adjust repo flags for GitHub vs CSR — see header comment
   in [ci/cloudbuild.yaml](ci/cloudbuild.yaml) for the GitHub flavor).

---

## How the pipeline behaves

The pipeline is **idempotent and convergent**:

- Iterates every entry in `lb-state/registry.yaml`.
- For each, fetches the live URL map, strips fingerprint, diffs against repo state.
- If different, re-fetches a fresh fingerprint and runs `gcloud compute url-maps import`.
- After import, re-fetches and verifies the live state now matches repo.

Consequences worth understanding:

- **The repo is the source of truth.** Any change made via console or ad-hoc
  gcloud that contradicts `lb-state/` will be reverted on the next merge to `main`.
  If you need to make an emergency console change, follow it up with
  `lb_export.sh` and a PR to lock it in.
- **Fingerprint is never stored in the repo.** It's GCP's optimistic-concurrency
  token; storing it would make every out-of-band touch stale the file. Scripts
  fetch it fresh at apply time.
- **`registry.yaml` is the index.** A YAML in `lb-state/` that isn't in the registry
  is ignored by the pipeline.

---

## Security / secrets

This repo handles routing configuration only. Backend services are referenced
by URL; nothing here authenticates to anything. But adjacent directories used
to hold raw GCP exports that did carry plaintext secrets. The `.gitignore`
blocks the usual offenders:

- `temp/` — raw Cloud Run / URL-map exports may contain plaintext env-var
  secrets. Treat as scratch space; never `git add temp/<anything>`.
- `*.har`, `pre-migration-apis-testing/transactions.*`, `rocketpay_env.json`,
  `rocketpay_collection.json` — captured staging traffic / Postman exports
  contain JWTs.
- `*.pem`, `*.key`, `*.env`, `service-account*.json`, `credentials*.json`.

**Known follow-up:** The live `api` Cloud Run service may still have
`AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` / `NEWRELIC_LICENSE_KEY` as
plaintext env vars. The deploy script (`load-balancers/stage-udharpay-api/gcp-setup/01ab_deploy_cloud_run_services.sh`)
already uses `--set-secrets` to pull these from Secret Manager on next deploy.
Prerequisite: create the three Secret Manager entries
(`rp-stage-secret-api-aws-access-key-id`, `rp-stage-secret-api-aws-secret-access-key`,
`rp-stage-secret-api-newrelic-license-key`) and rotate the keys at source before
re-deploying.
