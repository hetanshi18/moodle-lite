#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# start-ngrok.sh
# Starts an ngrok tunnel pointing at the Minikube ingress IP.
# Prints the public HTTPS URL when ready.
# ─────────────────────────────────────────────────────────────
set -euo pipefail

MINIKUBE_IP=$(minikube ip)
PID_FILE="/tmp/ngrok-pf.pid"
LOG_FILE="/tmp/ngrok.log"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  🔗  Starting ngrok tunnel"
echo "  Forwarding → http://${MINIKUBE_IP}:80"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Stop any existing ngrok
if [ -f "$PID_FILE" ]; then
  OLD_PID=$(cat "$PID_FILE")
  if kill -0 "$OLD_PID" 2>/dev/null; then
    echo "  Stopping previous ngrok (PID $OLD_PID)…"
    kill "$OLD_PID" || true
  fi
  rm -f "$PID_FILE"
fi

# Check ngrok auth token is configured
if ! ngrok config check &>/dev/null; then
  echo "❌  ngrok is not configured. Run: ngrok config add-authtoken YOUR_TOKEN"
  exit 1
fi

# Start ngrok in background
ngrok http "http://${MINIKUBE_IP}:80" \
  --host-header="moodlite.local" \
  --log="$LOG_FILE" \
  --log-format=json &>/dev/null &

NGROK_PID=$!
echo "$NGROK_PID" > "$PID_FILE"

echo "⏳  Waiting for ngrok to connect…"
sleep 4

# Extract public URL from ngrok API
PUBLIC_URL=$(curl -s http://127.0.0.1:4040/api/tunnels 2>/dev/null \
  | python3 -c "import sys, json; t=json.load(sys.stdin)['tunnels']; print([x['public_url'] for x in t if x['proto']=='https'][0])" 2>/dev/null \
  || echo "UNAVAILABLE – check ngrok dashboard at http://127.0.0.1:4040")

echo ""
echo "✅  ngrok tunnel is live!"
echo ""
echo "   🌍  Public URL:  ${PUBLIC_URL}"
echo "   📊  Dashboard:  http://127.0.0.1:4040"
echo "   PID: $NGROK_PID  (saved to $PID_FILE)"
echo ""
echo "   To stop:  kill \$(cat $PID_FILE)"
