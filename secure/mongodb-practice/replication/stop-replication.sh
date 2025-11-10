#!/bin/bash

# Stop MongoDB Replication
# Dừng tất cả các MongoDB instances trong replica set

echo "🛑 Dừng MongoDB Replica Set..."

# Dừng các MongoDB processes
echo "Đang dừng các MongoDB instances..."

# Tìm và dừng tất cả các mongod processes cho replica set
for port in 27017 27018 27019; do
    PID=$(pgrep -f "mongod.*--port $port")
    if [ ! -z "$PID" ]; then
        echo "Dừng MongoDB instance trên port $port (PID: $PID)..."
        kill $PID
        sleep 1
        
        # Force kill nếu cần
        if kill -0 $PID 2>/dev/null; then
            echo "Force killing process $PID..."
            kill -9 $PID
        fi
    else
        echo "Không tìm thấy MongoDB instance trên port $port"
    fi
done

echo ""
echo "⏳ Đợi processes dừng hoàn toàn..."
sleep 3

# Kiểm tra xem còn process nào đang chạy không
REMAINING=$(pgrep -f "mongod.*--replSet rs0")
if [ ! -z "$REMAINING" ]; then
    echo "⚠️ Vẫn còn processes đang chạy, force killing..."
    pkill -9 -f "mongod.*--replSet rs0"
    sleep 2
fi

echo ""
echo "🧹 Dọn dẹp (tùy chọn)..."
echo "Bạn có muốn xóa dữ liệu và logs không? (y/n)"
read -r response

if [[ "$response" =~ ^[Yy]$ ]]; then
    echo "Đang xóa dữ liệu và logs..."
    rm -rf data/rs0-*
    rm -rf logs/rs0-*.log
    echo "✅ Đã xóa dữ liệu và logs"
else
    echo "ℹ️ Giữ lại dữ liệu và logs"
fi

echo ""
echo "✅ Replica Set đã được dừng hoàn toàn!"
echo ""
echo "💡 Để khởi động lại:"
echo "   ./setup-replication.sh"