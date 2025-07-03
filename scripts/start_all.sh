#!/bin/bash

# Master Startup Script for CRUD Master Project
# Starts all microservices in the correct order

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

# Function to show usage
show_usage() {
    echo "CRUD Master - Microservices Startup Script"
    echo ""
    echo "Usage: $0 [OPTION]"
    echo ""
    echo "Options:"
    echo "  --setup-only      Only setup databases and dependencies"
    echo "  --start-services  Only start the services (assumes setup is done)"
    echo "  --full           Setup databases and start all services (default)"
    echo "  --help           Show this help message"
    echo ""
    echo "Individual service scripts:"
    echo "  ./start_inventory.sh  - Start inventory service only"
    echo "  ./start_billing.sh    - Start billing service only (with RabbitMQ)"
    echo "  ./start_gateway.sh    - Start API gateway only"
    echo ""
    echo "Services will be available at:"
    echo "  API Gateway:      http://localhost:5000"
    echo "  Inventory API:    http://localhost:8080"
    echo "  Billing API:      http://localhost:8081"
    echo "  RabbitMQ UI:      http://localhost:15672 (guest/guest)"
}

# Function to setup databases
setup_databases() {
    log_header "Setting up databases..."
    
    if [ -f "./setup_database.sh" ]; then
        ./setup_database.sh --full
        log_success "Database setup completed"
    else
        log_error "Database setup script not found: ./setup_database.sh"
        exit 1
    fi
}

# Function to check prerequisites
check_prerequisites() {
    log_header "Checking prerequisites..."
    
    # Check Python
    if ! command -v python3 &> /dev/null; then
        log_error "Python 3 is not installed"
        exit 1
    fi
    log_success "Python 3 is available"
    
    # Check Docker (only if starting billing service)
    if ! command -v docker &> /dev/null; then
        log_warning "Docker is not installed - billing service will not work"
    else
        if ! docker info &> /dev/null; then
            log_warning "Docker daemon is not running - billing service will not work"
        else
            log_success "Docker is available and running"
        fi
    fi
    
    # Check PostgreSQL
    if command -v pg_isready &> /dev/null; then
        if pg_isready -h localhost -p 5434 -U postgres &> /dev/null; then
            log_success "PostgreSQL is running and accessible"
        else
            log_error "PostgreSQL is not accessible on localhost:5434"
            exit 1
        fi
    else
        log_warning "pg_isready not found - cannot verify PostgreSQL status"
    fi
}

# Function to start services in background
start_services() {
    log_header "Starting microservices..."
    
    # Create logs directory
    mkdir -p logs
    
    log_info "Starting Inventory Service..."
    if [ -f "./start_inventory.sh" ]; then
        nohup ./start_inventory.sh > logs/inventory.log 2>&1 &
        INVENTORY_PID=$!
        echo $INVENTORY_PID > logs/inventory.pid
        log_success "Inventory service started (PID: $INVENTORY_PID)"
    else
        log_error "Inventory startup script not found"
        exit 1
    fi
    
    # Wait a bit for inventory to start
    sleep 3
    
    log_info "Starting Billing Service..."
    if [ -f "./start_billing.sh" ]; then
        nohup ./start_billing.sh > logs/billing.log 2>&1 &
        BILLING_PID=$!
        echo $BILLING_PID > logs/billing.pid
        log_success "Billing service started (PID: $BILLING_PID)"
    else
        log_error "Billing startup script not found"
        exit 1
    fi
    
    # Wait a bit for billing to start
    sleep 5
    
    log_info "Starting API Gateway..."
    if [ -f "./start_gateway.sh" ]; then
        nohup ./start_gateway.sh > logs/gateway.log 2>&1 &
        GATEWAY_PID=$!
        echo $GATEWAY_PID > logs/gateway.pid
        log_success "API Gateway started (PID: $GATEWAY_PID)"
    else
        log_error "Gateway startup script not found"
        exit 1
    fi
    
    # Wait for services to fully start
    log_info "Waiting for services to fully initialize..."
    sleep 10
}

