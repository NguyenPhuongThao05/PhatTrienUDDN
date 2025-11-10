# Hướng dẫn sử dụng MongoDB Replication & Sharding

## 📋 Lưu ý quan trọng

**Database files (`data/` và `logs/`) không được commit lên Git** vì:
- Kích thước lớn (100MB+) vượt quá giới hạn GitHub  
- Là dữ liệu tạm thời, được tạo lại khi chạy
- Mỗi máy sẽ có database riêng

## 🚀 Quick Start

### 1. Clone repository
```bash
git clone <repository-url>
cd mongodb-practice
```

### 2. Chạy thực hành
```bash
# Setup tất cả
./scripts/setup-all.sh

# Hoặc setup từng phần
cd replication && ./setup-replication.sh
cd ../sharding && ./setup-sharding.sh
```

### 3. Test các tính năng
```bash
# Test replication
cd replication
./test-replication.sh
./test-failover.sh

# Test sharding  
cd ../sharding
./test-sharding.sh
./test-shard-keys.sh
```

### 4. Health check
```bash
./scripts/health-check.sh
```

### 5. Cleanup khi xong
```bash
./scripts/cleanup-all.sh
```

## 📁 Cấu trúc thư mục sau khi chạy

```
mongodb-practice/
├── replication/
│   ├── data/          # ⚠️ Tự động tạo, không commit
│   ├── logs/          # ⚠️ Tự động tạo, không commit
│   └── *.sh          # Scripts
├── sharding/
│   ├── data/          # ⚠️ Tự động tạo, không commit  
│   ├── logs/          # ⚠️ Tự động tạo, không commit
│   └── *.sh          # Scripts
└── scripts/           # Utility scripts
```

## 🔧 Troubleshooting

### Nếu gặp lỗi "Port already in use"
```bash
./scripts/cleanup-all.sh
```

### Nếu muốn reset hoàn toàn
```bash
./scripts/cleanup-all.sh
# Chọn option 3 để xóa all data
```

### Check processes đang chạy
```bash
ps aux | grep mongod
```

## 📸 Screenshots để chứng minh

Chạy các lệnh sau để chụp màn hình:

1. **Replica Set Status:**
   ```bash
   mongosh --port 27018 --eval "rs.status()"
   ```

2. **Sharded Cluster Status:**
   ```bash
   mongosh --port 27500 --eval "sh.status()"
   ```

3. **Health Check:**
   ```bash
   ./scripts/health-check.sh
   ```

## ✅ Kết quả mong đợi

- **Replication**: 2-3 nodes active, 1 PRIMARY, 1-2 SECONDARY
- **Sharding**: 2 shards, 3 config servers, 1 mongos router
- **All connections**: ✅ CONNECTION OK