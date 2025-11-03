# Monitoring Stack Summary - Kubernetes Spring Boot Application

## ✅ Đã triển khai thành công

### 1. Prometheus Stack (kube-prometheus-stack)
- **Status**: ✅ Running
- **Access**: http://localhost:30090
- **Components**:
  - Prometheus Server
  - Grafana (admin/admin123)
  - AlertManager
  - ServiceMonitors

### 2. Grafana Dashboard
- **Status**: ✅ Running  
- **Access**: http://localhost:30091
- **Login**: admin/admin123
- **Pre-installed Dashboards**:
  - Kubernetes Cluster Monitoring
  - Node Exporter
  - Pod/Container Metrics

### 3. AlertManager
- **Status**: ✅ Running
- **Access**: http://localhost:30092
- **Configuration**: 
  - Email notifications (SMTP)
  - Slack notifications
  - HTTP webhook endpoints

### 4. Alert Rules (PrometheusRule)
- **Status**: ✅ Deployed
- **Rules Created**:
  - PodHighCPUUsage: CPU > 80% for 1 minute
  - SpringBootAppHighCPU: App-specific CPU alerts
- **File**: `pod-cpu-alert-rules.yaml`

### 5. Spring Boot Application Updates
- **Status**: ✅ Updated
- **Metrics Endpoint**: `/actuator/prometheus`
- **Dependencies**: micrometer-registry-prometheus
- **Configuration**: Prometheus endpoints exposed

### 6. ServiceMonitor
- **Status**: ✅ Created
- **Purpose**: Enable Prometheus to scrape Spring Boot metrics
- **Target**: securing-web-app service

### 7. Webhook Server
- **Status**: ✅ Ready
- **Port**: 8080
- **Endpoints**:
  - `/health` - Health check
  - `/webhook` - General alerts
  - `/webhook/critical` - Critical alerts
  - `/webhook/warning` - Warning alerts

### 8. Load Testing Tools
- **JMeter Test Plan**: ✅ Created (`spring-boot-load-test.jmx`)
- **Simple Load Test Script**: ✅ Created (`simple-load-test.sh`)
- **Purpose**: Generate CPU load to trigger alerts

## 📊 Access URLs

| Component | URL | Credentials |
|-----------|-----|-------------|
| Grafana | http://localhost:30091 | admin/admin123 |
| Prometheus | http://localhost:30090 | - |
| AlertManager | http://localhost:30092 | - |
| Spring Boot App | http://localhost:30080 | - |
| Webhook Server | http://localhost:8080 | - |

## 🚨 Alert Configuration

### Alert Rules
```yaml
# CPU > 80% for any pod
PodHighCPUUsage:
  expression: (rate(container_cpu_usage_seconds_total[1m]) * 100) > 80
  duration: 1m
  severity: warning

# Spring Boot app specific
SpringBootAppHighCPU:
  expression: CPU > 80% for app=securing-web-app
  duration: 1m
  severity: critical
```

### Notification Channels
1. **Email**: admin@example.com (critical), team@example.com (warning)
2. **Slack**: #alerts (critical), #monitoring (warning)  
3. **Webhook**: localhost:8080/webhook endpoints

## 🧪 Testing Scenario

### Trigger CPU Alerts
1. **Start Webhook Server**:
   ```bash
   cd k8s-monitoring
   node webhook-server.js
   ```

2. **Run Load Test**:
   ```bash
   # Option 1: JMeter
   ./run-load-test.sh
   
   # Option 2: Simple curl-based
   ./simple-load-test.sh
   ```

3. **Monitor Results**:
   - Watch CPU metrics in Grafana
   - Check fired alerts in AlertManager
   - Observe webhook notifications in console
   - Review alerts.log file

## 📁 Files Created

```
k8s-monitoring/
├── alertmanager-config.yaml          # AlertManager configuration
├── pod-cpu-alert-rules.yaml          # Prometheus alert rules
├── spring-boot-servicemonitor.yaml   # ServiceMonitor for app
├── webhook-server.js                 # Node.js webhook receiver
├── package.json                      # Node.js dependencies
├── spring-boot-load-test.jmx         # JMeter test plan
├── run-load-test.sh                  # JMeter test runner
├── simple-load-test.sh               # Curl-based load test
└── README.md                         # Detailed documentation
```

## ⚠️ Known Issues & Notes

1. **Spring Boot App Status**: 
   - Pods showing high restart counts
   - May need health check adjustment

2. **Metrics Server**: 
   - Not available for `kubectl top` commands
   - Prometheus metrics collection still works

3. **AlertManager Config**:
   - Update SMTP credentials for email alerts
   - Update Slack webhook URL for Slack notifications

## 🔄 Next Steps for Production

1. **Configure Real Notification Channels**:
   - Set up SMTP server credentials
   - Configure Slack webhook URLs
   - Set up external HTTP endpoints

2. **Add More Alert Rules**:
   - Memory usage alerts
   - Disk space alerts
   - Application-specific metrics

3. **Dashboard Customization**:
   - Create Spring Boot specific dashboards
   - Add business metrics visualization

4. **Security**:
   - Enable authentication for monitoring stack
   - Set up TLS/SSL certificates

## 🎯 Verification Checklist

- ✅ Prometheus collecting metrics from Kubernetes
- ✅ Grafana displaying cluster metrics
- ✅ AlertManager accessible and configured
- ✅ Alert rules created and loaded
- ✅ ServiceMonitor for Spring Boot app
- ✅ Webhook server ready for notifications
- ✅ Load testing tools prepared
- ✅ Documentation complete

**Status**: Monitoring stack fully deployed and ready for testing! 🚀