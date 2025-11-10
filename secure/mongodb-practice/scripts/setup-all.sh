#!/bin/bash

# Master Setup Script
# Khởi tạo cả Replication và Sharding environments

echo "🚀 MongoDB Replication & Sharding - Master Setup"
echo "================================================="

# Kiểm tra MongoDB có được cài đặt không
if ! command -v mongod &> /dev/null; then
    echo "❌ MongoDB chưa được cài đặt."
    echo ""
    echo "📥 Cài đặt MongoDB:"
    echo "   macOS: brew install mongodb/brew/mongodb-community"
    echo "   Ubuntu: sudo apt install mongodb"
    echo ""
    exit 1
fi

echo ""
echo "🔍 Phát hiện MongoDB version:"
mongod --version | head -1

echo ""
echo "📋 Chọn setup option:"
echo "   1) Chỉ setup Replication"
echo "   2) Chỉ setup Sharding"  
echo "   3) Setup cả hai (sequential)"
echo "   4) Hủy"

read -p "Lựa chọn của bạn (1-4): " choice

case $choice in
    1)
        echo ""
        echo "🔄 Setting up MongoDB Replication..."
        cd replication
        ./setup-replication.sh
        ;;
    2)
        echo ""  
        echo "🗂️ Setting up MongoDB Sharding..."
        cd sharding
        ./setup-sharding.sh
        ;;
    3)
        echo ""
        echo "🔄 Setting up MongoDB Replication first..."
        cd replication
        ./setup-replication.sh
        
        echo ""
        echo "⏳ Đợi 10 giây trước khi setup Sharding..."
        sleep 10
        
        echo ""
        echo "🗂️ Now setting up MongoDB Sharding..."
        cd ../sharding
        ./setup-sharding.sh
        ;;
    4)
        echo "Hủy setup."
        exit 0
        ;;
    *)
        echo "❌ Lựa chọn không hợp lệ."
        exit 1
        ;;
esac

echo ""
echo "✅ Setup hoàn tất!"
echo ""
echo "📖 Đọc thêm hướng dẫn:"
echo "   - Replication: ./replication/README.md"
echo "   - Sharding: ./sharding/README.md"