# Kafka Spring Boot Demo Project

## Tổng quan
Dự án này bao gồm:
- **Producer Spring Boot App**: Gửi dữ liệu JSON qua Kafka
- **Consumer Spring Boot App**: Nhận và xử lý dữ liệu JSON từ Kafka  
- **Kafka Cluster**: 3 broker nodes với Zookeeper ensemble
- **Testing Scripts**: Kiểm tra leader election và failover

## Cấu trúc thư mục
```
kafka/
├── kafka-producer/          # Spring Boot Producer Application
├── kafka-consumer/          # Spring Boot Consumer Application
├── kafka-cluster/           # Docker Compose setup cho Kafka cluster
│   ├── docker-compose.yml   # Cấu hình 3-node Kafka cluster
│   ├── setup-cluster.sh     # Script setup và khởi động cluster
│   ├── check-leader.sh      # Script kiểm tra partition leaders
│   └── test-failover.sh     # Script test failover scenario
└── README.md
```

## Yêu cầu hệ thống
- Java 17+
- Maven 3.6+
- Docker và Docker Compose
- cURL (để test APIs)

## Hướng dẫn chạy

### 1. Khởi động Kafka Cluster
```bash
cd kafka-cluster
./setup-cluster.sh
```

Cluster bao gồm:
- 3 Zookeeper nodes (ports: 2181, 2182, 2183)
- 3 Kafka brokers (ports: 9092, 9093, 9094)
- Kafka UI (http://localhost:8080)

### 2. Chạy Producer Application
```bash
cd kafka-producer
mvn spring-boot:run
```
Producer app chạy trên port **8081**

### 3. Chạy Consumer Application
```bash
cd kafka-consumer  
mvn spring-boot:run
```
Consumer app chạy trên port **8082**

## API Endpoints

### Producer APIs (port 8081)
- `POST /api/producer/send` - Gửi một message
- `POST /api/producer/send-sync` - Gửi message đồng bộ
- `POST /api/producer/send-batch?count=10` - Gửi nhiều messages
- `GET /api/producer/health` - Health check

### Consumer APIs (port 8082)
- `GET /api/consumer/messages` - Lấy tất cả messages đã xử lý
- `GET /api/consumer/messages/{id}` - Lấy message theo ID
- `GET /api/consumer/stats` - Thống kê xử lý messages
- `GET /api/consumer/health` - Health check

## Test Cluster và Failover

### 1. Kiểm tra Leader Election
```bash
cd kafka-cluster
./check-leader.sh
```

### 2. Test Failover Scenario  
```bash
cd kafka-cluster
./test-failover.sh
```

Script này sẽ:
- Xác định broker nào đang làm leader
- Dừng broker leader  
- Kiểm tra hệ thống có hoạt động tiếp không
- Khôi phục broker đã dừng

## Ví dụ Test APIs

### Gửi message qua Producer:
```bash
curl -X POST http://localhost:8081/api/producer/send \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Test Message",
    "content": "Hello Kafka Cluster",
    "sender": "TestUser",
    "priority": "HIGH"
  }'
```

### Xem messages đã xử lý qua Consumer:
```bash
curl http://localhost:8082/api/consumer/messages
```

### Xem thống kê:
```bash
curl http://localhost:8082/api/consumer/stats
```

## Monitoring

### Kafka UI
Truy cập http://localhost:8080 để:
- Monitor cluster health
- Xem topics và partitions
- Kiểm tra consumer groups
- Xem messages trong topics

### H2 Database Console (Consumer app)
Truy cập http://localhost:8082/h2-console
- JDBC URL: `jdbc:h2:mem:testdb`
- Username: `sa` 
- Password: `password`

## Các tính năng chính

### Producer App:
- Gửi messages JSON qua Kafka
- Hỗ trợ gửi đồng bộ/bất đồng bộ
- Batch message sending
- Automatic message ID generation
- Error handling và retry

### Consumer App:
- Nhận và xử lý messages từ Kafka
- Lưu trữ messages vào H2 database
- Manual acknowledgment để đảm bảo reliability
- Duplicate message detection
- Priority message handling
- REST APIs để query processed messages

### Kafka Cluster:
- 3-node cluster với high availability
- Replication factor = 3
- Min in-sync replicas = 2
- Automatic topic creation
- Leader election và failover support

## Troubleshooting

### Nếu cluster không khởi động:
```bash
cd kafka-cluster
docker-compose down -v
docker system prune -f
./setup-cluster.sh
```

### Nếu applications không kết nối được với Kafka:
- Kiểm tra Kafka cluster đang chạy: `docker-compose ps`
- Kiểm tra ports: `netstat -an | grep 909[2-4]`
- Xem logs: `docker-compose logs kafka-1`

### Reset toàn bộ hệ thống:
```bash
cd kafka-cluster
docker-compose down -v
docker volume prune -f
./setup-cluster.sh
```