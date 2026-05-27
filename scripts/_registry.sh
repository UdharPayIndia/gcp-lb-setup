#!/usr/bin/env bash
# Helpers shared by lb_export.sh / lb_diff.sh / lb_apply.sh.
# Reads lb-state/registry.yaml and resolves a state_file path to its
# project / url_map / scope. Sourced; do not execute directly.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REGISTRY="$REPO_ROOT/lb-state/registry.yaml"

require_yq() {
  if ! command -v yq >/dev/null 2>&1; then
    echo "ERROR: 'yq' is required (https://github.com/mikefarah/yq). On macOS: brew install yq" >&2
    exit 1
  fi
}

# Resolve <state_file> (e.g. "stage/api-services-and-apps.yaml" — with or without .yaml)
# Exports: LB_STATE_FILE, LB_STATE_PATH, LB_PROJECT, LB_URL_MAP, LB_SCOPE, LB_SCOPE_FLAG, LB_ENV
resolve_lb() {
  local input="$1"
  # Normalize: strip trailing .yaml so callers can pass either form
  local key="${input%.yaml}.yaml"

  require_yq

  local matches
  matches="$(yq eval -o=json '.load_balancers[] | select(.state_file == "'"$key"'")' "$REGISTRY")"
  if [[ -z "$matches" || "$matches" == "null" ]]; then
    echo "ERROR: no registry entry for state_file '$key' in $REGISTRY" >&2
    echo "Available entries:" >&2
    yq eval '.load_balancers[].state_file' "$REGISTRY" >&2
    exit 1
  fi

  LB_STATE_FILE="$key"
  LB_STATE_PATH="$REPO_ROOT/lb-state/$key"
  LB_PROJECT="$(echo "$matches"  | yq eval -p=json '.project'  -)"
  LB_URL_MAP="$(echo "$matches"  | yq eval -p=json '.url_map'  -)"
  LB_SCOPE="$(echo "$matches"    | yq eval -p=json '.scope'    -)"
  LB_ENV="$(echo "$matches"      | yq eval -p=json '.env'      -)"

  if [[ "$LB_SCOPE" == "global" ]]; then
    LB_SCOPE_FLAG="--global"
  elif [[ "$LB_SCOPE" == region:* ]]; then
    LB_SCOPE_FLAG="--region=${LB_SCOPE#region:}"
  else
    echo "ERROR: invalid scope '$LB_SCOPE' for $key — expected 'global' or 'region:<region>'" >&2
    exit 1
  fi

  if [[ ! -f "$LB_STATE_PATH" ]] && [[ "${ALLOW_MISSING_STATE:-0}" != "1" ]]; then
    echo "ERROR: state file missing: $LB_STATE_PATH" >&2
    exit 1
  fi
}

# Strip the fingerprint line from a URL-map YAML — stored state must never
# carry one (it's optimistic-concurrency, goes stale on any out-of-band change).
strip_fingerprint() {
  local src="$1" dst="$2"
  grep -v '^fingerprint:' "$src" > "$dst"
}

# Fetch the current live fingerprint for an LB. Writes it to stdout.
fetch_live_fingerprint() {
  gcloud compute url-maps describe "$LB_URL_MAP" \
    --project="$LB_PROJECT" $LB_SCOPE_FLAG \
    --format="value(fingerprint)"
}

# List every state_file in the registry, one per line.
list_lbs() {
  require_yq
  yq eval '.load_balancers[].state_file' "$REGISTRY"
}
