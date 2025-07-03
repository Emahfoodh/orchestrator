#!/bin/bash

# Stop All Services Script for CRUD Master Project
# Stops all running microservices and cleans up

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Logging functions
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

log_header() {
    echo -e "${CYAN}[CRUD MASTER]${NC} $1"
}

# Function to stop service by PID file
stop_service() {
    local service_name=$1
    local pid_file="logs/${service_name}.pid"
    
    if [ -f "$pid_file" ]; then
        local pid=$(cat "$pid_file")
        if ps -p $pid > /dev/null 2>&1; then
            log_info "Stopping $service_name (PID: $pid)..."
            kill $pid 2>/dev/null || true
            
            # Wait for process to stop
            local count=0
            while ps -p $pid > /dev/null 2>&1 && [ $count -lt 10 ]; do
                sleep 1
                ((count++))
            done
            
            if ps -p $pid > /dev/null 2>&1; then
                log_warning "Force killing $service_name..."
                kill -9 $pid 2>/dev/null || true
            fi
            
            log_success "$service_name stopped"
        else
            log_warning "$service_name was not running"
        fi
        rm -f "$pid_file"
    else
        log_warning "No PID file found for $service_name"
    fi
}

# Function to stop processes by port
stop_by_port() {
    local port=$1
    local service_name=$2
    
    local pids=$(lsof -ti:$port 2>/dev/null || true)
    if [ -n "$pids" ]; then
        log_info "Stopping $service_name on port $port..."
        echo $pids | xargs kill 2>/dev/null || true
        sleep 2
        
        # Force kill if still running
        local remaining_pids=$(lsof -ti:$port 2>/dev/null || true)
        if [ -n "$remaining_pids" ]; then
            log_warning "Force killing $service_name..."
            echo $remaining_pids | xargs kill -9 2>/dev/null || true
        fi
        log_success "$service_name stopped"
    else
        log_info "No processes found on port $port"
    fi
}

# Function to stop RabbitMQ container
stop_rabbitmq() {
    log_info "Checking RabbitMQ container..."
    
    if command -v docker &> /dev/null; then
        if docker ps --format "table {{.Names}}" | grep -q "^rabbitmq$"; then
            log_info "Stopping RabbitMQ container..."
            docker stop rabbitmq
            log_success "RabbitMQ container stopped"
        else
            log_info "RabbitMQ container is not running"
        fi
    else
        log_warning "Docker not available - cannot check RabbitMQ"
    fi
}

# Function to show usage
show_usage() {
    echo "CRUD Master - Stop All Services Script"
    echo ""
    echo "Usage: $0 [OPTION]"
    echo ""
    echo "Options:"
    echo "  --services-only   Stop only the microservices (keep RabbitMQ running)"
    echo "  --rabbitmq-only   Stop only RabbitMQ container"
    echo "  --all            Stop all services and RabbitMQ (default)"
    echo "  --help           Show this help message"
}

# Function to clean up logs
cleanup_logs() {
    if [ -d "logs" ]; then
        log_info "Cleaning up old log files..."
        rm -f logs/*.pid
        # Keep log files but rotate them
        for log_file in logs/*.log; do
            if [ -f "$log_file" ]; then
                mv "$log_file" "${log_file}.old" 2>/dev/null || true
            fi
        done
        log_success "Log cleanup completed"
    fi
}

# Main execution
main() {
    local action=${1:-"--all"}
    
    case $action in
        --help)
            show_usage
            exit 0
            ;;
        --services-only)
            log_header "Stopping microservices only..."
            
            # Stop by PID files first
            stop_service "gateway"
            stop_service "billing"
            stop_service "inventory"
            
            # Stop by ports as backup
            stop_by_port 5000 "API Gateway"
            stop_by_port 8080 "Inventory Service"
            stop_by_port 8081 "Billing Service"
            
            cleanup_logs
            log_success "All microservices stopped (RabbitMQ left running)"
            ;;
        --rabbitmq-only)
            log_header "Stopping RabbitMQ only..."
            stop_rabbitmq
            log_success "RabbitMQ stopped"
            ;;
        --all)
            log_header "Stopping all services..."
            
            # Stop microservices
            stop_service "gateway"
            stop_service "billing"
