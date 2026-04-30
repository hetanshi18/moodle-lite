#!/bin/bash
# MoodLite Master Startup Script
# Starts all services: Docker Compose (App + DB) + Monitoring Stack + (Optional) Minikube

set -e

SCRIPTS_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPTS_DIR")"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
header() {
    echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
}

success() {
    echo -e "${GREEN}✅ $1${NC}\n"
}

warning() {
    echo -e "${YELLOW}⚠️  $1${NC}\n"
}

error() {
    echo -e "${RED}❌ $1${NC}\n"
    exit 1
}

info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Check prerequisites
check_prerequisites() {
    header "Checking Prerequisites"
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        error "Docker is not installed. Please install Docker Desktop."
    fi
    success "Docker found"
    
    # Check Docker Compose
    if ! command -v docker-compose &> /dev/null; then
        error "Docker Compose is not installed."
    fi
    success "Docker Compose found"
    
    # Check if Docker daemon is running
    if ! docker ps &> /dev/null; then
        error "Docker daemon is not running. Please start Docker Desktop."
    fi
    success "Docker daemon is running"
}

# Function to start Docker Compose
start_docker_compose() {
    header "Step 1/3: Starting Docker Compose (App + Database)"
    
    cd "$PROJECT_DIR"
    
    info "Building images..."
    docker-compose build --no-cache
    
    info "Starting services..."
    docker-compose up -d
    
    info "Waiting for services to be healthy..."
    sleep 15
    
    if docker-compose ps | grep -q "healthy"; then
        success "Docker Compose started successfully!"
        echo -e "${GREEN}App URL: http://localhost:5000${NC}\n"
    else
        warning "Services started but may not be fully ready yet. Check with: docker-compose logs"
    fi
}

# Function to start Monitoring Stack
start_monitoring() {
    header "Step 2/3: Starting Monitoring Stack (Prometheus + Grafana)"
    
    cd "$PROJECT_DIR"
    
    # Create necessary directories
    mkdir -p monitoring/grafana/dashboards
    mkdir -p monitoring/grafana/datasources
    
    info "Starting Prometheus, Grafana, and Node Exporter..."
    docker-compose -f docker-compose.monitoring.yml up -d
    
    info "Waiting for monitoring services to start..."
    sleep 10
    
    if docker-compose -f docker-compose.monitoring.yml ps | grep -q "Up"; then
        success "Monitoring stack started successfully!"
        echo -e "${GREEN}Prometheus: http://localhost:9090${NC}"
        echo -e "${GREEN}Grafana: http://localhost:3000 (admin/admin)${NC}"
        echo -e "${GREEN}Alertmanager: http://localhost:9093${NC}\n"
    else
        warning "Monitoring services may not be fully ready yet. Check with: docker-compose -f docker-compose.monitoring.yml logs"
    fi
}

# Function to optionally start Minikube
start_minikube() {
    header "Step 3/3: (Optional) Starting Minikube + Kubernetes"
    
    read -p "Do you want to start Minikube and deploy to Kubernetes? (y/n) " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        
        # Check if Minikube is installed
        if ! command -v minikube &> /dev/null; then
            warning "Minikube is not installed."
            echo "Install it from: https://minikube.sigs.k8s.io/docs/start/"
            return
        fi
        
        info "Starting Minikube..."
        minikube start --cpus 6 --memory 10240 --disk-size 50g || warning "Minikube may already be running"
        
        info "Enabling Minikube addons..."
        minikube addons enable ingress
        minikube addons enable metrics-server
        
        info "Building and loading Docker image into Minikube..."
        eval $(minikube docker-env)
        docker build -t moodlite:latest . || warning "Failed to build image"
        
        info "Deploying to Kubernetes..."
        kubectl create namespace moodlite || warning "Namespace may already exist"
        kubectl apply -f k8s/ -n moodlite || warning "Some resources may already exist"
        
        info "Waiting for pods to be ready..."
        kubectl wait --for=condition=ready pod -l app=moodlite -n moodlite --timeout=300s || warning "Pods not ready after timeout"
        
        success "Minikube deployment completed!"
        
        MINIKUBE_IP=$(minikube ip)
        echo -e "${GREEN}Minikube IP: $MINIKUBE_IP${NC}"
        echo -e "${GREEN}Add this to your /etc/hosts: $MINIKUBE_IP moodlite.local${NC}"
        echo -e "${GREEN}Then access: http://moodlite.local${NC}\n"
        
    else
        info "Skipping Minikube setup"
    fi
}

# Main execution
main() {
    echo -e "${GREEN}"
    cat << "EOF"
╔═══════════════════════════════════════════════════╗
║   🚀 MoodLite Master Startup Script 🚀         ║
║                                                   ║
║   Starting ALL services:                         ║
║   ✓ Flask App + PostgreSQL (Docker Compose)    ║
║   ✓ Monitoring Stack (Prometheus + Grafana)    ║
║   ✓ (Optional) Minikube + Kubernetes           ║
╚═══════════════════════════════════════════════════╝
EOF
    echo -e "${NC}\n"
    
    check_prerequisites
    start_docker_compose
    start_monitoring
    start_minikube
    
    echo -e "\n${GREEN}╔═══════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║  🎉 All services are running! 🎉              ║${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════════════════╝${NC}\n"
    
    echo -e "${BLUE}📊 Access Points:${NC}"
    echo -e "   🟢 ${GREEN}Flask App${NC}:      http://localhost:5000"
    echo -e "   🟢 ${GREEN}Prometheus${NC}:    http://localhost:9090"
    echo -e "   🟢 ${GREEN}Grafana${NC}:       http://localhost:3000 (admin/admin)"
    echo -e "   🟢 ${GREEN}Alertmanager${NC}:  http://localhost:9093"
    echo ""
    
    echo -e "${BLUE}📋 Useful Commands:${NC}"
    echo -e "   • View app logs:       ${YELLOW}docker-compose logs -f app${NC}"
    echo -e "   • View monitoring:     ${YELLOW}docker-compose -f docker-compose.monitoring.yml logs -f${NC}"
    echo -e "   • Stop everything:     ${YELLOW}bash scripts/stop-all.sh${NC}"
    echo -e "   • Monitor AWS app:     ${YELLOW}bash scripts/monitor-aws.sh <EC2_IP>${NC}"
    echo ""
    
    echo -e "${BLUE}🔗 Next Steps:${NC}"
    echo -e "   1. Open http://localhost:5000 in your browser"
    echo -e "   2. Register and test the application"
    echo -e "   3. View metrics in Grafana (http://localhost:3000)"
    echo -e "   4. Check logs with: docker-compose logs -f"
    echo ""
}

# Run main
main
