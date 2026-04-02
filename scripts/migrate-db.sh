#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# migrate-db.sh
# Finds the running app pod and runs `flask db upgrade` inside it.
# Ensures the database schema is up to date after deployment.
# ─────────────────────────────────────────────────────────────
set -euo pipefail

NAMESPACE="moodlite"
LABEL="app=moodlite-app"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  🗄️   Running Database Migrations"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo "⏳  Waiting for app pod to be Ready…"
kubectl wait pod \
  --for=condition=Ready \
  --selector="$LABEL" \
  -n "$NAMESPACE" \
  --timeout=120s

POD=$(kubectl get pod -n "$NAMESPACE" -l "$LABEL" \
  -o jsonpath='{.items[0].metadata.name}')

echo "✅  Found pod: $POD"
echo ""
echo "⏳  Running flask db upgrade…"
kubectl exec -it "$POD" -n "$NAMESPACE" -- flask db upgrade

echo ""
echo "✅  Migrations complete."
