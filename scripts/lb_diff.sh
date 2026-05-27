#!/usr/bin/env bash
# Show the diff between live GCP URL map and the repo state file.
# Read-only: never modifies live or repo.
#
# Usage:   ./scripts/lb_diff.sh <state_file>
# Example: ./scripts/lb_diff.sh stage/api-services-and-apps.yaml
#
# Exit codes:
#   0 — no diff
#   1 — diff present (use with `if`/`||` in CI for change detection)
#   2 — error fetching live state

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/_registry.sh"

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <state_file>" >&2
  echo "Available state files:" >&2
  list_lbs >&2
  exit 2
fi

resolve_lb "$1"

LIVE_TMP="$(mktemp)"
LIVE_STRIPPED="$(mktemp)"
trap 'rm -f "$LIVE_TMP" "$LIVE_STRIPPED"' EXIT

echo "Fetching live $LB_URL_MAP from $LB_PROJECT ($LB_SCOPE)..." >&2
gcloud compute url-maps export "$LB_URL_MAP" \
  --project="$LB_PROJECT" $LB_SCOPE_FLAG \
  --destination="$LIVE_TMP" >&2

strip_fingerprint "$LIVE_TMP" "$LIVE_STRIPPED"

# diff exit codes: 0 same, 1 differ, 2 trouble.
if diff -u "$LB_STATE_PATH" "$LIVE_STRIPPED" \
     --label "repo:lb-state/$LB_STATE_FILE" \
     --label "live:$LB_URL_MAP"; then
  echo "" >&2
  echo "✓ No diff — repo state matches live LB." >&2
  exit 0
else
  echo "" >&2
  echo "✗ Diff present — running lb_apply.sh would push the repo state to live." >&2
  exit 1
fi
