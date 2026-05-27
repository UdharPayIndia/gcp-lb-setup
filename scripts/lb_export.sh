#!/usr/bin/env bash
# Fetch the live URL map and write it into the repo as the new state file.
# Use this when you've made changes via gcloud/console out-of-band and need
# to sync the repo back to reality, OR for the first-time snapshot of a new LB.
#
# Usage:   ./scripts/lb_export.sh <state_file>
# Example: ./scripts/lb_export.sh stage/api-services-and-apps.yaml
#          ./scripts/lb_export.sh stage/api-services-and-apps      # .yaml optional
#
# Side effects: overwrites lb-state/<state_file> with the live export.
#               fingerprint is stripped — review the diff before committing.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/_registry.sh"

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <state_file>" >&2
  echo "Available state files:" >&2
  list_lbs >&2
  exit 1
fi

ALLOW_MISSING_STATE=1 resolve_lb "$1"

TMP="$(mktemp)"
trap 'rm -f "$TMP"' EXIT

echo "Exporting $LB_URL_MAP from project $LB_PROJECT ($LB_SCOPE)..."
gcloud compute url-maps export "$LB_URL_MAP" \
  --project="$LB_PROJECT" $LB_SCOPE_FLAG \
  --destination="$TMP"

mkdir -p "$(dirname "$LB_STATE_PATH")"
strip_fingerprint "$TMP" "$LB_STATE_PATH"

echo ""
echo "Wrote: $LB_STATE_PATH"
echo "Review diff with:  git diff -- lb-state/$LB_STATE_FILE"
