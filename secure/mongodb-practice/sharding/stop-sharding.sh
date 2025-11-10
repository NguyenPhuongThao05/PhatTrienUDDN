#!/bin/bash

# Stop MongoDB Sharded Cluster
# Dừng tất cả các components của sharded cluster

echo "🛑 Dừng MongoDB Sharded Cluster..."

echo ""
echo "Bước 1: Dừng Query Router (mongos)..."
MONGOS_PID=$(pgrep -f "mongos.*--port 27500")
if [ ! -z "$MONGOS_PID" ]; then
    echo "Dừng mongos (PID: $MONGOS_PID)..."
    kill $MONGOS_PID
    sleep 2
else
    echo "Mongos không đang chạy"
fi

echo ""
echo "Bước 2: Dừng Shard Servers..."

# Dừng Shard 0
for port in 27200 27201; do
    PID=$(pgrep -f "mongod.*--port $port")
    if [ ! -z "$PID" ]; then
        echo "Dừng Shard 0 node trên port $port (PID: $PID)..."
        kill $PID
        sleep 1
    else
        echo "Shard 0 node port $port không đang chạy"
    fi
done

# Dừng Shard 1  
for port in 27300 27301; do
    PID=$(pgrep -f "mongod.*--port $port")
    if [ ! -z "$PID" ]; then
        echo "Dừng Shard 1 node trên port $port (PID: $PID)..."
        kill $PID
        sleep 1
    else
        echo "Shard 1 node port $port không đang chạy"
    fi
done

echo ""
echo "Bước 3: Dừng Config Servers..."

# Dừng Config Servers
for port in 27100 27101 27102; do
    PID=$(pgrep -f "mongod.*--port $port")
    if [ ! -z "$PID" ]; then
        echo "Dừng Config Server trên port $port (PID: $PID)..."
        kill $PID
        sleep 1
    else
        echo "Config Server port $port không đang chạy"
    fi
done

echo ""
echo "⏳ Đợi tất cả processes dừng hoàn toàn..."
sleep 5

# Kiểm tra và force kill nếu cần thiết
echo ""
echo "Bước 4: Kiểm tra remaining processes..."

REMAINING_SHARDING=$(pgrep -f "mongod.*--port 271[0-9][0-9]|mongos.*--port 275[0-9][0-9]")
if [ ! -z "$REMAINING_SHARDING" ]; then
    echo "⚠️ Vẫn còn processes đang chạy, force killing..."
    pkill -9 -f "mongod.*--port 271[0-9][0-9]"
    pkill -9 -f "mongos.*--port 275[0-9][0-9]"
    sleep 2
fi

echo ""
echo "🧹 Bước 5: Cleanup options..."
echo "Bạn có muốn xóa dữ liệu và logs không? (y/n)"
read -r response

if [[ "$response" =~ ^[Yy]$ ]]; then
    echo "Đang xóa dữ liệu và logs..."
    
    # Xóa data directories
    rm -rf data/config/
    rm -rf data/shard0/
    rm -rf data/shard1/
    
    # Xóa log files
    rm -f logs/config*.log
    rm -f logs/shard*.log
    rm -f logs/mongos.log
    
    echo "✅ Đã xóa tất cả dữ liệu và logs"
else
    echo "ℹ️ Giữ lại dữ liệu và logs"
    echo "   Data locations:"
    echo "     - Config: data/config/"
    echo "     - Shard 0: data/shard0/"
    echo "     - Shard 1: data/shard1/"
    echo "     - Logs: logs/"
fi

echo ""
echo "📊 Kiểm tra trạng thái cuối cùng..."
STILL_RUNNING=$(pgrep -f "mongod.*--port 271[0-9][0-9]|mongos.*--port 275[0-9][0-9]")
if [ -z "$STILL_RUNNING" ]; then
    echo "✅ Tất cả MongoDB processes đã dừng"
else
    echo "❌ Vẫn còn processes đang chạy:"
    ps aux | grep -E "mongod.*--port 271[0-9][0-9]|mongos.*--port 275[0-9][0-9]" | grep -v grep
fi

echo ""
echo "✅ Sharded Cluster đã được dừng hoàn toàn!"
echo ""
echo "💡 Để khởi động lại:"
echo "   ./setup-sharding.sh"