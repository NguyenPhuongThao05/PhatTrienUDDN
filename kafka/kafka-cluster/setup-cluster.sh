#!/bin/bash

# Script để setup và start toàn bộ hệ thống

echo "=== Kafka Cluster Setup Script ==="
echo

# Màu sắc cho output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}1. Dọn dẹp các container cũ (nếu có)...${NC}"
docker-compose down -v

echo
echo -e "${BLUE}2. Khởi động Kafka cluster (3 brokers + 3 zookeepers)...${NC}"
docker-compose up -d

echo
echo -e "${BLUE}3. Đợi cluster khởi động hoàn toàn...${NC}"
echo "Đang đợi 60 giây để cluster stable..."
sleep 60

echo
echo -e "${BLUE}4. Kiểm tra trạng thái các services...${NC}"
docker-compose ps

echo
echo -e "${BLUE}5. Tạo topic message-topic...${NC}"
docker exec kafka-1 kafka-topics --bootstrap-server localhost:29092 --create --topic message-topic --partitions 3 --replication-factor 3 --if-not-exists

echo
echo -e "${BLUE}6. Kiểm tra topic đã tạo...${NC}"
docker exec kafka-1 kafka-topics --bootstrap-server localhost:29092 --list

echo
echo -e "${GREEN}=== Setup hoàn thành! ===${NC}"
echo
echo "Các services đang chạy:"
echo "- Zookeeper Ensemble: ports 2181, 2182, 2183"
echo "- Kafka Broker 1: port 9092"
echo "- Kafka Broker 2: port 9093" 
echo "- Kafka Broker 3: port 9094"
echo "- Kafka UI: http://localhost:8080"
echo
echo "Các bước tiếp theo:"
echo "1. Chạy Producer app: cd kafka-producer && mvn spring-boot:run"
echo "2. Chạy Consumer app: cd kafka-consumer && mvn spring-boot:run"
echo "3. Test hệ thống: ./check-leader.sh"
echo "4. Test failover: ./test-failover.sh"