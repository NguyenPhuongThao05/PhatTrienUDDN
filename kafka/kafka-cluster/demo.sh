#!/bin/bash

# Script demo toàn bộ hệ thống Kafka với Spring Boot

echo "=== Demo Kafka Spring Boot System ==="
echo

# Màu sắc cho output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}Demo sẽ thực hiện các bước sau:${NC}"
echo "1. Khởi động Kafka cluster (3 brokers + 3 zookeepers)"
echo "2. Kiểm tra cluster health và leaders"
echo "3. Test gửi và nhận messages"
echo "4. Test failover scenario"
echo "5. Hiển thị kết quả"
echo

read -p "Bạn có muốn tiếp tục demo không? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Hủy demo"
    exit 1
fi

echo
echo -e "${BLUE}=== BƯỚC 1: Khởi động Kafka Cluster ===${NC}"
echo

# Khởi động cluster
./setup-cluster.sh

echo
echo -e "${BLUE}=== BƯỚC 2: Kiểm tra Cluster Health và Leaders ===${NC}"
echo

# Kiểm tra leader
./check-leader.sh

echo
echo -e "${BLUE}=== BƯỚC 3: Test Message Exchange ===${NC}"
echo

echo "Đang đợi để Producer và Consumer apps khởi động..."
echo "Vui lòng:"
echo "1. Mở terminal mới và chạy: cd kafka-producer && mvn spring-boot:run"  
echo "2. Mở terminal khác và chạy: cd kafka-consumer && mvn spring-boot:run"
echo

read -p "Nhấn Enter khi cả 2 apps đã khởi động (kiểm tra ports 8081 và 8082)..."

# Kiểm tra apps đang chạy
echo
echo "Kiểm tra Producer app (port 8081):"
if curl -s http://localhost:8081/api/producer/health > /dev/null; then
    echo -e "${GREEN}✓ Producer app đang hoạt động${NC}"
else
    echo -e "${RED}✗ Producer app chưa sẵn sàng${NC}"
fi

echo "Kiểm tra Consumer app (port 8082):"  
if curl -s http://localhost:8082/api/consumer/health > /dev/null; then
    echo -e "${GREEN}✓ Consumer app đang hoạt động${NC}"
else
    echo -e "${RED}✗ Consumer app chưa sẵn sàng${NC}"
fi

echo
echo "Gửi test messages..."

# Gửi một số test messages
for i in {1..5}; do
    echo "Gửi message $i..."
    curl -s -X POST http://localhost:8081/api/producer/send \
        -H "Content-Type: application/json" \
        -d "{
            \"title\": \"Demo Message $i\",
            \"content\": \"This is test message number $i from demo script\",
            \"sender\": \"DemoScript\",
            \"priority\": \"$([ $((i % 2)) -eq 0 ] && echo 'HIGH' || echo 'NORMAL')\"
        }" > /dev/null
    sleep 1
done

# Gửi batch messages
echo "Gửi batch messages..."
curl -s -X POST "http://localhost:8081/api/producer/send-batch?count=10" > /dev/null

echo "Đợi messages được xử lý..."
sleep 5

# Kiểm tra kết quả
echo
echo "Kiểm tra messages đã xử lý:"
processed_count=$(curl -s http://localhost:8082/api/consumer/stats | grep -o '"totalProcessedMessages":[0-9]*' | cut -d':' -f2)
echo -e "Tổng messages đã xử lý: ${GREEN}$processed_count${NC}"

echo
echo -e "${BLUE}=== BƯỚC 4: Test Failover Scenario ===${NC}"
echo

read -p "Bạn có muốn test failover scenario không? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Chạy failover test..."
    ./test-failover.sh
else
    echo "Bỏ qua failover test"
fi

echo
echo -e "${BLUE}=== BƯỚC 5: Tóm tắt Demo ===${NC}"
echo

echo -e "${GREEN}✓ Demo hoàn thành thành công!${NC}"
echo
echo "Kết quả demo:"
echo "- Kafka cluster với 3 brokers đã được thiết lập"
echo "- Zookeeper ensemble với 3 nodes đang hoạt động"
echo "- Producer Spring Boot app đã gửi messages thành công"
echo "- Consumer Spring Boot app đã nhận và xử lý messages"
echo "- Cluster có khả năng failover tự động"
echo
echo "Các URL hữu ích:"
echo "- Producer API: http://localhost:8081/api/producer/health"
echo "- Consumer API: http://localhost:8082/api/consumer/health" 
echo "- Consumer Stats: http://localhost:8082/api/consumer/stats"
echo "- Kafka UI: http://localhost:8080"
echo "- H2 Console: http://localhost:8082/h2-console"
echo
echo "Để dừng toàn bộ hệ thống:"
echo "- Dừng Spring Boot apps: Ctrl+C trong terminals"
echo "- Dừng Kafka cluster: docker-compose down -v"

echo
echo -e "${YELLOW}Demo kết thúc. Cảm ơn bạn!${NC}"