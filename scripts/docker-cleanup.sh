#!/bin/bash

# Complete Docker Cleanup Script for CRUD Master Project
# This script removes everything created by docker-compose

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

# Function to confirm deletion
confirm_deletion() {
    echo -e "${YELLOW}⚠️  WARNING: This will completely remove all Docker resources created by this project!${NC}"
    echo -e "${YELLOW}   This includes:${NC}"
    echo -e "${YELLOW}   - All containers (inventory-app, billing-app, api-gateway-app, databases, rabbitmq)${NC}"
    echo -e "${YELLOW}   - All volumes (database data will be lost!)${NC}"
    echo -e "${YELLOW}   - All custom images${NC}"
    echo -e "${YELLOW}   - Custom network${NC}"
    echo ""
    read -p "Are you sure you want to continue? (yes/no): " -r
    if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
        log_info "Cleanup cancelled."
        exit 0
    fi
}

# Function to stop and remove containers
cleanup_containers() {
    log_info "Stopping and removing containers..."
    
    # Use docker-compose to stop and remove containers
    if [ -f "docker-compose.yml" ]; then
        docker-compose down --remove-orphans || true
        log_success "Docker Compose containers stopped and removed"
    else
        log_warning "docker-compose.yml not found, attempting manual cleanup"
    fi
    
    # Manually remove containers if they still exist
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
            log_info "Removing container: $container"
            docker rm -f $container &>/dev/null || true
        fi
    done
    
    log_success "Container cleanup completed"
}

# Function to remove volumes
cleanup_volumes() {
    log_info "Removing volumes..."
    
    local volumes=(
        "play-with-containers-github_inventory-db-volume"
        "play-with-containers-github_billing-db-volume"
        "play-with-containers-github_api-gateway-volume"
    )
    
    for volume in "${volumes[@]}"; do
        if docker volume ls --format "table {{.Name}}" | grep -q "^${volume}$"; then
            log_info "Removing volume: $volume"
            docker volume rm $volume &>/dev/null || true
        fi
    done
    
    log_success "Volume cleanup completed"
}

# Function to remove images
cleanup_images() {
    log_info "Removing images..."
    
    local custom_images=(
        "inventory-app"
        "billing-app"
        "api-gateway-app"
    )
    
    for image in "${custom_images[@]}"; do
        if docker images --format "table {{.Repository}}" | grep -q "^${image}$"; then
            log_info "Removing image: $image"
            docker rmi $image &>/dev/null || true
        fi
    done
    
    # Ask about removing pulled images
    echo ""
    read -p "Do you want to remove pulled images (postgres, rabbitmq)? (yes/no): " -r
    if [[ $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
        local pulled_images=(
            "postgres:13-alpine"
            "rabbitmq:3-management-alpine"
        )
        
        for image in "${pulled_images[@]}"; do
            if docker images --format "table {{.Repository}}:{{.Tag}}" | grep -q "^${image}$"; then
                log_info "Removing image: $image"
                docker rmi $image &>/dev/null || true
            fi
        done
    fi
    
    log_success "Image cleanup completed"
}

# Function to remove networks
cleanup_networks() {
    log_info "Removing networks..."
    
    local networks=(
        "play-with-containers-github_microservices-network"
    )
    
    for network in "${networks[@]}"; do
        if docker network ls --format "table {{.Name}}" | grep -q "^${network}$"; then
            log_info "Removing network: $network"
            docker network rm $network &>/dev/null || true
        fi
    done
    
    log_success "Network cleanup completed"
}

# Function to show final status
show_final_status() {
    log_info "Checking remaining resources..."
    
    echo ""
    echo "=== Remaining Docker Resources ==="
    
    echo ""
    echo "Containers:"
    docker ps -a --format "table {{.Names}}\t{{.Status}}" | head -10
    
    echo ""
    echo "Images:"
    docker images --format "table {{.Repository}}:{{.Tag}}\t{{.Size}}" | head -10
    
    echo ""
    echo "Volumes:"
    docker volume ls --format "table {{.Name}}\t{{.Driver}}" | head -10
    
    echo ""
    echo "Networks:"
    docker network ls --format "table {{.Name}}\t{{.Driver}}" | head -10
}

# Function to clean up build cache (optional)
cleanup_build_cache() {
    echo ""
    read -p "Do you want to clean up Docker build cache? (yes/no): " -r
    if [[ $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
        log_info "Cleaning Docker build cache..."
        docker builder prune -f || true
        log_success "Build cache cleaned"
    fi
}

# Main function
main() {
    echo -e "${BLUE}🐳 Docker Complete Cleanup Script${NC}"
    echo -e "${BLUE}===================================${NC}"
    echo ""
    
    # Check if Docker is running
    if ! docker info &> /dev/null; then
        log_error "Docker is not running. Please start Docker first."
        exit 1
    fi
    
    # Confirm deletion
    confirm_deletion
    
    echo ""
    log_info "Starting cleanup process..."
    
    # Perform cleanup
    cleanup_containers
    cleanup_volumes
    cleanup_images
    cleanup_networks
    cleanup_build_cache
    
    echo ""
    show_final_status
    
    echo ""
    log_success "🎉 Cleanup completed successfully!"
    log_info "All Docker resources created by this project have been removed."
    
    # Show disk space freed
    log_info "You can run 'docker system df' to see current Docker disk usage."
}

# Run main function
main "$@"