#!/bin/bash
# MoodLite Status Check Script
# Shows what services are currently running

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
GRAY='\033[0;37m'
NC='\033[0m'

header() {
    echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

check_service() {
    if curl -s "$1" > /dev/null 2>&1; then
        echo -e "   ${GREEN}✅ UP${NC} - $2 ($1)"
    else
        echo -e "   ${RED}❌ DOWN${NC} - $2 ($1)"
    fi
}

header "🔍 MoodLite Services Status"

echo ""
echo -e "${YELLOW}Docker Compose Services:${NC}"
docker-compose ps 2>/dev/null || echo -e "   ${RED}No services running${NC}"

echo ""
echo -e "${YELLOW}Monitoring Stack:${NC}"
docker-compose -f docker-compose.monitoring.yml ps 2>/dev/null || echo -e "   ${RED}Monitoring stack not running${NC}"

echo ""
echo -e "${YELLOW}Service Health Checks:${NC}"
check_service "http://localhost:5000" "Flask Application"
check_service "http://localhost:5432" "PostgreSQL Database"
check_service "http://localhost:9090" "Prometheus"
check_service "http://localhost:3000" "Grafana"
check_service "http://localhost:9093" "Alertmanager"
check_service "http://localhost:9100" "Node Exporter"

echo ""
echo -e "${YELLOW}Kubernetes/Minikube:${NC}"
if command -v minikube &> /dev/null; then
    MINIKUBE_STATUS=$(minikube status 2>/dev/null | grep "minikube:" | awk '{print $2}')
    if [ "$MINIKUBE_STATUS" = "Running" ]; then
        echo -e "   ${GREEN}✅ Minikube is Running${NC}"
        echo -e "   ${GRAY}   IP: $(minikube ip)${NC}"
        echo -e "   ${GRAY}   Kubectl available: $(command -v kubectl &> /dev/null && echo "Yes" || echo "No")${NC}"
    else
        echo -e "   ${RED}❌ Minikube is Stopped${NC}"
    fi
else
    echo -e "   ${RED}❌ Minikube not installed${NC}"
fi

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${BLUE}📊 Quick Links:${NC}"
echo -e "   App:         http://localhost:5000"
echo -e "   Prometheus:  http://localhost:9090" 
echo -e "   Grafana:     http://localhost:3000"
echo ""
echo -e "${BLUE}📋 Useful Commands:${NC}"
echo -e "   Start all:   ${YELLOW}bash scripts/start-all.sh${NC}"
echo -e "   Stop all:    ${YELLOW}bash scripts/stop-all.sh${NC}"
echo -e "   View logs:   ${YELLOW}docker-compose logs -f${NC}"
echo ""
