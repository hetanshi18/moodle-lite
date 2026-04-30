#!/bin/bash
# Monitor AWS-deployed MoodLite app from local laptop

EC2_IP="${1:-localhost}"
INTERVAL="${2:-60}"

if [ "$EC2_IP" == "" ] || [ "$EC2_IP" == "-h" ] || [ "$EC2_IP" == "--help" ]; then
    echo "Usage: $0 <EC2_IP> [INTERVAL_SECONDS]"
    echo "Example: $0 54.123.45.67 60"
    echo ""
    exit 1
fi

echo "🔍 Starting MoodLite Monitoring (interval: ${INTERVAL}s)"
echo "📍 Target: http://${EC2_IP}:8000"
echo "⏹️  Press Ctrl+C to stop"
echo ""

while true; do
    clear
    echo "=== MoodLite Health Dashboard ==="
    echo "Last update: $(date)"
    echo ""
    
    # Try to get health info
    if curl -s --connect-timeout 5 "http://${EC2_IP}:8000/health" > /dev/null 2>&1; then
        echo "✅ Application Status: HEALTHY"
        
        # Get detailed metrics
        METRICS=$(curl -s --connect-timeout 5 "http://${EC2_IP}:8000/metrics/detailed" 2>/dev/null || echo "{}")
        
        if [ "$METRICS" != "{}" ]; then
            echo ""
            echo "📊 User Metrics:"
            echo "   Total Users: $(echo $METRICS | jq -r '.users.total // "N/A"')"
            echo "   Instructors: $(echo $METRICS | jq -r '.users.instructors // "N/A"')"
            echo "   Students: $(echo $METRICS | jq -r '.users.students // "N/A"')"
            
            echo ""
            echo "🎓 Course Metrics:"
            echo "   Total Courses: $(echo $METRICS | jq -r '.courses.total // "N/A"')"
            
            echo ""
            echo "📝 Assignment Metrics:"
            echo "   Total Assignments: $(echo $METRICS | jq -r '.assignments.total // "N/A"')"
            echo "   Total Submissions: $(echo $METRICS | jq -r '.assignments.submissions // "N/A"')"
            echo "   Completion Rate: $(echo $METRICS | jq -r '.assignments.completion_rate // "N/A"')%"
        fi
    else
        echo "❌ Application Status: UNREACHABLE"
        echo "   Could not connect to http://${EC2_IP}:8000"
    fi
    
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Next update in ${INTERVAL} seconds... (Ctrl+C to exit)"
    sleep "$INTERVAL"
done
