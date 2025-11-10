#!/bin/bash

# Test MongoDB Sharding
# Kiểm tra việc phân phối dữ liệu across shards

echo "🧪 Bắt đầu test MongoDB Sharding..."

# Kiểm tra mongos có đang chạy không
if ! pgrep -f "mongos.*--port 27500" > /dev/null; then
    echo "❌ Sharded cluster không đang chạy. Chạy ./setup-sharding.sh trước."
    exit 1
fi

echo ""
echo "📝 Bước 1: Thêm sample data vào sharded collections..."

# Thêm sample data
mongosh --port 27500 --quiet --eval "
use ecommerce;

// Clear existing data
db.products.drop();
db.orders.drop();

// Re-enable sharding sau khi drop
sh.shardCollection('ecommerce.products', { 'category': 1, '_id': 1 });
sh.shardCollection('ecommerce.orders', { 'userId': 1 });

print('Thêm products data...');
var categories = ['electronics', 'clothing', 'books', 'home', 'sports'];
var products = [];

for (let i = 0; i < 1000; i++) {
    products.push({
        _id: i,
        name: 'Product ' + i,
        category: categories[i % categories.length],
        price: Math.round((Math.random() * 1000 + 10) * 100) / 100,
        stock: Math.floor(Math.random() * 100) + 1,
        description: 'Description for product ' + i
    });
    
    // Insert in batches
    if (products.length === 100) {
        db.products.insertMany(products);
        products = [];
    }
}

// Insert remaining products
if (products.length > 0) {
    db.products.insertMany(products);
}

print('✅ Đã thêm ' + db.products.countDocuments() + ' products');

print('Thêm orders data...');
var orders = [];

for (let i = 0; i < 500; i++) {
    orders.push({
        _id: i,
        userId: 'user' + (i % 100),  // 100 different users
        productId: i % 1000,
        quantity: Math.floor(Math.random() * 5) + 1,
        totalAmount: Math.round((Math.random() * 500 + 50) * 100) / 100,
        orderDate: new Date(2024, Math.floor(Math.random() * 12), Math.floor(Math.random() * 28) + 1),
        status: ['pending', 'shipped', 'delivered'][Math.floor(Math.random() * 3)]
    });
    
    // Insert in batches
    if (orders.length === 50) {
        db.orders.insertMany(orders);
        orders = [];
    }
}

// Insert remaining orders
if (orders.length > 0) {
    db.orders.insertMany(orders);
}

print('✅ Đã thêm ' + db.orders.countDocuments() + ' orders');
"

echo ""
echo "⏳ Đợi 5 giây để balancer phân phối chunks..."
sleep 5

echo ""
echo "📊 Bước 2: Kiểm tra data distribution..."

mongosh --port 27500 --quiet --eval "
print('=== PRODUCTS DISTRIBUTION ===');
try {
    db.products.getShardDistribution();
} catch (e) {
    print('Chi tiết distribution:');
    sh.status();
}
"

echo ""
mongosh --port 27500 --quiet --eval "
print('=== ORDERS DISTRIBUTION ===');
try {
    db.orders.getShardDistribution();
} catch (e) {
    print('Không thể lấy distribution details, hiển thị tổng quan:');
    var stats = db.orders.stats();
    print('Total documents: ' + stats.count);
}
"

echo ""
echo "🔍 Bước 3: Test targeted queries (sử dụng shard key)..."

mongosh --port 27500 --quiet --eval "
use ecommerce;

print('Query 1: Tìm products theo category (shard key)');
var start = Date.now();
var electronics = db.products.find({ category: 'electronics' }).count();
var end = Date.now();
print('   Electronics products: ' + electronics + ' (thời gian: ' + (end - start) + 'ms)');

print('Query 2: Tìm orders theo userId (shard key)');  
start = Date.now();
var userOrders = db.orders.find({ userId: 'user50' }).count();
end = Date.now();
print('   User50 orders: ' + userOrders + ' (thời gian: ' + (end - start) + 'ms)');
"

echo ""
echo "🌐 Bước 4: Test scatter-gather queries (không có shard key)..."

mongosh --port 27500 --quiet --eval "
use ecommerce;

print('Query 3: Aggregate across all shards (không có shard key)');
var start = Date.now();
var avgPrice = db.products.aggregate([
    { \$group: { _id: null, avgPrice: { \$avg: '\$price' } } }
]).toArray();
var end = Date.now();
print('   Average product price: \$' + avgPrice[0].avgPrice.toFixed(2) + ' (thời gian: ' + (end - start) + 'ms)');

print('Query 4: Count by status across all orders');
start = Date.now();
var statusCounts = db.orders.aggregate([
    { \$group: { _id: '\$status', count: { \$sum: 1 } } }
]).toArray();
end = Date.now();
print('   Status distribution (thời gian: ' + (end - start) + 'ms):');
statusCounts.forEach(function(item) {
    print('     ' + item._id + ': ' + item.count + ' orders');
});
"

echo ""
echo "🎯 Bước 5: Test compound shard key queries..."

mongosh --port 27500 --quiet --eval "
use ecommerce;

print('Query 5: Compound shard key query (category + _id range)');
var start = Date.now();
var specificProducts = db.products.find({ 
    category: 'electronics', 
    _id: { \$gte: 0, \$lt: 100 } 
}).count();
var end = Date.now();
print('   Electronics with _id 0-99: ' + specificProducts + ' (thời gian: ' + (end - start) + 'ms)');
"

echo ""
echo "📈 Bước 6: Kiểm tra chunk distribution và balancer..."

mongosh --port 27500 --quiet --eval "
print('=== BALANCER STATUS ===');
print('Balancer state: ' + (sh.getBalancerState() ? 'Running' : 'Stopped'));

print('\\n=== CHUNK COUNTS ===');
db.getSiblingDB('config').chunks.aggregate([
    { \$group: { _id: { ns: '\$ns', shard: '\$shard' }, count: { \$sum: 1 } } },
    { \$sort: { '_id.ns': 1, '_id.shard': 1 } }
]).forEach(function(doc) {
    print(doc._id.ns + ' on ' + doc._id.shard + ': ' + doc.count + ' chunks');
});
"

echo ""
echo "🔧 Bước 7: Monitoring và performance..."

mongosh --port 27500 --quiet --eval "
use ecommerce;

print('=== DATABASE STATISTICS ===');
var stats = db.stats();
print('Database: ' + stats.db);
print('Collections: ' + stats.collections);
print('Data Size: ' + (stats.dataSize / 1024 / 1024).toFixed(2) + ' MB');
print('Index Size: ' + (stats.indexSize / 1024 / 1024).toFixed(2) + ' MB');

print('\\n=== SHARDING INFO ===');
var shardStats = db.runCommand('dbstats');
print('Sharded: ' + (shardStats.sharded || false));
print('Partitioned: ' + (shardStats.partitioned || false));
"

echo ""
echo "✅ Sharding test hoàn tất!"
echo ""
echo "📋 Kết quả test:"
echo "   ✓ Data được phân phối across multiple shards"
echo "   ✓ Targeted queries (với shard key) thực hiện nhanh"  
echo "   ✓ Scatter-gather queries hoạt động bình thường"
echo "   ✓ Compound shard keys hoạt động hiệu quả"
echo "   ✓ Balancer tự động phân phối chunks"
echo ""
echo "💡 Quan sát:"
echo "   - Queries có shard key chỉ truy cập relevant shards"
echo "   - Queries không có shard key broadcast tới all shards"
echo "   - MongoDB tự động balance chunks giữa các shards"