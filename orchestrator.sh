#!/bin/bash

# Orchestrator Script for K3s Microservices Cluster
# Usage: ./orchestrator.sh [create|start|stop]

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if kubectl is available
check_kubectl() {
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl is not installed or not in PATH"
        return 1
    fi
}

# Function to setup kubectl config
setup_kubectl() {
    if [ -f "./kubeconfig" ]; then
        export KUBECONFIG="./kubeconfig"
        print_status "kubectl configured to use local cluster"
    else
        print_warning "kubeconfig file not found. Cluster may not be ready."
    fi
}

# Function to create the cluster
create_cluster() {
    print_status "Creating K3s cluster..."
    
    # Start VMs
    vagrant up
    
    # Wait for kubeconfig
    local timeout=300
    local elapsed=0
    while [ ! -f "./kubeconfig" ] && [ $elapsed -lt $timeout ]; do
        print_status "Waiting for cluster to be ready... ($elapsed/$timeout seconds)"
        sleep 10
        elapsed=$((elapsed + 10))
    done
    
    if [ ! -f "./kubeconfig" ]; then
        print_error "Cluster creation failed - kubeconfig not found"
        return 1
    fi
    
    # Setup kubectl
    setup_kubectl
    check_kubectl
    
    # Wait for nodes to be ready
    print_status "Waiting for nodes to be ready..."
    kubectl wait --for=condition=Ready nodes --all --timeout=300s
    
    # Show cluster status
    print_status "Cluster created successfully!"
    echo
    kubectl get nodes -o wide
    
    print_status "Cluster is ready for deployments!"
}

# Function to start existing cluster
start_cluster() {
    print_status "Starting K3s cluster..."
    
    # Check if VMs exist
    if ! vagrant status | grep -q "running\|saved"; then
        print_warning "No existing cluster found. Use 'create' to create a new cluster."
        return 1
    fi
    
    # Start VMs
    vagrant up
    
    # Setup kubectl
    setup_kubectl
    check_kubectl
    
    # Wait for nodes to be ready
    print_status "Waiting for nodes to be ready..."
    kubectl wait --for=condition=Ready nodes --all --timeout=180s
    
    print_status "Cluster started successfully!"
    kubectl get nodes
}

# Function to stop the cluster
stop_cluster() {
    print_status "Stopping K3s cluster..."
    vagrant halt
    print_status "Cluster stopped successfully!"
}

# Function to destroy the cluster
destroy_cluster() {
    print_warning "This will completely destroy the cluster and all data!"
    read -p "Are you sure? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_status "Destroying K3s cluster..."
        vagrant destroy -f
        
        # Clean up generated files
        rm -f kubeconfig node-token
        
        print_status "Cluster destroyed successfully!"
    else
        print_status "Operation cancelled."
    fi
}

# Function to show cluster status
status_cluster() {
    print_status "Checking cluster status..."
    
    # Check Vagrant VMs
    echo "=== Vagrant VMs ==="
    vagrant status
    echo
    
    # Check kubectl connectivity
    if [ -f "./kubeconfig" ]; then
        setup_kubectl
        if check_kubectl; then
            echo "=== Kubernetes Nodes ==="
            kubectl get nodes 2>/dev/null || print_warning "Cannot connect to cluster"
            echo
            
            echo "=== Kubernetes Pods ==="
            kubectl get pods --all-namespaces 2>/dev/null || print_warning "Cannot retrieve pod information"
        fi
    else
        print_warning "kubeconfig not found - cluster may not be running"
    fi
}

# Function to deploy microservices
deploy_microservices() {
    print_status "Deploying microservices to cluster..."
    if [ ! -f "Scripts/deploy-microservices.sh" ]; then
        print_error "Deployment script not found"
        return 1
    fi
    
    # Validate manifests before deployment
    print_status "Validating Kubernetes manifests..."
    for manifest in Manifests/*/*.yaml; do
        if ! kubectl apply --dry-run=client -f "$manifest" > /dev/null 2>&1; then
            print_warning "Manifest validation warning: $manifest"
        fi
    done
    
    Scripts/deploy-microservices.sh
}

# Function to cleanup microservices
cleanup_microservices() {
    print_status "Cleaning up microservices from cluster..."
    if [ ! -f "Scripts/cleanup-microservices.sh" ]; then
        print_error "Cleanup script not found"
        return 1
    fi
    Scripts/cleanup-microservices.sh
}

# Function to show usage
show_usage() {
    echo "Orchestrator Script for K3s Microservices Cluster"
    echo
    echo "Usage: $0 [COMMAND]"
    echo
    echo "Commands:"
    echo "  create    Create and start a new K3s cluster"
    echo "  start     Start an existing K3s cluster" 
    echo "  stop      Stop the running K3s cluster"
    echo "  destroy   Destroy the cluster completely"
    echo "  deploy    Deploy microservices to the cluster"
    echo "  cleanup   Remove microservices from the cluster"
    echo "  status    Show cluster status"
    echo "  help      Show this help message"
    echo
}

# Main script logic
case "${1:-help}" in
    create)
        create_cluster
        ;;
    start)
        start_cluster
        ;;
    stop)
        stop_cluster
        ;;
    destroy)
        destroy_cluster
        ;;
    deploy)
        deploy_microservices
        ;;
    cleanup)
        cleanup_microservices
        ;;
    status)
        status_cluster
        ;;
    help|--help|-h)
        show_usage
        ;;
    *)
        print_error "Unknown command: $1"
        echo
        show_usage
        exit 1
        ;;
esac
