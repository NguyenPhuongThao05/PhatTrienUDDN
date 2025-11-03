#!/bin/bash

# Test webhook endpoint manually
echo "=== Testing Webhook Server ==="

# Test critical alert
echo "Sending test critical alert..."
curl -X POST http://localhost:8080/webhook/critical \
  -H "Content-Type: application/json" \
  -d '{
    "alerts": [
      {
        "status": "firing",
        "labels": {
          "alertname": "TestCriticalAlert",
          "severity": "critical",
          "instance": "test-instance",
          "job": "test-job"
        },
        "annotations": {
          "summary": "Test critical alert from manual trigger",
          "description": "This is a test critical alert to verify webhook functionality"
        },
        "startsAt": "'$(date -u +%Y-%m-%dT%H:%M:%S.%3NZ)'",
        "generatorURL": "http://prometheus:9090/graph"
      }
    ],
    "groupLabels": {
      "alertname": "TestCriticalAlert"
    },
    "commonLabels": {
      "alertname": "TestCriticalAlert",
      "severity": "critical"
    },
    "commonAnnotations": {
      "summary": "Test critical alert from manual trigger"
    },
    "externalURL": "http://alertmanager:9093",
    "version": "4",
    "groupKey": "{}:{alertname=\"TestCriticalAlert\"}"
  }'

echo -e "\n\n=== Testing Warning Alert ==="

# Test warning alert  
curl -X POST http://localhost:8080/webhook/warning \
  -H "Content-Type: application/json" \
  -d '{
    "alerts": [
      {
        "status": "firing", 
        "labels": {
          "alertname": "TestWarningAlert",
          "severity": "warning",
          "instance": "test-instance",
          "job": "test-job"
        },
        "annotations": {
          "summary": "Test warning alert from manual trigger",
          "description": "This is a test warning alert to verify webhook functionality"
        },
        "startsAt": "'$(date -u +%Y-%m-%dT%H:%M:%S.%3NZ)'",
        "generatorURL": "http://prometheus:9090/graph"
      }
    ],
    "groupLabels": {
      "alertname": "TestWarningAlert"
    },
    "commonLabels": {
      "alertname": "TestWarningAlert", 
      "severity": "warning"
    },
    "commonAnnotations": {
      "summary": "Test warning alert from manual trigger"
    },
    "externalURL": "http://alertmanager:9093",
    "version": "4",
    "groupKey": "{}:{alertname=\"TestWarningAlert\"}"
  }'

echo -e "\n\n=== Webhook Test Completed ==="
echo "Check webhook server console for received alerts"
echo "Check alerts.log file for logged notifications"