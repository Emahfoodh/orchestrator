#!/bin/bash

# Inventory App Startup Script
# Sets up virtual environment and starts the inventory microservice

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
APP_DIR="../srcs/inventory-app"
VENV_DIR="$APP_DIR/venv"
REQUIREMENTS_FILE="$APP_DIR/requirements.txt"
RUN_FILE="$APP_DIR/run.py"

log_info "Starting Inventory App setup and launch..."

# Check if app directory exists
if [ ! -d "$APP_DIR" ]; then
    log_error "Inventory app directory not found: $APP_DIR"
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

# Start the application
log_success "Starting Inventory App..."
log_info "Application will be available at: http://localhost:8080"
log_info "Press Ctrl+C to stop the application"
echo ""

python run.py
