#!/bin/bash

# Billing App Startup Script
# Sets up RabbitMQ, virtual environment, and starts the billing microservice

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

# Configuration
APP_DIR="../srcs/billing-app"
VENV_DIR="$APP_DIR/venv"
REQUIREMENTS_FILE="$APP_DIR/requirements.txt"
RUN_FILE="$APP_DIR/run.py"
RABBITMQ_CONTAINER="rabbitmq"

log_info "Starting Billing App setup and launch..."

# Function to check if Docker is running
check_docker() {
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed or not in PATH"
        exit 1
    fi
    
    if ! docker info &> /dev/null; then
        log_error "Docker daemon is not running"
        exit 1
    fi
    
    log_success "Docker is available and running"
}

# Function to setup RabbitMQ
setup_rabbitmq() {
    log_info "Setting up RabbitMQ..."
    
    # Check if RabbitMQ container already exists
    if docker ps -a --format "table {{.Names}}" | grep -q "^${RABBITMQ_CONTAINER}$"; then
        log_warning "RabbitMQ container already exists"
        
        # Check if it's running
        if docker ps --format "table {{.Names}}" | grep -q "^${RABBITMQ_CONTAINER}$"; then
            log_info "RabbitMQ container is already running"
        else
            log_info "Starting existing RabbitMQ container..."
            docker start $RABBITMQ_CONTAINER
            log_success "RabbitMQ container started"
        fi
    else
        log_info "Creating and starting new RabbitMQ container..."
        docker run -d --name $RABBITMQ_CONTAINER -p 5672:5672 -p 15672:15672 rabbitmq:3-management
        log_success "RabbitMQ container created and started"
    fi
    
    # Wait for RabbitMQ to be ready
    log_info "Waiting for RabbitMQ to be ready..."
    sleep 5
    
    # Check if RabbitMQ is accessible
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if docker exec $RABBITMQ_CONTAINER rabbitmqctl status &> /dev/null; then
            log_success "RabbitMQ is ready"
            break
        else
            log_info "Waiting for RabbitMQ... (attempt $attempt/$max_attempts)"
            sleep 2
            ((attempt++))
        fi
    done
    
    if [ $attempt -gt $max_attempts ]; then
        log_error "RabbitMQ failed to start properly"
        exit 1
    fi
    
    log_success "RabbitMQ is running and accessible"
    log_info "RabbitMQ Management UI: http://localhost:15672 (guest/guest)"
}

# Function to setup Python environment
setup_python_env() {
    log_info "Setting up Python environment..."
    
    # Check if app directory exists
    if [ ! -d "$APP_DIR" ]; then
        log_error "Billing app directory not found: $APP_DIR"
        exit 1
    fi
    
    # Change to app directory
    cd "$APP_DIR"
    log_info "Changed to directory: $(pwd)"
    
    # Check if virtual environment already exists
    if [ -d "venv" ]; then
        log_warning "Virtual environment already exists"
    else
        log_info "Creating Python virtual environment..."
        python3 -m venv venv
        log_success "Virtual environment created"
    fi
    
    # Activate virtual environment
    log_info "Activating virtual environment..."
    source venv/bin/activate
    log_success "Virtual environment activated"
    
    # Check if requirements file exists
    if [ ! -f "requirements.txt" ]; then
        log_error "Requirements file not found: requirements.txt"
        exit 1
    fi
    
    # Install requirements
    log_info "Installing Python dependencies..."
    pip install -r requirements.txt
    log_success "Dependencies installed"
    
    # Check if run.py exists
    if [ ! -f "run.py" ]; then
        log_error "Application entry point not found: run.py"
        exit 1
    fi
    
    # Check if .env file exists
    if [ -f ".env" ]; then
        log_info "Found .env file, environment variables will be loaded"
    else
        log_warning "No .env file found, using default configuration"
    fi
}

# Function to start the application
start_application() {
    log_success "Starting Billing App..."
    log_info "Application will be available at: http://localhost:8081"
    log_info "RabbitMQ Management UI: http://localhost:15672"
    log_info "Press Ctrl+C to stop the application"
    echo ""
    
    python run.py
}

# Function to cleanup on exit
cleanup() {
    log_warning "Shutting down..."
    # Note: We don't stop RabbitMQ container as it might be used by other services
    # Users can manually stop it with: docker stop rabbitmq
}

# Set trap for cleanup
trap cleanup EXIT

# Main execution
main() {
    check_docker
    setup_rabbitmq
    setup_python_env
    start_application
}

# Execute main function
main "$@"
