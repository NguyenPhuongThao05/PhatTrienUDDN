#!/bin/bash

# Cleanup All MongoDB Instances
# Dừng và cleanup tất cả MongoDB instances

echo "🧹 MongoDB Cleanup - Dừng tất cả instances"
echo "==========================================="

echo ""
echo "🛑 Dừng tất cả MongoDB processes..."

# Dừng Replication (nếu đang chạy)
if pgrep -f "mongod.*--replSet rs0" > /dev/null; then
    echo "Dừng Replication instances..."
    cd replication 2>/dev/null && ./stop-replication.sh || {
        echo "Không thể chạy stop script, killing manually..."
        pkill -f "mongod.*--replSet rs0"
    }
    cd ..
fi

# Dừng Sharding (nếu đang chạy) 
if pgrep -f "mongod.*--port 271[0-9][0-9]\|mongos.*--port 275[0-9][0-9]" > /dev/null; then
    echo "Dừng Sharding cluster..."
    cd sharding 2>/dev/null && ./stop-sharding.sh || {
        echo "Không thể chạy stop script, killing manually..."
        pkill -f "mongod.*--port 271[0-9][0-9]"
        pkill -f "mongos.*--port 275[0-9][0-9]"
    }
    cd ..
fi

# Force kill bất kỳ MongoDB process nào còn sót lại
echo ""
echo "🔍 Kiểm tra remaining MongoDB processes..."
REMAINING=$(pgrep -f mongod)
if [ ! -z "$REMAINING" ]; then
    echo "⚠️ Force killing remaining MongoDB processes..."
    pkill -9 mongod
    sleep 2
fi

REMAINING_MONGOS=$(pgrep -f mongos)
if [ ! -z "$REMAINING_MONGOS" ]; then
    echo "⚠️ Force killing remaining mongos processes..."
    pkill -9 mongos
    sleep 2
fi

echo ""
echo "🗂️ Cleanup options:"
echo "   1) Giữ lại tất cả dữ liệu và logs"
echo "   2) Xóa chỉ logs"
echo "   3) Xóa tất cả (data + logs)"
echo "   4) Hủy"

read -p "Lựa chọn của bạn (1-4): " cleanup_choice

case $cleanup_choice in
    1)
        echo "ℹ️ Giữ lại tất cả dữ liệu và logs"
        ;;
    2)
        echo "🗑️ Xóa logs..."
        rm -rf replication/logs/
        rm -rf sharding/logs/
        echo "✅ Đã xóa logs"
        ;;
    3)
        echo "🗑️ Xóa tất cả dữ liệu và logs..."
        rm -rf replication/data/ replication/logs/
        rm -rf sharding/data/ sharding/logs/
        echo "✅ Đã xóa tất cả dữ liệu và logs"
        ;;
    4)
        echo "Hủy cleanup."
        ;;
    *)
        echo "❌ Lựa chọn không hợp lệ, giữ lại dữ liệu."
        ;;
esac

echo ""
echo "📊 Trạng thái cuối cùng:"

# Kiểm tra processes
MONGO_PROCESSES=$(pgrep -f mongo)
if [ -z "$MONGO_PROCESSES" ]; then
    echo "✅ Tất cả MongoDB processes đã dừng"
else
    echo "⚠️ Vẫn còn MongoDB processes:"
    ps aux | grep mongo | grep -v grep
fi

# Kiểm tra ports
echo ""
echo "🔌 Kiểm tra ports đang sử dụng:"
USED_PORTS=$(lsof -i :27017,27018,27019,27100,27101,27102,27200,27201,27300,27301,27500 2>/dev/null | grep LISTEN)
if [ -z "$USED_PORTS" ]; then
    echo "✅ Tất cả MongoDB ports đã được giải phóng"
else
    echo "⚠️ Các ports vẫn đang được sử dụng:"
    echo "$USED_PORTS"
fi

echo ""
echo "✅ Cleanup hoàn tất!"
echo ""
echo "💡 Để khởi động lại:"
echo "   - Replication: cd replication && ./setup-replication.sh" 
echo "   - Sharding: cd sharding && ./setup-sharding.sh"
echo "   - Hoặc: ./scripts/setup-all.sh"