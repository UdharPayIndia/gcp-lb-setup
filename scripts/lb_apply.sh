#!/usr/bin/env bash
# Apply the repo state file to the live GCP URL map.
# Fetches the live fingerprint (optimistic-concurrency token), injects it
# into the YAML, imports, then re-fetches to verify the apply landed.
#
# Usage:   ./scripts/lb_apply.sh <state_file> [--yes]
# Example: ./scripts/lb_apply.sh stage/api-services-and-apps.yaml
#
# Without --yes, prints the diff and prompts before applying.
# CI/CloudBuild should pass --yes.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/_registry.sh"

if [[ $# -lt 1 || $# -gt 2 ]]; then
  echo "Usage: $0 <state_file> [--yes]" >&2
  echo "Available state files:" >&2
  list_lbs >&2
  exit 1
fi

resolve_lb "$1"
AUTO_YES=0
if [[ "${2:-}" == "--yes" ]]; then AUTO_YES=1; fi

# ─── Step 1: Show diff so the operator knows what's about to change ───
LIVE_TMP="$(mktemp)"
LIVE_STRIPPED="$(mktemp)"
PATCHED="$(mktemp)"
trap 'rm -f "$LIVE_TMP" "$LIVE_STRIPPED" "$PATCHED"' EXIT

echo "==> Fetching live $LB_URL_MAP from $LB_PROJECT ($LB_SCOPE)..."
gcloud compute url-maps export "$LB_URL_MAP" \
  --project="$LB_PROJECT" $LB_SCOPE_FLAG \
  --destination="$LIVE_TMP"

strip_fingerprint "$LIVE_TMP" "$LIVE_STRIPPED"

echo ""
echo "==> Diff repo → live:"
if diff -u "$LIVE_STRIPPED" "$LB_STATE_PATH" \
     --label "live:$LB_URL_MAP" \
     --label "repo:lb-state/$LB_STATE_FILE"; then
  echo ""
  echo "✓ Repo state already matches live. Nothing to apply."
  exit 0
fi

# ─── Step 2: Confirm ───
if [[ "$AUTO_YES" -ne 1 ]]; then
  echo ""
  read -r -p "Apply this diff to live $LB_URL_MAP? [y/N] " ans
  if [[ "$ans" != "y" && "$ans" != "Y" ]]; then
    echo "Aborted."
    exit 1
  fi
fi

# ─── Step 3: Inject fresh live fingerprint and import ───
FINGERPRINT="$(fetch_live_fingerprint)"
if [[ -z "$FINGERPRINT" ]]; then
  echo "ERROR: could not fetch live fingerprint." >&2
  exit 1
fi

# Prepend fingerprint line to the patched file — gcloud accepts it anywhere
# in the top-level mapping; first line is fine.
{
  echo "fingerprint: $FINGERPRINT"
  cat "$LB_STATE_PATH"
} > "$PATCHED"

echo ""
echo "==> Importing into $LB_URL_MAP (fingerprint=$FINGERPRINT)..."
gcloud compute url-maps import "$LB_URL_MAP" \
  --project="$LB_PROJECT" $LB_SCOPE_FLAG \
  --source="$PATCHED" \
  --quiet

# ─── Step 4: Verify post-apply ───
VERIFY_TMP="$(mktemp)"
VERIFY_STRIPPED="$(mktemp)"
gcloud compute url-maps export "$LB_URL_MAP" \
  --project="$LB_PROJECT" $LB_SCOPE_FLAG \
  --destination="$VERIFY_TMP"
strip_fingerprint "$VERIFY_TMP" "$VERIFY_STRIPPED"

if diff -q "$LB_STATE_PATH" "$VERIFY_STRIPPED" >/dev/null; then
  echo ""
  echo "✓ Apply verified: live now matches lb-state/$LB_STATE_FILE."
  rm -f "$VERIFY_TMP" "$VERIFY_STRIPPED"
else
  echo ""
  echo "⚠ Post-apply verify shows residual diff — investigate:" >&2
  diff -u "$LB_STATE_PATH" "$VERIFY_STRIPPED" \
    --label "repo:lb-state/$LB_STATE_FILE" \
    --label "live:$LB_URL_MAP (after import)" >&2
  rm -f "$VERIFY_TMP" "$VERIFY_STRIPPED"
  exit 1
fi
