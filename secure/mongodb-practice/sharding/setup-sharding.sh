#!/bin/bash

# MongoDB Sharding Setup Script
# Tự động khởi tạo sharded cluster với config servers, shards, và mongos

echo "🚀 Bắt đầu thiết lập MongoDB Sharded Cluster..."

# Kiểm tra MongoDB có được cài đặt không
if ! command -v mongod &> /dev/null; then
    echo "❌ MongoDB chưa được cài đặt. Vui lòng cài đặt MongoDB trước."
    exit 1
fi

# Dừng các process MongoDB đang chạy (nếu có)
echo "🛑 Dừng các MongoDB instances đang chạy..."
pkill -f "mongod.*--port 271[0-9][0-9]" 2>/dev/null || true
pkill -f "mongos.*--port 275[0-9][0-9]" 2>/dev/null || true
sleep 2

# Tạo thư mục dữ liệu và logs
echo "📁 Tạo thư mục dữ liệu..."
mkdir -p data/config/config0 data/config/config1 data/config/config2
mkdir -p data/shard0/shard0_0 data/shard0/shard0_1
mkdir -p data/shard1/shard1_0 data/shard1/shard1_1
mkdir -p logs

echo ""
echo "⚙️ BƯỚC 1: Khởi động Config Servers..."

# Khởi động Config Servers (Ports 27100, 27101, 27102)
echo "🔧 Config Server 0 (Port 27100)..."
mongod --configsvr --replSet configReplSet --port 27100 --dbpath data/config/config0 --logpath logs/config0.log --quiet &

echo "🔧 Config Server 1 (Port 27101)..."
mongod --configsvr --replSet configReplSet --port 27101 --dbpath data/config/config1 --logpath logs/config1.log --quiet &

echo "🔧 Config Server 2 (Port 27102)..."
mongod --configsvr --replSet configReplSet --port 27102 --dbpath data/config/config2 --logpath logs/config2.log --quiet &

echo "⏳ Đợi Config Servers khởi động..."
sleep 5

# Khởi tạo Config Replica Set
echo "🔄 Khởi tạo Config Replica Set..."
mongosh --port 27100 --quiet --eval "
rs.initiate({
    _id: 'configReplSet',
    configsvr: true,
    members: [
        { _id: 0, host: 'localhost:27100' },
        { _id: 1, host: 'localhost:27101' },
        { _id: 2, host: 'localhost:27102' }
    ]
})
"

echo "⏳ Đợi Config Replica Set khởi tạo..."
sleep 8

echo ""
echo "⚙️ BƯỚC 2: Khởi động Shard Servers..."

# Shard 0 (Ports 27200, 27201)
echo "🗂️ Shard 0 - Node 0 (Port 27200)..."
mongod --shardsvr --replSet shard0ReplSet --port 27200 --dbpath data/shard0/shard0_0 --logpath logs/shard0_0.log --quiet &

echo "🗂️ Shard 0 - Node 1 (Port 27201)..."
mongod --shardsvr --replSet shard0ReplSet --port 27201 --dbpath data/shard0/shard0_1 --logpath logs/shard0_1.log --quiet &

echo "⏳ Đợi Shard 0 khởi động..."
sleep 3

# Khởi tạo Shard 0 Replica Set
echo "🔄 Khởi tạo Shard 0 Replica Set..."
mongosh --port 27200 --quiet --eval "
rs.initiate({
    _id: 'shard0ReplSet',
    members: [
        { _id: 0, host: 'localhost:27200' },
        { _id: 1, host: 'localhost:27201' }
    ]
})
"

# Shard 1 (Ports 27300, 27301)
echo "🗂️ Shard 1 - Node 0 (Port 27300)..."
mongod --shardsvr --replSet shard1ReplSet --port 27300 --dbpath data/shard1/shard1_0 --logpath logs/shard1_0.log --quiet &

echo "🗂️ Shard 1 - Node 1 (Port 27301)..."
mongod --shardsvr --replSet shard1ReplSet --port 27301 --dbpath data/shard1/shard1_1 --logpath logs/shard1_1.log --quiet &

echo "⏳ Đợi Shard 1 khởi động..."
sleep 3

# Khởi tạo Shard 1 Replica Set
echo "🔄 Khởi tạo Shard 1 Replica Set..."
mongosh --port 27300 --quiet --eval "
rs.initiate({
    _id: 'shard1ReplSet',
    members: [
        { _id: 0, host: 'localhost:27300' },
        { _id: 1, host: 'localhost:27301' }
    ]
})
"

echo "⏳ Đợi Shard Replica Sets khởi tạo..."
sleep 8

echo ""
echo "⚙️ BƯỚC 3: Khởi động Query Router (mongos)..."

# Query Router (Port 27500)
mongos --configdb configReplSet/localhost:27100,localhost:27101,localhost:27102 --port 27500 --logpath logs/mongos.log &

echo "⏳ Đợi mongos khởi động..."
sleep 5

echo ""
echo "⚙️ BƯỚC 4: Cấu hình Sharded Cluster..."

# Thêm shards vào cluster
echo "🔗 Thêm Shards vào cluster..."
mongosh --port 27500 --quiet --eval "
print('Thêm Shard 0...');
sh.addShard('shard0ReplSet/localhost:27200,localhost:27201');

print('Thêm Shard 1...');
sh.addShard('shard1ReplSet/localhost:27300,localhost:27301');

print('✅ Đã thêm tất cả shards');
"

echo ""
echo "⚙️ BƯỚC 5: Thiết lập Database và Collections..."

# Enable sharding và tạo sharded collections
mongosh --port 27500 --quiet --eval "
print('Enable sharding cho database ecommerce...');
sh.enableSharding('ecommerce');

print('Shard collection products với key {category: 1, _id: 1}...');
sh.shardCollection('ecommerce.products', { 'category': 1, '_id': 1 });

print('Shard collection orders với key {userId: 1}...');
sh.shardCollection('ecommerce.orders', { 'userId': 1 });

print('✅ Sharding setup hoàn tất');
"

echo ""
echo "📊 Kiểm tra trạng thái cluster..."
mongosh --port 27500 --quiet --eval "
print('=== SHARDED CLUSTER STATUS ===');
var status = sh.status();
"

echo ""
echo "✅ Thiết lập Sharded Cluster hoàn tất!"
echo ""
echo "📋 Thông tin kết nối:"
echo "   Query Router (mongos): mongosh --port 27500"
echo "   Config Servers: ports 27100, 27101, 27102"
echo "   Shard 0: ports 27200, 27201" 
echo "   Shard 1: ports 27300, 27301"
echo ""
echo "🧪 Test sharding bằng cách chạy:"
echo "   ./test-sharding.sh"
echo ""
echo "🛑 Để dừng sharded cluster:"
echo "   ./stop-sharding.sh"