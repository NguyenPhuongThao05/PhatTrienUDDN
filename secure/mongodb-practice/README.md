# MongoDB Replication & Sharding - Thực hành

Bài thực hành chi tiết về **MongoDB Replication** và **Sharding** theo tài liệu tham khảo [GeeksforGeeks](https://www.geeksforgeeks.org/mongodb/mongodb-replication-and-sharding/).

## 📋 Tổng quan

### Replication vs Sharding

| Khía cạnh | **Replication** | **Sharding** |
|-----------|----------------|---------------|
| **Mục đích** | Data redundancy, High availability | Horizontal scaling, Large datasets |
| **Cách thức** | Copies data across multiple servers | Splits data across multiple servers |
| **Thành phần** | Primary và Secondary nodes | Shards, Config servers, Query routers |
| **Operations** | Primary xử lý writes; Secondary có thể handle reads | Mỗi shard xử lý part của data |
| **Lợi ích chính** | Fault tolerance, Data backup, Read scaling | Performance, Scalability, Storage capacity |
| **Sử dụng khi** | Cần reliability và availability | Quản lý large datasets hiệu quả |

## 🏗️ Cấu trúc Project

```
mongodb-practice/
├── README.md                     # File này
├── replication/                  # Bài thực hành Replication
│   ├── README.md                # Hướng dẫn chi tiết Replication
│   ├── setup-replication.sh     # Setup replica set
│   ├── test-replication.sh      # Test data synchronization
│   ├── test-failover.sh         # Test automatic failover
│   └── stop-replication.sh      # Dừng replica set
├── sharding/                     # Bài thực hành Sharding
│   ├── README.md                # Hướng dẫn chi tiết Sharding
│   ├── setup-sharding.sh        # Setup sharded cluster
│   ├── test-sharding.sh         # Test data distribution
│   ├── test-shard-keys.sh       # Test shard key performance
│   └── stop-sharding.sh         # Dừng sharded cluster
└── scripts/                      # Utility scripts
    ├── setup-all.sh             # Master setup script
    ├── cleanup-all.sh           # Cleanup tất cả
    └── health-check.sh          # Health check tool
```

## 🚀 Quick Start

### Yêu cầu hệ thống
- **MongoDB** đã được cài đặt
- **macOS/Linux** với bash shell
- Tối thiểu **9 ports** available (27017-27019, 27100-27102, 27200-27201, 27300-27301, 27500)

### Cài đặt MongoDB (nếu chưa có)

**macOS:**
```bash
brew tap mongodb/brew
brew install mongodb-community
```

**Ubuntu/Debian:**
```bash
sudo apt update
sudo apt install mongodb
```

### Setup nhanh

1. **Setup tất cả:**
```bash
cd mongodb-practice
./scripts/setup-all.sh
```

2. **Hoặc setup từng cái:**
```bash
# Chỉ Replication
cd replication
./setup-replication.sh

# Chỉ Sharding  
cd sharding
./setup-sharding.sh
```

## 📚 Hướng dẫn thực hành

### 🔄 Thực hành 1: MongoDB Replication

**Mục tiêu:** Hiểu và thực hành Replica Set để đảm bảo high availability

**Các bước thực hành:**

1. **Setup Replica Set:**
```bash
cd replication
./setup-replication.sh
```

2. **Test Data Replication:**
```bash
./test-replication.sh
```

3. **Test Automatic Failover:**
```bash
./test-failover.sh
```

4. **Dừng Replica Set:**
```bash
./stop-replication.sh
```

**Kết quả học được:**
- Cách thiết lập và quản lý Replica Set
- Hiểu về Primary/Secondary roles
- Automatic failover và election process
- Data synchronization giữa các nodes

### 🗂️ Thực hành 2: MongoDB Sharding

**Mục tiêu:** Hiểu và thực hành Sharded Cluster để scale horizontally

**Các bước thực hành:**

1. **Setup Sharded Cluster:**
```bash
cd sharding  
./setup-sharding.sh
```

2. **Test Data Distribution:**
```bash
./test-sharding.sh
```

3. **Test Shard Key Performance:**
```bash
./test-shard-keys.sh
```

4. **Dừng Sharded Cluster:**
```bash
./stop-sharding.sh
```

**Kết quả học được:**
- Kiến trúc Sharded Cluster (Shards, Config Servers, Mongos)
- Shard key selection và impact lên performance
- Data distribution và balancing
- Query routing và optimization

## 🛠️ Utility Scripts

### Health Check
Kiểm tra trạng thái tất cả MongoDB instances:
```bash
./scripts/health-check.sh
```

### Cleanup All
Dừng và cleanup tất cả MongoDB instances:
```bash  
./scripts/cleanup-all.sh
```

### Master Setup
Setup interactive cho cả Replication và Sharding:
```bash
./scripts/setup-all.sh
```

## 📊 Ports và Services

### Replication Ports
- **27017**: Primary Node
- **27018**: Secondary Node 1  
- **27019**: Secondary Node 2

### Sharding Ports
- **27100-27102**: Config Servers
- **27200-27201**: Shard 0 (Replica Set)
- **27300-27301**: Shard 1 (Replica Set)
- **27500**: Query Router (mongos)

## 🔍 Kết nối và Testing

### Replication
```bash
# Connect to Primary
mongosh --port 27017

# Connect to Secondary (read-only)
mongosh --port 27018
```

### Sharding
```bash
# Connect through Query Router
mongosh --port 27500

# Direct connect to shard
mongosh --port 27200  # Shard 0
mongosh --port 27300  # Shard 1
```

## 🧪 Sample Commands

### Replication Commands
```javascript
// Replica set status
rs.status()

// Check primary
rs.isMaster()

// Add new member
rs.add("localhost:27020")

// Enable secondary reads
rs.slaveOk() // Deprecated
db.getMongo().setReadPref('secondary') // New way
```

### Sharding Commands  
```javascript
// Shard status
sh.status()

// Enable sharding on database
sh.enableSharding("myapp")

// Shard a collection
sh.shardCollection("myapp.users", { "userId": 1 })

// Check data distribution
db.users.getShardDistribution()

// Balancer status
sh.getBalancerState()
```

## ⚡ Performance Tips

### Replication Best Practices
- Sử dụng số lẻ members (3, 5, 7...) để tránh split-brain
- Cấu hình read preference phù hợp với use case
- Monitor oplog size và replication lag
- Sử dụng appropriate write concern

### Sharding Best Practices  
- Chọn shard key có high cardinality và even distribution
- Tránh monotonic shard keys (như _id, timestamp)
- Monitor chunk distribution và balancer activity
- Consider compound shard keys cho better distribution
- Pre-split chunks cho known data patterns

## 🚨 Troubleshooting

### Common Issues

1. **Port already in use:**
```bash
# Kill MongoDB processes
pkill mongod
pkill mongos
```

2. **Permission denied on data directories:**
```bash
sudo chown -R $(whoami) data/
```

3. **Replica set initialization fails:**
```bash
# Check logs
tail logs/rs0-*.log

# Restart with clean state
rm -rf data/ logs/
```

4. **Sharding setup incomplete:**
```bash
# Use health check to diagnose
./scripts/health-check.sh
```

## 🎯 Learning Objectives

Sau khi hoàn thành thực hành này, bạn sẽ:

✅ **Hiểu rõ khái niệm Replication:**
- Replica Set architecture và components
- Primary/Secondary roles và responsibilities  
- Automatic failover mechanisms
- Data synchronization và oplog

✅ **Hiểu rõ khái niệm Sharding:**
- Sharded Cluster architecture
- Shard key selection strategies
- Data distribution và balancing
- Query routing và performance implications

✅ **Kỹ năng thực hành:**
- Thiết lập và quản lý MongoDB clusters
- Monitoring và troubleshooting
- Performance optimization
- Best practices cho production deployment

## 📖 Tài liệu tham khảo

- [MongoDB Replication and Sharding - GeeksforGeeks](https://www.geeksforgeeks.org/mongodb/mongodb-replication-and-sharding/)
- [MongoDB Official Documentation - Replication](https://docs.mongodb.com/manual/replication/)
- [MongoDB Official Documentation - Sharding](https://docs.mongodb.com/manual/sharding/)
- [MongoDB Best Practices](https://docs.mongodb.com/manual/administration/production-notes/)

---

## 📝 Notes

- Thực hành này được thiết kế cho môi trường development/learning
- Để deploy production, cần cấu hình thêm security, monitoring, và backup
- Test với data volume lớn hơn để hiểu rõ performance characteristics
- Consider network topology và geographic distribution cho production clusters

**Happy Learning! 🎓**