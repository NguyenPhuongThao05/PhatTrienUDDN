#!/bin/bash

# Script để kiểm tra Kafka cluster và leader election

echo "=== Kafka Cluster Health Check và Leader Election Test ==="
echo

# Màu sắc cho output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Cấu hình
KAFKA_BROKERS="localhost:9092,localhost:9093,localhost:9094"
TOPIC_NAME="message-topic"

echo -e "${BLUE}1. Kiểm tra trạng thái các broker...${NC}"
echo

# Kiểm tra từng broker
for port in 9092 9093 9094; do
    echo -n "Checking broker on port $port: "
    if nc -z localhost $port; then
        echo -e "${GREEN}ONLINE${NC}"
    else
        echo -e "${RED}OFFLINE${NC}"
    fi
done

echo
echo -e "${BLUE}2. Tạo topic với replication factor 3...${NC}"
echo

# Tạo topic nếu chưa có
docker exec kafka-1 kafka-topics --bootstrap-server localhost:29092 --create --topic $TOPIC_NAME --partitions 3 --replication-factor 3 --if-not-exists

echo
echo -e "${BLUE}3. Kiểm tra thông tin topic...${NC}"
echo

# Hiển thị thông tin topic
docker exec kafka-1 kafka-topics --bootstrap-server localhost:29092 --describe --topic $TOPIC_NAME

echo
echo -e "${BLUE}4. Kiểm tra partition leader cho từng partition...${NC}"
echo

# Lấy thông tin leader cho từng partition
for partition in 0 1 2; do
    leader_info=$(docker exec kafka-1 kafka-topics --bootstrap-server localhost:29092 --describe --topic $TOPIC_NAME | grep "Partition: $partition" | awk '{print $6}')
    echo -e "Partition $partition: Leader is Broker ${GREEN}$leader_info${NC}"
done

echo
echo -e "${BLUE}5. Kiểm tra cluster metadata...${NC}"
echo

# Hiển thị thông tin cluster
docker exec kafka-1 kafka-broker-api-versions --bootstrap-server localhost:29092 | head -10

echo
echo -e "${BLUE}6. Kiểm tra consumer groups...${NC}"
echo

# Liệt kê consumer groups
docker exec kafka-1 kafka-consumer-groups --bootstrap-server localhost:29092 --list

echo
echo -e "${YELLOW}=== Script hoàn thành! ===${NC}"
echo -e "Sử dụng script test-failover.sh để kiểm tra failover scenario"