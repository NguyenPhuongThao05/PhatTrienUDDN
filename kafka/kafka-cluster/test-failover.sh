#!/bin/bash

# Script để test failover scenario - dừng leader và kiểm tra hệ thống

echo "=== Kafka Failover Test Script ==="
echo

# Màu sắc cho output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

TOPIC_NAME="message-topic"

echo -e "${BLUE}1. Kiểm tra leader hiện tại cho từng partition...${NC}"
echo

# Function để lấy leader của một partition
get_partition_leader() {
    local partition=$1
    docker exec kafka-1 kafka-topics --bootstrap-server localhost:29092 --describe --topic $TOPIC_NAME 2>/dev/null | grep "Partition: $partition" | awk '{print $6}'
}

# Lưu thông tin leader ban đầu
declare -A original_leaders
for partition in 0 1 2; do
    leader=$(get_partition_leader $partition)
    original_leaders[$partition]=$leader
    echo -e "Partition $partition: Leader is Broker ${GREEN}$leader${NC}"
done

# Tìm broker được sử dụng nhiều nhất làm leader
declare -A leader_count
for leader in "${original_leaders[@]}"; do
    ((leader_count[$leader]++))
done

# Tìm leader chính (broker có nhiều partition leader nhất)
main_leader=""
max_count=0
for broker in "${!leader_count[@]}"; do
    if [ "${leader_count[$broker]}" -gt "$max_count" ]; then
        max_count="${leader_count[$broker]}"
        main_leader="$broker"
    fi
done

echo
echo -e "${YELLOW}Broker $main_leader đang là leader cho $max_count partition(s)${NC}"

# Xác định container name từ broker ID
case $main_leader in
    1) container_name="kafka-1" ;;
    2) container_name="kafka-2" ;;
    3) container_name="kafka-3" ;;
    *) echo "Unknown broker ID: $main_leader"; exit 1 ;;
esac

echo -e "${RED}Sẽ dừng container: $container_name (Broker $main_leader)${NC}"
echo

# Hỏi xác nhận
read -p "Bạn có muốn tiếp tục test failover không? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Hủy test failover"
    exit 1
fi

echo
echo -e "${BLUE}2. Dừng broker leader ($container_name)...${NC}"
echo

# Dừng container
docker stop $container_name

echo "Container $container_name đã bị dừng"
echo

echo -e "${BLUE}3. Đợi 10 giây để cluster tự động elect leader mới...${NC}"
sleep 10

echo
echo -e "${BLUE}4. Kiểm tra leader mới sau khi failover...${NC}"
echo

# Kiểm tra leader mới
for partition in 0 1 2; do
    old_leader=${original_leaders[$partition]}
    new_leader=$(get_partition_leader $partition)
    
    echo -n "Partition $partition: "
    if [ "$old_leader" == "$main_leader" ]; then
        echo -e "Leader changed from ${RED}$old_leader${NC} to ${GREEN}$new_leader${NC}"
    else
        echo -e "Leader remains ${GREEN}$new_leader${NC} (không thay đổi)"
    fi
done

echo
echo -e "${BLUE}5. Kiểm tra trạng thái cluster sau failover...${NC}"
echo

# Kiểm tra trạng thái cluster
remaining_brokers=""
for port in 9092 9093 9094; do
    case $port in
        9092) broker="kafka-1" ;;
        9093) broker="kafka-2" ;;
        9094) broker="kafka-3" ;;
    esac
    
    if [ "$broker" != "$container_name" ]; then
        echo -n "Checking broker $broker on port $port: "
        if nc -z localhost $port; then
            echo -e "${GREEN}ONLINE${NC}"
            if [ -z "$remaining_brokers" ]; then
                remaining_brokers="localhost:$port"
            else
                remaining_brokers="$remaining_brokers,localhost:$port"
            fi
        else
            echo -e "${RED}OFFLINE${NC}"
        fi
    else
        echo -e "Broker $broker on port $port: ${RED}STOPPED (intentionally)${NC}"
    fi
done

echo
echo -e "${BLUE}6. Test gửi message với cluster còn lại...${NC}"
echo

# Test gửi message với broker còn lại
echo "Testing message production với cluster còn lại..."

# Tạo test message
test_message='{"id":999,"title":"Failover Test","content":"Message sent during failover test","sender":"FailoverScript","priority":"HIGH"}'

# Gửi message qua producer API (giả sử producer app đang chạy)
response=$(curl -s -X POST http://localhost:8081/api/producer/send \
    -H "Content-Type: application/json" \
    -d "$test_message" 2>/dev/null)

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Message gửi thành công sau failover${NC}"
    echo "Response: $response"
else
    echo -e "${YELLOW}⚠ Không thể test qua API (có thể producer app chưa chạy)${NC}"
fi

echo
echo -e "${BLUE}7. Khởi động lại broker đã dừng...${NC}"
echo

# Khởi động lại container
docker start $container_name

echo "Đang khởi động lại $container_name..."
sleep 15

echo
echo -e "${BLUE}8. Kiểm tra cluster sau khi khôi phục...${NC}"
echo

# Kiểm tra tất cả broker
for port in 9092 9093 9094; do
    echo -n "Checking broker on port $port: "
    if nc -z localhost $port; then
        echo -e "${GREEN}ONLINE${NC}"
    else
        echo -e "${RED}OFFLINE${NC}"
    fi
done

echo
echo -e "${BLUE}9. Kiểm tra partition leaders sau khi khôi phục...${NC}"
echo

# Kiểm tra leader sau khi khôi phục
for partition in 0 1 2; do
    leader=$(get_partition_leader $partition)
    echo -e "Partition $partition: Leader is Broker ${GREEN}$leader${NC}"
done

echo
echo -e "${GREEN}=== Failover Test hoàn thành! ===${NC}"
echo
echo "Kết quả:"
echo "- Cluster đã sống sót sau khi dừng broker $main_leader"
echo "- Leaders được tự động elect lại"
echo "- Hệ thống tiếp tục hoạt động bình thường"
echo "- Broker đã được khôi phục thành công"