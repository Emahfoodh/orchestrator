#!/bin/bash

# Deploy Microservices to Kubernetes Script
# This script deploys all microservices manifests to the K3s cluster

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}[DEPLOY]${NC} $1"
}

# Check if kubectl is available and configured
if ! command -v kubectl &> /dev/null; then
    print_error "kubectl is not installed or not in PATH"
    exit 1
fi

# Setup kubectl config
if [ -f "./kubeconfig" ]; then
    export KUBECONFIG="./kubeconfig"
    print_status "kubectl configured to use local cluster"
else
    print_error "kubeconfig file not found. Make sure the cluster is running."
    exit 1
fi

# Check if cluster is ready
if ! kubectl get nodes &> /dev/null; then
    print_error "Cannot connect to Kubernetes cluster. Make sure it's running."
    exit 1
fi

print_header "Deploying Microservices to Kubernetes"

# Deploy namespace
print_status "Creating namespace..."
kubectl apply -f Manifests/namespaces/

# Deploy secrets
print_status "Creating secrets..."
kubectl apply -f Manifests/secrets/

# Deploy databases (StatefulSets)
print_status "Deploying databases..."
kubectl apply -f Manifests/databases/

# Wait for databases to be ready
print_status "Waiting for databases to be ready..."
kubectl wait --for=condition=ready pod -l app=inventory-db -n microservices --timeout=300s
kubectl wait --for=condition=ready pod -l app=billing-db -n microservices --timeout=300s
kubectl wait --for=condition=ready pod -l app=rabbitmq -n microservices --timeout=300s

# Deploy applications
print_status "Deploying applications..."
kubectl apply -f Manifests/applications/

# Deploy ingress
print_status "Deploying ingress..."
kubectl apply -f Manifests/ingress/

# Wait for applications to be ready
print_status "Waiting for applications to be ready..."
kubectl wait --for=condition=ready pod -l app=inventory-app -n microservices --timeout=300s
kubectl wait --for=condition=ready pod -l app=billing-app -n microservices --timeout=300s
kubectl wait --for=condition=ready pod -l app=api-gateway -n microservices --timeout=300s

print_status "Deployment completed successfully!"

# Show status
print_header "Cluster Status"
echo
echo "=== Nodes ==="
kubectl get nodes

echo
echo "=== Pods ==="
kubectl get pods -n microservices

echo
echo "=== Services ==="
kubectl get services -n microservices

echo
echo "=== Ingress ==="
kubectl get ingress -n microservices

echo
echo "=== Horizontal Pod Autoscalers ==="
kubectl get hpa -n microservices

print_status "API Gateway is accessible at:"
echo "  - NodePort: http://<node-ip>:30000"
echo "  - Ingress: http://api-gateway.local (add to /etc/hosts)"

echo
print_status "RabbitMQ Management is accessible via port-forward:"
echo "  kubectl port-forward -n microservices svc/rabbitmq 15672:15672"
echo "  Then access: http://localhost:15672 (guest/guest)"
