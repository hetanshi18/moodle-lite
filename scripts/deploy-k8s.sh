#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# deploy-k8s.sh
# Applies all Kubernetes manifests in dependency order and
# waits for all pods to reach Running/Ready state.
# ─────────────────────────────────────────────────────────────
set -euo pipefail

NAMESPACE="moodlite"
K8S_DIR="$(cd "$(dirname "$0")/../k8s" && pwd)"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  📦  Deploying MoodLite to Kubernetes"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

apply() {
  echo "  ➤ Applying $1…"
  kubectl apply -f "$K8S_DIR/$1"
}

# 1 – Namespace first
apply namespace.yaml

# 2 – Config and secrets
apply configmap.yaml
apply secret.yaml

# 3 – Storage
apply postgres-pv.yaml
apply postgres-pvc.yaml

# 4 – Database
apply postgres-deployment.yaml
apply postgres-service.yaml

# 5 – Application
apply app-deployment.yaml
apply app-service.yaml

# 6 – Ingress and autoscaling
apply ingress.yaml
apply hpa.yaml

echo ""
echo "⏳  Waiting for Postgres to be ready…"
kubectl rollout status deployment/postgres -n "$NAMESPACE" --timeout=120s

echo "⏳  Waiting for MoodLite app to be ready…"
kubectl rollout status deployment/moodlite-app -n "$NAMESPACE" --timeout=120s

echo ""
echo "📋  Pod status:"
kubectl get pods -n "$NAMESPACE"
echo ""
echo "📋  Services:"
kubectl get svc -n "$NAMESPACE"
echo ""
echo "📋  Ingress:"
kubectl get ingress -n "$NAMESPACE"
echo ""
echo "✅  Deployment complete."
