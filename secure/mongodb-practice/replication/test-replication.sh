#!/bin/bash

# Test MongoDB Replication
# Kiểm tra việc đồng bộ dữ liệu giữa các nodes

echo "🧪 Bắt đầu test MongoDB Replication..."

# Kiểm tra replica set có đang chạy không
if ! pgrep -f "mongod.*--port 27017" > /dev/null; then
    echo "❌ Replica set không đang chạy. Chạy ./setup-replication.sh trước."
    exit 1
fi

echo ""
echo "📝 Bước 1: Thêm dữ liệu vào Primary node..."

# Thêm dữ liệu test vào primary
mongosh --port 27017 --quiet --eval "
use testReplication;
db.users.drop();
db.users.insertMany([
    { name: 'Alice', age: 25, role: 'developer' },
    { name: 'Bob', age: 30, role: 'designer' },
    { name: 'Charlie', age: 35, role: 'manager' }
]);
print('✅ Đã thêm ' + db.users.countDocuments() + ' documents vào primary node');
"

echo ""
echo "⏳ Đợi 3 giây để dữ liệu đồng bộ..."
sleep 3

echo ""
echo "🔍 Bước 2: Kiểm tra dữ liệu trên Secondary nodes..."

# Kiểm tra secondary node 1
echo "📊 Secondary Node 1 (Port 27018):"
mongosh --port 27018 --quiet --eval "
use testReplication
db.getMongo().setReadPref('secondary');
try {
    var count = db.users.countDocuments();
    if (count > 0) {
        print('✅ Tìm thấy ' + count + ' documents');
        db.users.find().forEach(function(doc) {
            print('   - ' + doc.name + ' (' + doc.age + ', ' + doc.role + ')');
        });
    } else {
        print('❌ Không tìm thấy dữ liệu');
    }
} catch (e) {
    print('❌ Lỗi khi đọc dữ liệu: ' + e.message);
}
"

echo ""
# Kiểm tra secondary node 2  
echo "📊 Secondary Node 2 (Port 27019):"
mongosh --port 27019 --quiet --eval "
use testReplication
db.getMongo().setReadPref('secondary');
try {
    var count = db.users.countDocuments();
    if (count > 0) {
        print('✅ Tìm thấy ' + count + ' documents');
        db.users.find().forEach(function(doc) {
            print('   - ' + doc.name + ' (' + doc.age + ', ' + doc.role + ')');
        });
    } else {
        print('❌ Không tìm thấy dữ liệu');
    }
} catch (e) {
    print('❌ Lỗi khi đọc dữ liệu: ' + e.message);
}
"

echo ""
echo "📈 Bước 3: Test Real-time Replication..."
echo "Thêm document mới và kiểm tra đồng bộ ngay lập tức..."

# Thêm document mới
mongosh --port 27017 --quiet --eval "
use testReplication;
db.users.insertOne({ name: 'David', age: 28, role: 'tester', timestamp: new Date() });
print('✅ Đã thêm document mới với timestamp');
"

echo "⏳ Đợi 2 giây..."
sleep 2

# Kiểm tra document mới trên secondary
mongosh --port 27018 --quiet --eval "
use testReplication
db.getMongo().setReadPref('secondary');
var newDoc = db.users.findOne({ name: 'David' });
if (newDoc) {
    print('✅ Document mới đã được đồng bộ: ' + newDoc.name + ' (created at: ' + newDoc.timestamp + ')');
} else {
    print('❌ Document mới chưa được đồng bộ');
}
"

echo ""
echo "🔄 Bước 4: Kiểm tra Replica Set Status..."
mongosh --port 27017 --quiet --eval "
print('=== REPLICA SET HEALTH CHECK ===');
var status = rs.status();
status.members.forEach(function(member) {
    var health = member.health == 1 ? '✅ Healthy' : '❌ Unhealthy';
    print('Node: ' + member.name + ' - State: ' + member.stateStr + ' - Health: ' + health);
});
print('');
print('Primary: ' + rs.isMaster().primary);
"

echo ""
echo "✅ Test replication hoàn tất!"
echo ""
echo "💡 Bạn có thể:"
echo "   - Kết nối tới bất kỳ node nào để xem dữ liệu"
echo "   - Test failover bằng cách dừng primary node"
echo "   - Monitor oplog: mongosh --port 27017 --eval \"db.oplog.rs.find().limit(5).sort({\\$natural:-1})\""