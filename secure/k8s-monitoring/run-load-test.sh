#!/bin/bash

# Script để chạy JMeter load test và trigger CPU alerts

echo "=== Starting CPU Load Test for Spring Boot App ==="

# Kiểm tra JMeter có được cài đặt không
if ! command -v jmeter &> /dev/null; then
    echo "JMeter not found. Installing via Homebrew..."
    brew install jmeter
fi

# Kiểm tra webhook server
echo "Checking webhook server..."
if curl -s http://localhost:8080/health > /dev/null; then
    echo "✓ Webhook server is running"
else
    echo "✗ Webhook server is not running. Please start it first:"
    echo "  cd k8s-monitoring && node webhook-server.js"
    exit 1
fi

# Kiểm tra Spring Boot app
echo "Checking Spring Boot app..."
if curl -s http://localhost:30080 > /dev/null; then
    echo "✓ Spring Boot app is accessible"
else
    echo "✗ Spring Boot app is not accessible at localhost:30080"
    exit 1
fi

# Chạy JMeter test
echo "Starting JMeter load test..."
echo "This will create high CPU load to trigger alerts..."
echo "Monitor Grafana (localhost:30091) and AlertManager (localhost:30092)"
echo "Press Ctrl+C to stop the test"

jmeter -n -t spring-boot-load-test.jmx -l test-results.jtl -e -o test-report

echo "Load test completed. Check:"
echo "1. Grafana dashboards for CPU metrics"
echo "2. AlertManager for fired alerts" 
echo "3. Webhook server logs for received notifications"
echo "4. Test report in test-report/ directory"