#!/bin/bash

# Deploy script for Spring Boot SSO with KeyCloak on Kubernetes

set -e

echo "🚀 Deploying Spring Boot SSO Application with KeyCloak to Kubernetes..."

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl is not installed or not in PATH"
    exit 1
fi

# Check if Docker Desktop Kubernetes is running
kubectl cluster-info &> /dev/null || {
    echo "❌ Kubernetes cluster is not accessible. Make sure Docker Desktop Kubernetes is enabled."
    exit 1
}

# Create namespace if it doesn't exist
echo "📝 Creating namespace if not exists..."
kubectl create namespace default --dry-run=client -o yaml | kubectl apply -f -

# Apply ConfigMap
echo "📋 Applying ConfigMap..."
kubectl apply -f k8s/configmap.yaml

# Deploy KeyCloak
echo "🔐 Deploying KeyCloak..."
kubectl apply -f k8s/keycloak.yaml

# Wait for KeyCloak to be ready
echo "⏳ Waiting for KeyCloak to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/keycloak-deployment

# Deploy Spring Boot Application
echo "🌱 Deploying Spring Boot Application..."
kubectl apply -f k8s/spring-boot-app.yaml

# Wait for Spring Boot app to be ready
echo "⏳ Waiting for Spring Boot Application to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/demo-app-deployment

# Show deployment status
echo "📊 Deployment Status:"
kubectl get deployments
kubectl get services
kubectl get pods

echo ""
echo "✅ Deployment completed successfully!"
echo ""
echo "🌐 Access URLs:"
echo "   KeyCloak Admin Console: http://localhost:30180"
echo "   Spring Boot Application: http://localhost:30080"
echo ""
echo "🔑 KeyCloak Admin Credentials:"
echo "   Username: admin"
echo "   Password: admin"
echo ""
echo "📝 Next steps:"
echo "   1. Access KeyCloak admin console and configure the 'spring-boot-app' client"
echo "   2. Set Valid Redirect URIs to: http://localhost:30080/login/oauth2/code/keycloak"
echo "   3. Set Post Logout Redirect URIs to: http://localhost:30080/logout-success"
echo "   4. Test the Spring Boot application"