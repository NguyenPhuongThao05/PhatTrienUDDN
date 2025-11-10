#!/bin/bash

# Test MongoDB Shard Key Performance
# So sánh performance của different shard key strategies

echo "⚡ Bắt đầu test Shard Key Performance..."

# Kiểm tra mongos có đang chạy không
if ! pgrep -f "mongos.*--port 27500" > /dev/null; then
    echo "❌ Sharded cluster không đang chạy. Chạy ./setup-sharding.sh trước."
    exit 1
fi

echo ""
echo "📋 Test Setup: So sánh các shard key strategies..."

mongosh --port 27500 --quiet --eval "
use performance_test;

// Drop existing collections
db.good_shard.drop();
db.poor_shard.drop();
db.monotonic_shard.drop();

print('Setting up collections với different shard keys...');

// Collection 1: Good shard key (userId - high cardinality, even distribution)
sh.shardCollection('performance_test.good_shard', { 'userId': 1 });

// Collection 2: Poor shard key (status - low cardinality) 
sh.shardCollection('performance_test.poor_shard', { 'status': 1 });

// Collection 3: Monotonic shard key (_id - always increasing)
sh.shardCollection('performance_test.monotonic_shard', { '_id': 1 });

print('✅ Collections setup hoàn tất');
"

echo ""
echo "📊 Test 1: Insert Performance với different shard keys..."

mongosh --port 27500 --quiet --eval "
use performance_test;

var userIds = [];
for (let i = 0; i < 100; i++) {
    userIds.push('user' + Math.floor(Math.random() * 1000));
}

var statuses = ['active', 'inactive', 'pending'];

print('=== INSERT PERFORMANCE TEST ===');

// Test 1: Good shard key (userId)
print('\\n1. Good Shard Key (userId):');
var start = Date.now();
for (let i = 0; i < 1000; i++) {
    db.good_shard.insertOne({
        _id: i,
        userId: userIds[i % userIds.length],
        data: 'Sample data ' + i,
        timestamp: new Date(),
        value: Math.random() * 100
    });
}
var goodTime = Date.now() - start;
print('   Time: ' + goodTime + 'ms for 1000 inserts');

// Test 2: Poor shard key (status) 
print('\\n2. Poor Shard Key (status):');
start = Date.now();
for (let i = 0; i < 1000; i++) {
    db.poor_shard.insertOne({
        _id: i,
        status: statuses[i % statuses.length],
        userId: userIds[i % userIds.length],
        data: 'Sample data ' + i,
        timestamp: new Date(),
        value: Math.random() * 100
    });
}
var poorTime = Date.now() - start;
print('   Time: ' + poorTime + 'ms for 1000 inserts');

// Test 3: Monotonic shard key (_id)
print('\\n3. Monotonic Shard Key (_id):');
start = Date.now();
for (let i = 0; i < 1000; i++) {
    db.monotonic_shard.insertOne({
        _id: i,
        userId: userIds[i % userIds.length],
        status: statuses[i % statuses.length], 
        data: 'Sample data ' + i,
        timestamp: new Date(),
        value: Math.random() * 100
    });
}
var monotonicTime = Date.now() - start;
print('   Time: ' + monotonicTime + 'ms for 1000 inserts');

print('\\n=== INSERT PERFORMANCE COMPARISON ===');
print('Good Shard Key:      ' + goodTime + 'ms');
print('Poor Shard Key:      ' + poorTime + 'ms'); 
print('Monotonic Shard Key: ' + monotonicTime + 'ms');
"

echo ""
echo "⏳ Đợi 5 giây để balancer hoạt động..."
sleep 5

echo ""
echo "🎯 Test 2: Query Performance với shard keys..."

mongosh --port 27500 --quiet --eval "
use performance_test;

print('=== QUERY PERFORMANCE TEST ===');

// Query 1: Targeted query with good shard key
print('\\n1. Targeted Query (Good Shard Key):');
var start = Date.now();
var result1 = db.good_shard.find({ userId: 'user500' }).count();
var queryTime1 = Date.now() - start;
print('   Result: ' + result1 + ' documents');
print('   Time: ' + queryTime1 + 'ms (targeted to specific shard)');

// Query 2: Targeted query with poor shard key
print('\\n2. Targeted Query (Poor Shard Key):');
start = Date.now();
var result2 = db.poor_shard.find({ status: 'active' }).count();
var queryTime2 = Date.now() - start;
print('   Result: ' + result2 + ' documents');
print('   Time: ' + queryTime2 + 'ms (may hit multiple shards due to uneven distribution)');

// Query 3: Range query with monotonic key
print('\\n3. Range Query (Monotonic Shard Key):');
start = Date.now();
var result3 = db.monotonic_shard.find({ _id: { \$gte: 100, \$lt: 200 } }).count();
var queryTime3 = Date.now() - start;
print('   Result: ' + result3 + ' documents');
print('   Time: ' + queryTime3 + 'ms (range query on shard key)');

