#!/bin/bash

# Cleanup Microservices from Kubernetes Script
# This script removes all microservices from the K3s cluster

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
    echo -e "${BLUE}[CLEANUP]${NC} $1"
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

print_header "Cleaning up Microservices from Kubernetes"

print_warning "This will remove all microservices deployments, services, and data!"
read -p "Are you sure you want to continue? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_status "Operation cancelled."
    exit 0
fi

# Remove ingress
print_status "Removing ingress..."
kubectl delete -f Manifests/ingress/ --ignore-not-found=true

# Remove applications
print_status "Removing applications..."
kubectl delete -f Manifests/applications/ --ignore-not-found=true

# Remove databases
print_status "Removing databases..."
kubectl delete -f Manifests/databases/ --ignore-not-found=true

# Remove secrets
print_status "Removing secrets..."
kubectl delete -f Manifests/secrets/ --ignore-not-found=true

# Remove namespace (this will clean up any remaining resources)
print_status "Removing namespace..."
kubectl delete -f Manifests/namespaces/ --ignore-not-found=true

# Wait for namespace deletion
print_status "Waiting for namespace deletion to complete..."
kubectl wait --for=delete namespace/microservices --timeout=120s 2>/dev/null || true

print_status "Cleanup completed successfully!"

echo
print_header "Remaining Resources"
echo "=== Pods ==="
kubectl get pods --all-namespaces | grep microservices || echo "No microservices pods found"

echo
echo "=== PVCs ==="
kubectl get pvc --all-namespaces | grep microservices || echo "No microservices PVCs found"
