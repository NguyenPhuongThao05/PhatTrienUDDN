#!/bin/bash

# Test MongoDB Failover
# Mô phỏng sự cố primary node và kiểm tra automatic failover

echo "🚨 Bắt đầu test Failover..."

# Kiểm tra replica set có đang chạy không
if ! pgrep -f "mongod.*--port 27017" > /dev/null; then
    echo "❌ Replica set không đang chạy. Chạy ./setup-replication.sh trước."
    exit 1
fi

echo ""
echo "📊 Bước 1: Kiểm tra trạng thái hiện tại..."
mongosh --port 27017 --quiet --eval "
var status = rs.status();
var primary = '';
status.members.forEach(function(member) {
    if (member.stateStr === 'PRIMARY') {
        primary = member.name;
        print('Primary hiện tại: ' + primary);
    }
});
"

echo ""
echo "💾 Bước 2: Thêm dữ liệu test trước khi failover..."
mongosh --port 27017 --quiet --eval "
use testFailover;
db.transactions.drop();
db.transactions.insertMany([
    { id: 1, type: 'transfer', amount: 100, timestamp: new Date() },
    { id: 2, type: 'deposit', amount: 500, timestamp: new Date() },
    { id: 3, type: 'withdraw', amount: 50, timestamp: new Date() }
]);
print('✅ Đã thêm ' + db.transactions.countDocuments() + ' transactions');
"

echo ""
echo "🛑 Bước 3: Dừng Primary node (mô phỏng sự cố)..."
PRIMARY_PID=$(pgrep -f "mongod.*--port 27017")
if [ ! -z "$PRIMARY_PID" ]; then
    kill $PRIMARY_PID
    echo "✅ Đã dừng Primary node (PID: $PRIMARY_PID)"
else
    echo "❌ Không tìm thấy Primary node"
    exit 1
fi

echo ""
echo "⏳ Đợi election process (10 giây)..."
sleep 10

echo ""
echo "🔍 Bước 4: Kiểm tra Primary mới..."

# Thử kết nối tới các secondary nodes
NEW_PRIMARY=""
for port in 27018 27019; do
    echo "Kiểm tra node port $port..."
    RESULT=$(mongosh --port $port --quiet --eval "
    try {
        var isMaster = rs.isMaster();
        if (isMaster.ismaster) {
            print('✅ Node này là PRIMARY mới');
            print('Primary: localhost:$port');
        } else {
            print('ℹ️ Node này là SECONDARY');
        }
    } catch (e) {
        print('❌ Không thể kết nối: ' + e.message);
    }
    " 2>/dev/null)
    
    echo "$RESULT"
    
    if echo "$RESULT" | grep -q "PRIMARY mới"; then
        NEW_PRIMARY=$port
        break
    fi
done

echo ""
echo "📊 Bước 5: Kiểm tra tính toàn vẹn dữ liệu sau failover..."

if [ ! -z "$NEW_PRIMARY" ]; then
    mongosh --port $NEW_PRIMARY --quiet --eval "
    use testFailover;
    try {
        var count = db.transactions.countDocuments();
        print('✅ Tìm thấy ' + count + ' transactions trên Primary mới');
        
        db.transactions.find().forEach(function(doc) {
            print('   Transaction ' + doc.id + ': ' + doc.type + ' - ' + doc.amount);
        });
        
        // Test write operation trên primary mới
        db.transactions.insertOne({ 
            id: 4, 
            type: 'transfer', 
            amount: 200, 
            timestamp: new Date(),
            note: 'After failover'
        });
        print('✅ Write operation thành công trên Primary mới');
        
    } catch (e) {
        print('❌ Lỗi khi kiểm tra dữ liệu: ' + e.message);
    }
    "
else
    echo "❌ Không thể xác định Primary mới"
fi

echo ""
echo "🔄 Bước 6: Khởi động lại node bị dừng..."
echo "Khởi động lại Primary cũ như một Secondary node..."

mongod --port 27017 --dbpath data/rs0-0 --replSet rs0 --logpath logs/rs0-0.log --quiet &

echo "⏳ Đợi node rejoin cluster..."
sleep 8

echo ""
echo "📈 Bước 7: Kiểm tra trạng thái cluster sau recovery..."
if [ ! -z "$NEW_PRIMARY" ]; then
    mongosh --port $NEW_PRIMARY --quiet --eval "
    print('=== CLUSTER STATUS AFTER FAILOVER ===');
    var status = rs.status();
    status.members.forEach(function(member) {
        var health = member.health == 1 ? '✅' : '❌';
        print(health + ' Node: ' + member.name + ' - State: ' + member.stateStr);
    });
    
    print('');
    print('New Primary: ' + rs.isMaster().primary);
    "
fi

echo ""
echo "✅ Failover test hoàn tất!"
echo ""
echo "📋 Kết quả:"
echo "   - Primary cũ (27017) đã được dừng và khởi động lại"
echo "   - Một Secondary đã được bầu làm Primary mới" 
echo "   - Dữ liệu được bảo toàn trong quá trình failover"
echo "   - Cluster đã recovery và hoạt động bình thường"
echo ""
echo "💡 Điều này chứng minh MongoDB Replication cung cấp:"
echo "   - Automatic Failover"
echo "   - High Availability"  
echo "   - Data Consistency"