#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# start-minikube.sh
# Starts Minikube with required resources and enables addons.
# Safe to run again if Minikube is already running.
# ─────────────────────────────────────────────────────────────
set -euo pipefail

CPUS="${MINIKUBE_CPUS:-6}"
MEMORY="${MINIKUBE_MEMORY:-10240}"     # MB
DRIVER="${MINIKUBE_DRIVER:-docker}"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  🚀  Starting Minikube"
echo "  CPUs: $CPUS   Memory: ${MEMORY}MB   Driver: $DRIVER"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

STATUS=$(minikube status --format='{{.Host}}' 2>/dev/null || echo "Stopped")

if [ "$STATUS" == "Running" ]; then
  echo "✅  Minikube is already running."
else
  minikube start \
    --cpus="$CPUS" \
    --memory="$MEMORY" \
    --driver="$DRIVER" \
    --delete-on-failure=true
  echo "✅  Minikube started."
fi

echo ""
echo "🔌  Enabling required addons…"
minikube addons enable ingress
minikube addons enable metrics-server
minikube addons enable storage-provisioner

echo ""
echo "📋  Cluster info:"
kubectl cluster-info
echo ""
echo "✅  Minikube is ready."
