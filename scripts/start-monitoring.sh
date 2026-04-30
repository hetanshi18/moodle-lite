#!/bin/bash
# Start local monitoring stack using Docker Compose

echo "🚀 Starting MoodLite Monitoring Stack..."
echo ""

# Create necessary directories
mkdir -p monitoring/grafana/dashboards
mkdir -p monitoring/grafana/datasources

# Start monitoring stack
docker-compose -f docker-compose.monitoring.yml up -d

# Wait for services to start
echo "⏳ Waiting for services to start..."
sleep 10

echo ""
echo "✅ Monitoring stack is running!"
echo ""
echo "📊 Access your monitoring dashboards:"
echo "   🟢 Prometheus: http://localhost:9090"
echo "   🟢 Grafana:    http://localhost:3000 (login: admin/admin)"
echo "   🟢 Alertmanager: http://localhost:9093"
echo ""
echo "📈 Available metrics:"
echo "   - Application health"
echo "   - System metrics (CPU, Memory, Disk, Network)"
echo "   - Node exporter metrics"
echo ""
echo "Next steps:"
echo "1. Open http://localhost:3000 in your browser"
echo "2. Login with admin/admin"
echo "3. Add Prometheus as data source: http://prometheus:9090"
echo ""
