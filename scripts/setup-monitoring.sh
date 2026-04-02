#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# setup-monitoring.sh
# Adds the prometheus-community Helm repo and installs (or upgrades)
# kube-prometheus-stack into the `monitoring` namespace.
# ─────────────────────────────────────────────────────────────
set -euo pipefail

MONITORING_DIR="$(cd "$(dirname "$0")/../monitoring" && pwd)"
RELEASE="monitoring"
CHART="prometheus-community/kube-prometheus-stack"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  📊  Setting up Prometheus + Grafana"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Add + update Helm repo
echo "⏳  Adding prometheus-community Helm repo…"
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts 2>/dev/null || true
helm repo update

# Install or upgrade
if helm status "$RELEASE" -n monitoring &>/dev/null; then
  echo "⏳  Upgrading existing monitoring release…"
  helm upgrade "$RELEASE" "$CHART" \
    -n monitoring \
    -f "$MONITORING_DIR/values.yaml" \
    --wait --timeout 5m
else
  echo "⏳  Installing monitoring stack…"
  helm install "$RELEASE" "$CHART" \
    -n monitoring \
    --create-namespace \
    -f "$MONITORING_DIR/values.yaml" \
    --wait --timeout 5m
fi

echo ""
echo "📋  Monitoring pods:"
kubectl get pods -n monitoring
echo ""
echo "✅  Prometheus + Grafana installed."
echo "   Run ./scripts/forward-grafana.sh to access Grafana at http://localhost:3000"
echo "   Login: admin / moodlite-grafana"
