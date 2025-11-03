# Kubernetes Monitoring và Alerting Stack

## Tổng quan
Hệ thống monitoring và alerting cho Spring Boot application trên Kubernetes bao gồm:
- **Prometheus**: Thu thập metrics
- **Grafana**: Trực quan hóa dữ liệu
- **AlertManager**: Quản lý và gửi cảnh báo
- **Spring Boot**: Expose metrics qua endpoint `/actuator/prometheus`

## Thành phần đã triển khai

### 1. Ứng dụng Spring Boot
- **URL**: http://localhost:30080
- **Metrics endpoint**: http://localhost:30080/actuator/prometheus
- **Pods**: 3 replicas với MySQL database

### 2. Prometheus
- **URL**: http://localhost:30090
- **Chức năng**: Thu thập metrics từ K8s cluster và Spring Boot app
- **Alert Rules**: CPU > 80% trong 1 phút

### 3. Grafana
- **URL**: http://localhost:30091
- **Login**: admin/admin123
- **Dashboards có sẵn**:
  - Kubernetes Cluster Monitoring
  - Node Exporter
  - Pod và Container metrics

### 4. AlertManager
- **URL**: http://localhost:30092
- **Chức năng**: Nhận alerts từ Prometheus và gửi notifications

### 5. Webhook Server
- **URL**: http://localhost:8080
- **Endpoints**:
  - `GET /health` - Health check
  - `POST /webhook` - General alerts
  - `POST /webhook/critical` - Critical alerts
  - `POST /webhook/warning` - Warning alerts

## Cách sử dụng

### 1. Khởi động Webhook Server
```bash
cd k8s-monitoring
node webhook-server.js
```

### 2. Chạy Load Test để trigger alerts
```bash
cd k8s-monitoring
./run-load-test.sh
```

### 3. Monitoring CPU và Alerts

#### Trên Grafana:
1. Truy cập http://localhost:30091
2. Login với admin/admin123
3. Vào dashboard "Kubernetes / Compute Resources / Pod"
4. Tìm pod "securing-web-app" để xem CPU usage

#### Trên AlertManager:
1. Truy cập http://localhost:30092
2. Xem các alerts đang firing
3. Kiểm tra silence rules

#### Webhook Notifications:
1. Kiểm tra console của webhook server
2. Xem file `alerts.log` để xem chi tiết notifications

### 4. Alert Rules đã tạo

#### PodHighCPUUsage
- **Condition**: `(rate(container_cpu_usage_seconds_total[1m]) * 100) > 80`
- **Duration**: 1 phút
- **Severity**: warning
- **Description**: Pod CPU usage > 80%

#### SpringBootAppHighCPU  
- **Condition**: CPU > 80% cho pods có label `app=securing-web-app`
- **Duration**: 1 phút
- **Severity**: critical
- **Description**: Spring Boot app high CPU usage

## AlertManager Configuration

### Email Notifications
- **SMTP**: smtp.gmail.com:587
- **Recipients**: 
  - Critical: admin@example.com
  - Warning: team@example.com

### Slack Notifications
- **Channels**:
  - Critical: #alerts
  - Warning: #monitoring
- **Webhook URL**: Cần cập nhật với Slack webhook thật

### HTTP Webhook
- **Critical alerts**: http://host.docker.internal:8080/webhook/critical
- **Warning alerts**: http://host.docker.internal:8080/webhook/warning

## Troubleshooting

### 1. Webhook không nhận được alerts
```bash
# Kiểm tra AlertManager config
kubectl logs -n monitoring alertmanager-prometheus-kube-prometheus-alertmanager-0

# Test webhook server
curl -X POST http://localhost:8080/webhook -H "Content-Type: application/json" -d '{"test": "alert"}'
```

### 2. Prometheus không scrape metrics
```bash
# Kiểm tra targets trong Prometheus UI
# Truy cập http://localhost:30090/targets
```

### 3. Grafana không hiển thị dữ liệu
```bash
# Kiểm tra data source connection trong Grafana
# Configuration > Data Sources > Prometheus
```

## Mở rộng

### 1. Thêm custom metrics
Thêm vào `application.properties`:
```properties
management.metrics.export.prometheus.enabled=true
management.metrics.distribution.percentiles-histogram.http.server.requests=true
```

### 2. Tạo custom dashboard
1. Vào Grafana
2. Create > Dashboard
3. Sử dụng PromQL queries để query metrics

### 3. Thêm alert rules mới
Tạo file PrometheusRule mới và apply:
```yaml
kubectl apply -f new-alert-rules.yaml
```

## Load Testing với JMeter

### Test Plan Features
- **50 concurrent threads**
- **1000 loops per thread**
- **3 HTTP requests**: Home page, Login, Metrics endpoint
- **100ms delay** giữa các requests

### Chạy test:
```bash
# GUI mode
jmeter -t spring-boot-load-test.jmx

# Command line mode
jmeter -n -t spring-boot-load-test.jmx -l results.jtl
```

## Files trong project

```
k8s-monitoring/
├── alertmanager-config.yaml      # AlertManager configuration
├── pod-cpu-alert-rules.yaml      # Prometheus alert rules
├── webhook-server.js             # Node.js webhook server
├── package.json                  # Node.js dependencies
├── spring-boot-load-test.jmx     # JMeter test plan
├── run-load-test.sh              # Script chạy load test
└── alerts.log                    # Log file cho webhook notifications
```