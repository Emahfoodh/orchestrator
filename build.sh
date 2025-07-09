#!/bin/bash

# Fresh Start Script
# This script cleans up existing containers and starts fresh

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to clean up existing containers
cleanup_containers() {
    log_info "Cleaning up existing containers..."
    
    # Stop and remove existing containers
    local containers=(
        "inventory-db"
        "billing-db"
        "rabbit-queue"
        "inventory-app"
        "billing-app"
        "api-gateway-app"
    )
    
    for container in "${containers[@]}"; do
        if docker ps -a --format "table {{.Names}}" | grep -q "^${container}$"; then
            log_info "Stopping and removing container: $container"
            docker stop $container &>/dev/null || true
            docker rm $container &>/dev/null || true
        fi
    done
    
    log_success "Container cleanup completed"
}

# Function to clean up existing images
cleanup_images() {
    log_info "Cleaning up existing images..."
    
    local images=(
        "inventory-app"
        "billing-app"
        "api-gateway-app"
    )
    
    for image in "${images[@]}"; do
        if docker images --format "table {{.Repository}}" | grep -q "^${image}$"; then
            log_info "Removing image: $image"
            docker rmi $image &>/dev/null || true
        fi
    done
    
    log_success "Image cleanup completed"
}

# Function to clean up networks
cleanup_networks() {
    log_info "Cleaning up networks..."
    
    local network="microservices-network"
    if docker network ls --format "table {{.Name}}" | grep -q "^${network}$"; then
        log_info "Removing network: $network"
        docker network rm $network &>/dev/null || true
    fi
    
    log_success "Network cleanup completed"
}

# Function to start fresh
start_fresh() {
    log_info "Starting fresh deployment..."
    
    # Use the simple docker-compose file
    log_info "Starting services with docker-compose..."
    docker-compose -f docker-compose.yml up --build -d
    
    log_success "Services started successfully"
}

# Function to verify deployment
verify_deployment() {
    log_info "Verifying deployment..."
    
    # Wait a bit for services to initialize
    sleep 10
    
    # Check container status
    log_info "Container status:"
    docker-compose ps
    
    # Check if API gateway is responding
    log_info "Testing API Gateway..."
    if curl -s -f http://localhost:3000/health &>/dev/null; then
        log_success "API Gateway is responding at http://localhost:3000"
    else
        log_warning "API Gateway is not responding yet. You may need to wait a bit longer."
    fi
    
    # Show logs for debugging
    log_info "Recent logs (last 20 lines per service):"
    for service in inventory-app billing-app api-gateway-app; do
        echo "=== $service logs ==="
        docker-compose logs --tail=20 $service
        echo ""
    done
}

# Main function
main() {
    log_info "Starting fresh deployment process..."
    
    # Clean up existing resources
    cleanup_containers
    cleanup_images
    cleanup_networks
    
    # Start fresh
    start_fresh
    
    # Verify deployment
    verify_deployment
    
    log_success "Fresh deployment completed!"
    log_info "API Gateway should be available at: http://localhost:3000"
    log_info "Use 'docker-compose logs -f <service>' to view real-time logs"
    log_info "Use 'docker-compose down' to stop all services"
}

# Run main function
main