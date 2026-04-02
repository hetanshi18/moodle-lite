#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# forward-grafana.sh
# Port-forwards Grafana to localhost:3000.
# Runs in the background and prints the PID.
# Kill it with:  kill $(cat /tmp/grafana-pf.pid)
# ─────────────────────────────────────────────────────────────
set -euo pipefail

LOCAL_PORT="${GRAFANA_PORT:-3000}"
PID_FILE="/tmp/grafana-pf.pid"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  📈  Starting Grafana Port-Forward"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Kill any existing port-forward on that port
if [ -f "$PID_FILE" ]; then
  OLD_PID=$(cat "$PID_FILE")
  if kill -0 "$OLD_PID" 2>/dev/null; then
    echo "  Stopping previous port-forward (PID $OLD_PID)…"
    kill "$OLD_PID" || true
  fi
  rm -f "$PID_FILE"
fi

# Find Grafana pod
GRAFANA_POD=$(kubectl get pod -n monitoring \
  -l "app.kubernetes.io/name=grafana" \
  -o jsonpath='{.items[0].metadata.name}')

echo "  Found Grafana pod: $GRAFANA_POD"

# Start port-forward in background
kubectl port-forward "$GRAFANA_POD" "${LOCAL_PORT}:3000" -n monitoring &>/tmp/grafana-pf.log &
BG_PID=$!
echo "$BG_PID" > "$PID_FILE"

sleep 2

echo ""
echo "✅  Grafana is available at:  http://localhost:${LOCAL_PORT}"
echo "   Username: admin"
echo "   Password: moodlite-grafana"
echo "   Port-forward PID: $BG_PID  (saved to $PID_FILE)"
echo ""
echo "   To stop:  kill \$(cat $PID_FILE)"
