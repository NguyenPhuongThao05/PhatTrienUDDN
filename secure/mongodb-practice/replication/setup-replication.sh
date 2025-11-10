#!/bin/bash

# MongoDB Replication Setup Script
# Tự động khởi tạo replica set với 3 nodes

echo "🚀 Bắt đầu thiết lập MongoDB Replication..."

# Tạo thư mục dữ liệu và logs
echo "📁 Tạo thư mục dữ liệu..."
mkdir -p data/rs0-0 data/rs0-1 data/rs0-2
mkdir -p logs

# Kiểm tra MongoDB có được cài đặt không
if ! command -v mongod &> /dev/null; then
    echo "❌ MongoDB chưa được cài đặt. Vui lòng cài đặt MongoDB trước."
    exit 1
fi

# Dừng các process MongoDB đang chạy (nếu có)
echo "🛑 Dừng các MongoDB instances đang chạy..."
pkill -f "mongod.*--port 2701[789]" 2>/dev/null || true
sleep 2

# Khởi động MongoDB instances
echo "🔄 Khởi động Primary Node (Port 27017)..."
mongod --port 27017 --dbpath data/rs0-0 --replSet rs0 --logpath logs/rs0-0.log --quiet &

echo "🔄 Khởi động Secondary Node 1 (Port 27018)..."
mongod --port 27018 --dbpath data/rs0-1 --replSet rs0 --logpath logs/rs0-1.log --quiet &

echo "🔄 Khởi động Secondary Node 2 (Port 27019)..."
mongod --port 27019 --dbpath data/rs0-2 --replSet rs0 --logpath logs/rs0-2.log --quiet &

# Đợi các instances khởi động
echo "⏳ Đợi MongoDB instances khởi động..."
sleep 5

# Khởi tạo replica set
echo "⚙️ Khởi tạo Replica Set..."
mongosh --port 27017 --quiet --eval "
rs.initiate({
    _id: 'rs0',
    members: [
        { _id: 0, host: 'localhost:27017' },
        { _id: 1, host: 'localhost:27018' },
        { _id: 2, host: 'localhost:27019' }
    ]
})
"

# Đợi replica set khởi tạo
echo "⏳ Đợi Replica Set khởi tạo..."
sleep 10

# Kiểm tra trạng thái
echo "📊 Kiểm tra trạng thái Replica Set..."
mongosh --port 27017 --quiet --eval "
print('=== REPLICA SET STATUS ===');
rs.status().members.forEach(function(member) {
    print('Node: ' + member.name + ' - State: ' + member.stateStr);
});
print('');
print('Primary Node: ' + rs.isMaster().primary);
"

echo ""
echo "✅ Thiết lập Replica Set hoàn tất!"
echo ""
echo "📋 Thông tin kết nối:"
echo "   Primary: mongosh --port 27017"
echo "   Secondary 1: mongosh --port 27018" 
echo "   Secondary 2: mongosh --port 27019"
echo ""
echo "🧪 Test replication bằng cách chạy:"
echo "   ./test-replication.sh"
echo ""
echo "🛑 Để dừng replica set:"
echo "   ./stop-replication.sh"