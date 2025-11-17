#!/bin/bash

# Script demo API testing và failover scenario

echo "=== Kafka API Testing & Failover Demo ==="
echo

# Màu sắc
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}1. Testing Producer và Consumer APIs...${NC}"
echo

# Test Producer health
echo -n "Producer Health: "
producer_health=$(curl -s http://localhost:8081/api/producer/health 2>/dev/null)
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ UP${NC} - $producer_health"
else
    echo -e "${RED}✗ DOWN${NC}"
fi

# Test Consumer health
echo -n "Consumer Health: "
consumer_health=$(curl -s http://localhost:8082/api/consumer/health 2>/dev/null)
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ UP${NC} - $consumer_health"
else
    echo -e "${RED}✗ DOWN${NC}"
fi

echo
echo -e "${BLUE}2. Testing message flow với Producer API...${NC}"
echo

# Gửi một vài test messages
echo "Gửi 3 test messages..."
for i in {1..3}; do
    response=$(curl -s -X POST http://localhost:8081/api/producer/send \
        -H "Content-Type: application/json" \
        -d "{\"title\":\"Demo Message $i\",\"content\":\"Test message $i for demo\",\"sender\":\"DemoScript\",\"priority\":\"$([ $((i % 2)) -eq 0 ] && echo 'HIGH' || echo 'NORMAL')\"}" 2>/dev/null)
    
    if [ $? -eq 0 ]; then
        echo -e "Message $i: ${GREEN}✓ Sent${NC} - $response"
    else
        echo -e "Message $i: ${RED}✗ Failed${NC}"
    fi
    sleep 1
done

echo
echo "Gửi batch messages..."
batch_response=$(curl -s -X POST "http://localhost:8081/api/producer/send-batch?count=5" 2>/dev/null)
if [ $? -eq 0 ]; then
    echo -e "Batch messages: ${GREEN}✓ Sent${NC} - $batch_response"
else
    echo -e "Batch messages: ${RED}✗ Failed${NC}"
fi

echo
echo -e "${BLUE}3. Kiểm tra Kafka cluster status...${NC}"
echo

# Kiểm tra Kafka brokers
for port in 9092 9093 9094; do
    echo -n "Kafka broker on port $port: "
    if nc -z localhost $port; then
        echo -e "${GREEN}ONLINE${NC}"
    else
        echo -e "${RED}OFFLINE${NC}"
    fi
done

echo
echo -e "${BLUE}4. Kiểm tra partition leaders...${NC}"
echo

# Kiểm tra partition leaders
docker exec kafka-1 kafka-topics --bootstrap-server localhost:29092 --describe --topic message-topic 2>/dev/null | grep "Leader:"

echo
echo -e "${BLUE}5. Kiểm tra consumer groups...${NC}"
echo

# Kiểm tra consumer group status
docker exec kafka-1 kafka-consumer-groups --bootstrap-server localhost:29092 --describe --group message-consumer-group 2>/dev/null

echo
echo -e "${YELLOW}6. Test Failover Scenario...${NC}"
echo

read -p "Bạn có muốn test failover không? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${RED}Đang dừng kafka-2 để test failover...${NC}"
    docker stop kafka-2
    
    echo "Đợi 10 giây để cluster tự rebalance..."
    sleep 10
    
    echo "Kiểm tra cluster status sau failover:"
    for port in 9092 9093 9094; do
        case $port in
            9092) broker="kafka-1" ;;
            9093) broker="kafka-2" ;;
            9094) broker="kafka-3" ;;
        esac
        
        echo -n "Broker $broker on port $port: "
        if [ "$broker" = "kafka-2" ]; then
            echo -e "${RED}STOPPED (intentionally)${NC}"
        elif nc -z localhost $port; then
            echo -e "${GREEN}ONLINE${NC}"
        else
            echo -e "${RED}OFFLINE${NC}"
        fi
    done
    
    echo
    echo "Test gửi message trong khi failover:"
    failover_response=$(curl -s -X POST http://localhost:8081/api/producer/send \
        -H "Content-Type: application/json" \
        -d '{"title":"Failover Test","content":"Message during failover","sender":"FailoverTester","priority":"HIGH"}' 2>/dev/null)
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Message sent successfully during failover${NC}"
        echo "Response: $failover_response"
    else
        echo -e "${RED}✗ Failed to send message during failover${NC}"
    fi
    
    echo
    echo "Kiểm tra partition leaders sau failover:"
    docker exec kafka-1 kafka-topics --bootstrap-server localhost:29092 --describe --topic message-topic 2>/dev/null | grep "Leader:"
    
    echo
    echo -e "${BLUE}Khôi phục kafka-2...${NC}"
    docker start kafka-2
    
    echo "Đợi broker khôi phục..."
    sleep 15
    
    echo "Cluster status sau khi khôi phục:"
    for port in 9092 9093 9094; do
        echo -n "Checking broker on port $port: "
        if nc -z localhost $port; then
            echo -e "${GREEN}ONLINE${NC}"
        else
            echo -e "${RED}OFFLINE${NC}"
        fi
    done
    
else
    echo "Bỏ qua failover test"
fi

echo
echo -e "${GREEN}=== Demo hoàn thành! ===${NC}"
echo
echo "Tóm tắt:"
echo "- Producer API: http://localhost:8081/api/producer/health"
echo "- Consumer API: http://localhost:8082/api/consumer/health"
echo "- Kafka UI: http://localhost:8080"
echo "- H2 Console: http://localhost:8082/h2-console"
echo
echo "Các API endpoints:"
echo "  POST /api/producer/send - Gửi message"
echo "  POST /api/producer/send-batch?count=N - Gửi N messages"
echo "  GET /api/consumer/stats - Xem thống kê"
echo "  GET /api/consumer/messages - Xem tất cả messages"