# Makefile for Kafka Spring Boot Demo

.PHONY: help setup start-cluster start-producer start-consumer stop-cluster clean demo check-leaders test-failover

# Default target
help:
	@echo "Available commands:"
	@echo "  make setup         - Setup and start Kafka cluster"
	@echo "  make start-cluster - Start Kafka cluster only"
	@echo "  make start-producer- Start Producer Spring Boot app"
	@echo "  make start-consumer- Start Consumer Spring Boot app"
	@echo "  make stop-cluster  - Stop Kafka cluster"
	@echo "  make clean         - Clean all containers and volumes"
	@echo "  make demo          - Run complete demo"
	@echo "  make check-leaders - Check partition leaders"
	@echo "  make test-failover - Test failover scenario"
	@echo "  make status        - Show system status"

# Setup và start cluster
setup:
	@echo "Setting up Kafka cluster..."
	cd kafka-cluster && ./setup-cluster.sh

# Start cluster only
start-cluster:
	@echo "Starting Kafka cluster..."
	cd kafka-cluster && docker-compose up -d

# Start producer app
start-producer:
	@echo "Starting Producer app..."
	cd kafka-producer && mvn spring-boot:run

# Start consumer app  
start-consumer:
	@echo "Starting Consumer app..."
	cd kafka-consumer && mvn spring-boot:run

# Stop cluster
stop-cluster:
	@echo "Stopping Kafka cluster..."
	cd kafka-cluster && docker-compose down

# Clean everything
clean:
	@echo "Cleaning all containers and volumes..."
	cd kafka-cluster && docker-compose down -v
	docker system prune -f
	docker volume prune -f

# Run demo
demo:
	@echo "Running complete demo..."
	cd kafka-cluster && ./demo.sh

# Check leaders
check-leaders:
	@echo "Checking partition leaders..."
	cd kafka-cluster && ./check-leader.sh

# Test failover
test-failover:
	@echo "Testing failover scenario..."
	cd kafka-cluster && ./test-failover.sh

# Show status
status:
	@echo "=== System Status ==="
	@echo "Kafka Cluster:"
	cd kafka-cluster && docker-compose ps
	@echo ""
	@echo "Producer (port 8081):"
	@curl -s http://localhost:8081/api/producer/health 2>/dev/null | grep -o '"status":"[^"]*"' || echo "Not running"
	@echo ""
	@echo "Consumer (port 8082):"
	@curl -s http://localhost:8082/api/consumer/health 2>/dev/null | grep -o '"status":"[^"]*"' || echo "Not running"

# Quick test
test:
	@echo "Running quick test..."
	@echo "Sending test message..."
	@curl -s -X POST http://localhost:8081/api/producer/send \
		-H "Content-Type: application/json" \
		-d '{"title":"Quick Test","content":"Test from Makefile","sender":"Makefile","priority":"HIGH"}' \
		&& echo "✓ Message sent successfully" || echo "✗ Failed to send message"
	@sleep 2
	@echo "Checking processed messages:"
	@curl -s http://localhost:8082/api/consumer/stats | grep -o '"totalProcessedMessages":[0-9]*' | cut -d':' -f2 | sed 's/^/Total processed: /' || echo "Cannot get stats"