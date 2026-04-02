#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# present.sh
# Pre-presentation orchestrator.
# Calls each individual script in order and exits on first failure.
#
# Individual scripts can also be run independently:
#   ./scripts/start-minikube.sh
#   ./scripts/deploy-k8s.sh
#   ./scripts/migrate-db.sh
#   ./scripts/setup-monitoring.sh
#   ./scripts/forward-grafana.sh
#   ./scripts/start-ngrok.sh
# ─────────────────────────────────────────────────────────────
set -euo pipefail

SCRIPTS_DIR="$(cd "$(dirname "$0")" && pwd)"

header() {
  echo ""
  echo "╔══════════════════════════════════════════════════╗"
  printf  "║  %-48s║\n" "$1"
  echo "╚══════════════════════════════════════════════════╝"
}

START=$(date +%s)

header "Step 1/6 – Start Minikube"
bash "$SCRIPTS_DIR/start-minikube.sh"

header "Step 2/6 – Deploy Kubernetes Resources"
bash "$SCRIPTS_DIR/deploy-k8s.sh"

header "Step 3/6 – Run Database Migrations"
bash "$SCRIPTS_DIR/migrate-db.sh"

header "Step 4/6 – Install Monitoring Stack"
bash "$SCRIPTS_DIR/setup-monitoring.sh"

header "Step 5/6 – Start Grafana Port-Forward"
bash "$SCRIPTS_DIR/forward-grafana.sh"

header "Step 6/6 – Start ngrok Tunnel"
bash "$SCRIPTS_DIR/start-ngrok.sh"

END=$(date +%s)
ELAPSED=$(( END - START ))

echo ""
echo "╔══════════════════════════════════════════════════╗"
echo "║  ✅  MoodLite is READY for presentation!         ║"
echo "╠══════════════════════════════════════════════════╣"
echo "║  App (local):   http://moodlite.local            ║"
echo "║  Grafana:       http://localhost:3000             ║"
echo "║  ngrok URL:     see output above                 ║"
echo "║  Load test:     ./scripts/load-test.sh           ║"
printf "║  Setup time:    %-33s║\n" "${ELAPSED}s"
echo "╚══════════════════════════════════════════════════╝"
