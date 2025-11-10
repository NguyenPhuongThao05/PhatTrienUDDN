# MongoDB Replication - Thực hành

## Khái niệm Replication

MongoDB Replication là quá trình tạo nhiều bản sao dữ liệu trên các server khác nhau để đảm bảo:
- **Tính sẵn sàng cao (High Availability)**
- **Khả năng chịu lỗi (Fault Tolerance)**  
- **Dự phòng dữ liệu (Data Redundancy)**
- **Mở rộng khả năng đọc (Read Scaling)**

## Cấu trúc Replica Set

Một Replica Set bao gồm:
- **Primary Node**: Xử lý tất cả write operations
- **Secondary Nodes**: Duy trì bản sao dữ liệu, có thể xử lý read operations
- **Arbiter (tùy chọn)**: Tham gia bầu cử nhưng không chứa dữ liệu

## Thực hành: Thiết lập Replica Set

### Yêu cầu

- MongoDB đã được cài đặt
- Tối thiểu 3 ports khác nhau (27017, 27018, 27019)

### Bước 1: Tạo thư mục dữ liệu

```bash
mkdir -p data/rs0-0 data/rs0-1 data/rs0-2
mkdir -p logs
```

### Bước 2: Khởi động các MongoDB instances

**Primary Node (Port 27017):**
```bash
mongod --port 27017 --dbpath data/rs0-0 --replSet rs0 --logpath logs/rs0-0.log --fork
```

**Secondary Node 1 (Port 27018):**
```bash
mongod --port 27018 --dbpath data/rs0-1 --replSet rs0 --logpath logs/rs0-1.log --fork
```

**Secondary Node 2 (Port 27019):**
```bash
mongod --port 27019 --dbpath data/rs0-2 --replSet rs0 --logpath logs/rs0-2.log --fork
```

### Bước 3: Khởi tạo Replica Set

Kết nối tới primary node:
```bash
mongosh --port 27017
```

Khởi tạo replica set:
```javascript
rs.initiate({
    _id: "rs0",
    members: [
        { _id: 0, host: "localhost:27017" },
        { _id: 1, host: "localhost:27018" },
        { _id: 2, host: "localhost:27019" }
    ]
})
```

### Bước 4: Kiểm tra trạng thái

```javascript
// Kiểm tra cấu hình replica set
rs.conf()

// Kiểm tra trạng thái
rs.status()

// Kiểm tra node nào là primary
rs.isMaster()
```

### Bước 5: Test Replication

**Trên Primary node:**
```javascript
use testdb
db.users.insertOne({name: "John", age: 30})
db.users.insertMany([
    {name: "Alice", age: 25},
    {name: "Bob", age: 35}
])
```

**Kết nối tới Secondary node:**
```bash
mongosh --port 27018
```

**Trên Secondary node:**
```javascript
// Cho phép đọc trên secondary
rs.slaveOk()
// Hoặc với MongoDB 5.0+
db.getMongo().setReadPref('secondary')

use testdb
db.users.find()
```

### Bước 6: Test Failover

1. Tắt primary node:
```bash
# Tìm process ID của mongod port 27017
ps aux | grep mongod
kill <PID_của_port_27017>
```

2. Kiểm tra election trên node còn lại:
```javascript
rs.status()
```

3. Một secondary node sẽ được bầu làm primary mới

## Các lệnh quan trọng

```javascript
// Thêm member mới
rs.add("localhost:27020")

// Xóa member
rs.remove("localhost:27020")

// Xem log oplog
db.oplog.rs.find().limit(5).sort({$natural: -1})

// Cấu hình read preference
db.getMongo().setReadPref('secondary')
db.getMongo().setReadPref('primary')
db.getMongo().setReadPref('primaryPreferred')
```

## Lợi ích của Replication

1. **Automatic Failover**: Tự động chuyển đổi khi primary node gặp sự cố
2. **Data Redundancy**: Dữ liệu được sao lưu trên nhiều node  
3. **Read Scaling**: Phân tán read operations lên secondary nodes
4. **Backup**: Có thể backup từ secondary node mà không ảnh hưởng primary

## Lưu ý quan trọng

- Luôn sử dụng số lẻ các member (3, 5, 7...) để tránh split-brain
- Secondary nodes đồng bộ từ oplog của primary
- Write concern và read preference có thể cấu hình theo nhu cầu
- Arbiters chỉ tham gia bầu cử, không lưu trữ dữ liệu