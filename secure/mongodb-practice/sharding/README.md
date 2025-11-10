# MongoDB Sharding - Thực hành

## Khái niệm Sharding

MongoDB Sharding là quá trình phân tán dữ liệu theo chiều ngang (horizontal partitioning) trên nhiều server để:
- **Xử lý datasets lớn (Handle Large Datasets)**
- **Tăng hiệu suất đọc/ghi (Performance Scaling)**
- **Phân phối tải (Load Distribution)**
- **Mở rộng storage capacity**

## Kiến trúc Sharded Cluster

Một Sharded Cluster bao gồm:

### 1. Shards
- Mỗi shard chứa một subset của dữ liệu
- Thường được cấu hình như replica sets để đảm bảo high availability
- Dữ liệu được phân chia dựa trên shard key

### 2. Config Servers  
- Lưu trữ metadata về cluster
- Thông tin về chunks và data distribution
- Cấu hình như replica set (3 config servers)

### 3. Query Routers (mongos)
- Điểm kết nối cho client applications
- Route queries tới appropriate shards
- Aggregate results từ multiple shards

## Thực hành: Thiết lập Sharded Cluster

### Yêu cầu

- MongoDB đã được cài đặt
- Tối thiểu 9 ports cho complete setup

### Bước 1: Tạo thư mục dữ liệu

```bash
# Config servers
mkdir -p data/config/config0 data/config/config1 data/config/config2

# Shards (mỗi shard có 2 replicas)
mkdir -p data/shard0/shard0_0 data/shard0/shard0_1
mkdir -p data/shard1/shard1_0 data/shard1/shard1_1

mkdir -p logs
```

### Bước 2: Khởi động Config Servers

```bash
# Config Server Replica Set (Ports 27100, 27101, 27102)
mongod --configsvr --replSet configReplSet --port 27100 --dbpath data/config/config0 --logpath logs/config0.log --fork

mongod --configsvr --replSet configReplSet --port 27101 --dbpath data/config/config1 --logpath logs/config1.log --fork

mongod --configsvr --replSet configReplSet --port 27102 --dbpath data/config/config2 --logpath logs/config2.log --fork
```

Khởi tạo config replica set:
```bash
mongosh --port 27100 --eval "
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
```

### Bước 3: Khởi động Shard Servers

**Shard 0 Replica Set (Ports 27200, 27201):**
```bash
mongod --shardsvr --replSet shard0ReplSet --port 27200 --dbpath data/shard0/shard0_0 --logpath logs/shard0_0.log --fork

mongod --shardsvr --replSet shard0ReplSet --port 27201 --dbpath data/shard0/shard0_1 --logpath logs/shard0_1.log --fork
```

Khởi tạo shard 0:
```bash
mongosh --port 27200 --eval "
rs.initiate({
    _id: 'shard0ReplSet',
    members: [
        { _id: 0, host: 'localhost:27200' },
        { _id: 1, host: 'localhost:27201' }
    ]
})
"
```

**Shard 1 Replica Set (Ports 27300, 27301):**
```bash
mongod --shardsvr --replSet shard1ReplSet --port 27300 --dbpath data/shard1/shard1_0 --logpath logs/shard1_0.log --fork

mongod --shardsvr --replSet shard1ReplSet --port 27301 --dbpath data/shard1/shard1_1 --logpath logs/shard1_1.log --fork
```

Khởi tạo shard 1:
```bash
mongosh --port 27300 --eval "
rs.initiate({
    _id: 'shard1ReplSet', 
    members: [
        { _id: 0, host: 'localhost:27300' },
        { _id: 1, host: 'localhost:27301' }
    ]
})
"
```

### Bước 4: Khởi động Query Router (mongos)

```bash
# Query Router (Port 27500)
mongos --configdb configReplSet/localhost:27100,localhost:27101,localhost:27102 --port 27500 --logpath logs/mongos.log --fork
```

### Bước 5: Thêm Shards vào Cluster

Kết nối tới mongos:
```bash
mongosh --port 27500
```

Thêm các shards:
```javascript
// Thêm shard 0
sh.addShard("shard0ReplSet/localhost:27200,localhost:27201")

// Thêm shard 1  
sh.addShard("shard1ReplSet/localhost:27300,localhost:27301")

// Kiểm tra cluster status
sh.status()
```

### Bước 6: Enable Sharding và Shard Collections

```javascript
// Enable sharding cho database
sh.enableSharding("ecommerce")

// Shard collection với shard key
sh.shardCollection("ecommerce.products", { "category": 1, "_id": 1 })
sh.shardCollection("ecommerce.orders", { "userId": 1 })

// Kiểm tra sharding status
db.printShardingStatus()
```

### Bước 7: Test Sharding với Sample Data

```javascript
use ecommerce

// Thêm sample products
for (let i = 0; i < 1000; i++) {
    db.products.insertOne({
        _id: i,
        name: "Product " + i,
        category: ["electronics", "clothing", "books", "home"][i % 4],
        price: Math.random() * 1000,
        stock: Math.floor(Math.random() * 100)
    });
}

// Thêm sample orders
for (let i = 0; i < 500; i++) {
    db.orders.insertOne({
        _id: i,
        userId: "user" + (i % 50),
        productId: i % 1000,
        quantity: Math.floor(Math.random() * 5) + 1,
        orderDate: new Date()
    });
}

// Kiểm tra data distribution
sh.status()
```

## Các lệnh quan trọng

```javascript
// Kiểm tra cluster config
sh.status()

// Xem chunks distribution
db.printShardingStatus()

// Kiểm tra shard key cho collection
db.products.getShardDistribution()

// Balancer operations
sh.getBalancerState()
sh.startBalancer()
sh.stopBalancer()

// Move chunks manually (if needed)
sh.moveChunk("ecommerce.products", 
    { "category": "electronics", "_id": MinKey }, 
    "shard1ReplSet")
```

## Shard Key Selection

### Good Shard Keys:
- **High Cardinality**: Nhiều giá trị unique
- **Even Distribution**: Phân phối đều data
- **Non-Monotonic**: Không tăng dần theo thời gian

### Examples:
```javascript
// Good shard keys
{ "userId": 1 }                    // High cardinality
{ "category": 1, "_id": 1 }        // Compound key
{ "location": 1, "timestamp": 1 }   // Geographic + temporal

// Poor shard keys  
{ "_id": 1 }           // Monotonic (ObjectId)
{ "timestamp": 1 }     // Monotonic
{ "status": 1 }        // Low cardinality
```

## Monitoring Sharded Cluster

```javascript
// Connection info
db.runCommand("isdbgrid")

// Shard statistics
db.stats()

// Collection sharding info
db.products.stats()

// Chunk info
db.chunks.find().pretty()

// Active migrations
sh.isBalancerRunning()
```

## Lợi ích của Sharding

1. **Horizontal Scaling**: Tăng capacity bằng cách thêm shards
2. **Performance**: Parallel processing trên multiple shards  
3. **Storage**: Phân phối storage load
4. **Geographic Distribution**: Shards có thể ở các location khác nhau

## Lưu ý quan trọng

- Shard key không thể thay đổi sau khi đã chọn
- Queries không có shard key sẽ broadcast tới all shards
- Config servers phải là replica set (3 nodes)
- Balancer tự động di chuyển chunks để cân bằng load
- Cần monitor chunk size và distribution thường xuyên