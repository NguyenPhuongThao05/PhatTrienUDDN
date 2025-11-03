#!/bin/bash

# Simple load test script using curl
echo "=== Starting Simple Load Test ==="

# Function to make requests
make_requests() {
    local count=$1
    echo "Making $count concurrent requests..."
    
    for i in $(seq 1 $count); do
        curl -s http://localhost:30080/actuator/health > /dev/null 2>&1 &
    done
    wait
}

# Webhook server check
if ! curl -s http://localhost:8080/health > /dev/null; then
    echo "Warning: Webhook server not running at localhost:8080"
fi

# Prometheus check
if ! curl -s http://localhost:30090/-/healthy > /dev/null; then
    echo "Warning: Prometheus not accessible at localhost:30090"
fi

# Start load test
echo "Starting load test to trigger CPU alerts..."
echo "Press Ctrl+C to stop"

while true; do
    make_requests 20
    echo "Batch completed at $(date)"
    sleep 5
done