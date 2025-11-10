#!/bin/bash

# MongoDB Health Check Script
# Kiểm tra trạng thái của tất cả MongoDB instances

echo "🏥 MongoDB Health Check"
echo "======================"

# Function to check if port is listening
check_port() {
    if lsof -i :$1 &>/dev/null; then
        echo "✅ Port $1: LISTENING"
        return 0
    else
        echo "❌ Port $1: NOT LISTENING" 
        return 1
    fi
}

# Function to test MongoDB connection
test_mongo_connection() {
    local port=$1
    local name=$2
    
    if mongosh --port $port --quiet --eval "db.runCommand('ping')" &>/dev/null; then
        echo "✅ $name (Port $port): CONNECTION OK"
        return 0
    else
        echo "❌ $name (Port $port): CONNECTION FAILED"
        return 1
    fi
}

echo ""
echo "🔌 Checking Ports..."
replication_ports=(27017 27018 27019)
sharding_ports=(27100 27101 27102 27200 27201 27300 27301 27500)

echo ""
echo "📊 Replication Ports:"
replication_running=0
for port in "${replication_ports[@]}"; do
    if check_port $port; then
        ((replication_running++))
    fi
done

echo ""
echo "🗂️ Sharding Ports:" 
sharding_running=0
for port in "${sharding_ports[@]}"; do
    if check_port $port; then
        ((sharding_running++))
    fi
done

echo ""
echo "🔗 Connection Tests..."

# Test Replication if running
if [ $replication_running -gt 0 ]; then
    echo ""
    echo "🔄 Testing Replication Cluster:"
    
    for port in "${replication_ports[@]}"; do
        if lsof -i :$port &>/dev/null; then
            test_mongo_connection $port "Replica Node"
        fi
    done
    
    # Check replica set status
    if lsof -i :27017 &>/dev/null; then
        echo ""
        echo "📋 Replica Set Status:"
        mongosh --port 27017 --quiet --eval "
        try {
            var status = rs.status();
            print('Replica Set: ' + status.set);
            status.members.forEach(function(member) {
                var health = member.health == 1 ? '✅' : '❌';
                print(health + ' ' + member.name + ': ' + member.stateStr);
            });
        } catch (e) {
            print('❌ Error getting replica status: ' + e.message);
        }
        "
    fi
fi

# Test Sharding if running
if [ $sharding_running -gt 0 ]; then
    echo ""
    echo "🗂️ Testing Sharded Cluster:"
    
    # Test mongos
    if lsof -i :27500 &>/dev/null; then
        if test_mongo_connection 27500 "Query Router (mongos)"; then
            echo ""
            echo "📊 Sharding Status:"
            mongosh --port 27500 --quiet --eval "
            try {
                print('Database admin:');
                var shards = db.adminCommand('listShards');
                shards.shards.forEach(function(shard) {
                    print('✅ Shard: ' + shard._id + ' - ' + shard.host);
                });
                
                print('\\nSharded Databases:');
                var config = db.getSiblingDB('config');
                var dbs = config.databases.find({partitioned: true});
                if (dbs.count() > 0) {
                    dbs.forEach(function(db) {
                        print('📚 ' + db._id + ': partitioned');
                    });
                } else {
                    print('ℹ️ No sharded databases found');
                }
            } catch (e) {
                print('❌ Error getting shard status: ' + e.message);
            }
            "
        fi
    fi
    
    # Test config servers
    echo ""
    echo "🔧 Config Servers:"
    for port in 27100 27101 27102; do
        if lsof -i :$port &>/dev/null; then
            test_mongo_connection $port "Config Server"
        fi
    done
    
    # Test shards
    echo ""
    echo "🗄️ Shard Servers:"
    shard_ports=(27200 27201 27300 27301)
    for port in "${shard_ports[@]}"; do
        if lsof -i :$port &>/dev/null; then
            if [ $port -lt 27300 ]; then
                test_mongo_connection $port "Shard 0"
            else
                test_mongo_connection $port "Shard 1"
            fi
        fi
    done
fi

echo ""
echo "💾 Process Information:"
echo ""
MONGO_PROCESSES=$(ps aux | grep -E "mongod|mongos" | grep -v grep)
if [ ! -z "$MONGO_PROCESSES" ]; then
    echo "📊 Running MongoDB Processes:"
    echo "$MONGO_PROCESSES" | while read line; do
        echo "   $line"
    done
else
    echo "ℹ️ No MongoDB processes running"
fi

echo ""
echo "📈 Summary:"
echo "=========="

if [ $replication_running -gt 0 ]; then
    echo "🔄 Replication: $replication_running/3 nodes running"
    if [ $replication_running -eq 3 ]; then
        echo "   Status: ✅ Full replica set active"
    else
        echo "   Status: ⚠️ Partial replica set"
    fi
fi

if [ $sharding_running -gt 0 ]; then
    echo "🗂️ Sharding: $sharding_running/8 components running"
    if [ $sharding_running -eq 8 ]; then
        echo "   Status: ✅ Full sharded cluster active"  
    else
        echo "   Status: ⚠️ Partial sharded cluster"
    fi
fi

if [ $replication_running -eq 0 ] && [ $sharding_running -eq 0 ]; then
    echo "ℹ️ No MongoDB clusters running"
    echo ""
    echo "💡 To start:"
    echo "   Replication: cd replication && ./setup-replication.sh"
    echo "   Sharding: cd sharding && ./setup-sharding.sh"
fi

echo ""
echo "🏥 Health check complete!"