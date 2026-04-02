#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# load-test.sh
# Sends rapid HTTP requests to the app to drive CPU up and
# trigger HPA autoscaling. Safe to run standalone at any time.
#
# Usage:
#   ./scripts/load-test.sh                        # uses moodlite.local
#   ./scripts/load-test.sh https://xxxx.ngrok.io  # uses ngrok URL
#
# Requirements: curl (always present) or `ab` (Apache Bench)
# ─────────────────────────────────────────────────────────────
set -euo pipefail

TARGET="${1:-http://moodlite.local}"
DURATION="${LOAD_DURATION:-60}"     # seconds
CONCURRENCY="${LOAD_CONCURRENCY:-20}"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  🔥  Load Test — Triggering HPA"
echo "  Target:      $TARGET"
echo "  Duration:    ${DURATION}s"
echo "  Concurrency: $CONCURRENCY"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  Watch scaling in another terminal:"
echo "  kubectl get hpa -n moodlite --watch"
echo ""

END_TIME=$(( $(date +%s) + DURATION ))

request_count=0
error_count=0

while [ "$(date +%s)" -lt "$END_TIME" ]; do
  for i in $(seq 1 "$CONCURRENCY"); do
    curl -s -o /dev/null -w "" \
      -H "Host: moodlite.local" \
      "$TARGET/" &
  done
  wait
  request_count=$(( request_count + CONCURRENCY ))
  printf "\r  Requests sent: %-6d" "$request_count"
done

echo ""
echo ""
echo "✅  Load test complete. Sent ~${request_count} requests."
echo ""
echo "  Check HPA status:"
echo "  kubectl describe hpa moodlite-app-hpa -n moodlite"