print('\\n=== QUERY PERFORMANCE COMPARISON ===');
print('Good Shard Key Query:      ' + queryTime1 + 'ms');
print('Poor Shard Key Query:      ' + queryTime2 + 'ms');
print('Monotonic Shard Key Query: ' + queryTime3 + 'ms');
"

echo ""
echo "📈 Test 3: Data Distribution Analysis..."

mongosh --port 27500 --quiet --eval "
use performance_test;

print('=== DATA DISTRIBUTION ANALYSIS ===');

// Analyze chunk distribution
db.getSiblingDB('config').chunks.aggregate([
    { \$match: { ns: { \$regex: '^performance_test\\.' } } },
    { \$group: { 
        _id: { collection: '\$ns', shard: '\$shard' }, 
        chunkCount: { \$sum: 1 } 
    }},
    { \$sort: { '_id.collection': 1, '_id.shard': 1 } }
]).forEach(function(doc) {
    var collection = doc._id.collection.replace('performance_test.', '');
    print(collection + ' on ' + doc._id.shard + ': ' + doc.chunkCount + ' chunks');
});

print('\\n=== SHARD KEY CARDINALITY ===');

// Check cardinality for each shard key
var goodCardinal = db.good_shard.distinct('userId').length;
print('Good Shard Key (userId) cardinality: ' + goodCardinal);

var poorCardinal = db.poor_shard.distinct('status').length;
print('Poor Shard Key (status) cardinality: ' + poorCardinal);

var monotonicCardinal = db.monotonic_shard.distinct('_id').length;
print('Monotonic Shard Key (_id) cardinality: ' + monotonicCardinal);
"

echo ""
echo "🔍 Test 4: Hot Spotting Detection..."

mongosh --port 27500 --quiet --eval "
use performance_test;

print('=== HOT SPOTTING ANALYSIS ===');
print('Detecting write hotspots by analyzing chunk ranges...');

// Simulate more writes to demonstrate hotspotting
print('\\nInserting additional data to demonstrate patterns...');

// Add more data with monotonic pattern (creates hotspot)
var start = Date.now();
for (let i = 1000; i < 1500; i++) {
    db.monotonic_shard.insertOne({
        _id: i,
        userId: 'user' + (i % 100),
        data: 'Additional data ' + i,
        timestamp: new Date()
    });
}
var hotspotTime = Date.now() - start;
print('Monotonic inserts (hotspot prone): ' + hotspotTime + 'ms for 500 inserts');

// Add more data with good distribution
start = Date.now();
for (let i = 1000; i < 1500; i++) {
    db.good_shard.insertOne({
        _id: i,
        userId: 'user' + Math.floor(Math.random() * 1000),
        data: 'Additional data ' + i,
        timestamp: new Date()
    });
}
var distributedTime = Date.now() - start;
print('Distributed inserts (good shard key): ' + distributedTime + 'ms for 500 inserts');

print('\\nHotspot Detection:');
if (hotspotTime > distributedTime * 1.2) {
    print('⚠️ Detected potential hotspot with monotonic shard key');
} else {
    print('✅ No significant hotspot detected');
}
"

echo ""
echo "📊 Bước 5: Recommendations..."

mongosh --port 27500 --quiet --eval "
print('=== SHARD KEY RECOMMENDATIONS ===');
print('');
print('✅ GOOD SHARD KEY CHARACTERISTICS:');
print('   - High Cardinality (nhiều giá trị unique)');
print('   - Even Write Distribution (phân phối đều)');  
print('   - Query Isolation (queries chỉ cần 1 shard)');
print('   - Non-Monotonic (không tăng dần theo thời gian)');
print('');
print('❌ AVOID THESE SHARD KEYS:');
print('   - Low Cardinality (ít giá trị unique)');
print('   - Monotonic Fields (_id, timestamp)');
print('   - Fields with Hotspots (tập trung vào 1 shard)');
print('   - Frequently NULL values');
print('');
print('🎯 BEST PRACTICES:');
print('   - Use compound shard keys for better distribution');
print('   - Consider hashed shard keys for monotonic fields');
print('   - Monitor chunk distribution regularly'); 
print('   - Test with production-like data volumes');
"

echo ""
echo "✅ Shard Key Performance test hoàn tất!"
echo ""
echo "📋 Kết quả:"
echo "   ✓ So sánh performance của different shard key strategies"
echo "   ✓ Phân tích data distribution patterns"
echo "   ✓ Detect potential hotspotting issues"
echo "   ✓ Đưa ra recommendations cho shard key selection"
echo ""
echo "💡 Key Takeaways:"
echo "   - Shard key selection ảnh hưởng lớn đến performance"
echo "   - High cardinality shard keys phân phối tốt hơn"
echo "   - Monotonic shard keys có thể tạo hotspots"
echo "   - Monitor và test với real-world data là quan trọng"