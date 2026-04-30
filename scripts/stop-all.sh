#!/bin/bash
# MoodLite Stop All Services Script
# Cleanly shuts down all running services

set -e

SCRIPTS_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPTS_DIR")"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

header() {
    echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
}

success() {
    echo -e "${GREEN}✅ $1${NC}\n"
}

info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

header "Stopping All MoodLite Services"

cd "$PROJECT_DIR"

# Stop Docker Compose
info "Stopping Docker Compose (App + Database)..."
docker-compose down -v || true
success "Docker Compose stopped"

# Stop Monitoring Stack
info "Stopping Monitoring Stack (Prometheus + Grafana)..."
docker-compose -f docker-compose.monitoring.yml down -v || true
success "Monitoring Stack stopped"

# Optionally stop Minikube
read -p "Stop Minikube? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    info "Stopping Minikube..."
    minikube stop || true
    success "Minikube stopped"
else
    info "Keeping Minikube running"
fi

echo -e "\n${GREEN}╔═══════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  ✅ All services have been stopped! ✅         ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════╝${NC}\n"

info "To restart everything: bash scripts/start-all.sh"