# Function to check service health
check_services() {
    log_header "Checking service health..."
    
    # Check Inventory API
    if curl -s http://localhost:8080/api/movies > /dev/null 2>&1; then
        log_success "✓ Inventory API is responding"
    else
        log_warning "✗ Inventory API is not responding"
    fi
    
    # Check Billing API
    if curl -s http://localhost:8081 > /dev/null 2>&1; then
        log_success "✓ Billing API is responding"
    else
        log_warning "✗ Billing API is not responding"
    fi
    
    # Check API Gateway
    if curl -s http://localhost:5000 > /dev/null 2>&1; then
        log_success "✓ API Gateway is responding"
    else
        log_warning "✗ API Gateway is not responding"
    fi
    
    # Check RabbitMQ
    if curl -s http://localhost:15672 > /dev/null 2>&1; then
        log_success "✓ RabbitMQ Management UI is accessible"
    else
        log_warning "✗ RabbitMQ Management UI is not accessible"
    fi
}

# Function to show service information
show_service_info() {
    log_header "Service Information"
    echo ""
    echo -e "${GREEN}Services are running!${NC}"
    echo ""
    echo "API Endpoints:"
    echo "  🚪 API Gateway:      http://localhost:5000"
    echo "  📦 Inventory API:    http://localhost:8080"
    echo "  💰 Billing API:      http://localhost:8081"
    echo "  🐰 RabbitMQ UI:      http://localhost:15672 (guest/guest)"
    echo ""
    echo "Example API Calls:"
    echo "  curl http://localhost:5000/api/movies"
    echo "  curl -X POST http://localhost:5000/api/movies -H 'Content-Type: application/json' -d '{\"title\":\"Test Movie\"}'"
    echo "  curl -X POST http://localhost:5000/api/billing -H 'Content-Type: application/json' -d '{\"user_id\":\"1\",\"number_of_items\":\"2\",\"total_amount\":\"50\"}'"
    echo ""
    echo "Log files:"
    echo "  📝 Inventory: logs/inventory.log"
    echo "  📝 Billing:   logs/billing.log"
    echo "  📝 Gateway:   logs/gateway.log"
    echo ""
    echo -e "${YELLOW}To stop all services, run: ./stop_all.sh${NC}"
    echo -e "${YELLOW}To view logs: tail -f logs/*.log${NC}"
}

# Function to cleanup on exit
cleanup() {
    log_warning "Shutting down services..."
    
    if [ -f "logs/gateway.pid" ]; then
        kill $(cat logs/gateway.pid) 2>/dev/null || true
        rm -f logs/gateway.pid
    fi
    
    if [ -f "logs/billing.pid" ]; then
        kill $(cat logs/billing.pid) 2>/dev/null || true
        rm -f logs/billing.pid
    fi
    
    if [ -f "logs/inventory.pid" ]; then
        kill $(cat logs/inventory.pid) 2>/dev/null || true
        rm -f logs/inventory.pid
    fi
    
    log_info "Services stopped"
}

# Set trap for cleanup
trap cleanup EXIT

# Main execution
main() {
    local action=${1:-"--full"}
    
    case $action in
        --help)
            show_usage
            exit 0
            ;;
        --setup-only)
            log_header "CRUD Master - Database Setup Only"
            check_prerequisites
            setup_databases
            log_success "Setup completed! Run with --start-services to start the applications"
            ;;
        --start-services)
            log_header "CRUD Master - Starting Services Only"
            check_prerequisites
            start_services
            check_services
            show_service_info
            
            # Keep the script running
            log_info "Press Ctrl+C to stop all services"
            while true; do
                sleep 10
            done
            ;;
        --full)
            log_header "CRUD Master - Full Setup and Start"
            check_prerequisites
            setup_databases
            start_services
            check_services
            show_service_info
            
            # Keep the script running
            log_info "Press Ctrl+C to stop all services"
            while true; do
                sleep 10
            done
            ;;
        *)
            log_error "Unknown option: $action"
            show_usage
            exit 1
            ;;
    esac
}

# Execute main function with all arguments
main "$@"
