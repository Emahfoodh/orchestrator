#!/bin/bash

# Inventory Database Setup Script
# Creates a separate PostgreSQL Docker container for the inventory service

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INVENTORY DB]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[INVENTORY DB]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[INVENTORY DB]${NC} $1"
}

log_error() {
    echo -e "${RED}[INVENTORY DB]${NC} $1"
}

# Configuration
CONTAINER_NAME="inventory_postgres"
DB_NAME="movies_db"
DB_USER="postgres"
DB_PASSWORD="postgres"
DB_PORT="5432"
HOST_PORT="5435"

log_info "Setting up Inventory Database Container..."

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

# Function to setup PostgreSQL container
setup_postgres_container() {
    log_info "Setting up PostgreSQL container for inventory service..."
    
    # Check if container already exists
    if docker ps -a --format "table {{.Names}}" | grep -q "^${CONTAINER_NAME}$"; then
        log_warning "Container '$CONTAINER_NAME' already exists"
        
        # Check if it's running
        if docker ps --format "table {{.Names}}" | grep -q "^${CONTAINER_NAME}$"; then
            log_info "Container '$CONTAINER_NAME' is already running"
        else
            log_info "Starting existing container '$CONTAINER_NAME'..."
            docker start $CONTAINER_NAME
            log_success "Container '$CONTAINER_NAME' started"
        fi
    else
        log_info "Creating new PostgreSQL container '$CONTAINER_NAME'..."
        docker run -d \
            --name $CONTAINER_NAME \
            -e POSTGRES_DB=$DB_NAME \
            -e POSTGRES_USER=$DB_USER \
            -e POSTGRES_PASSWORD=$DB_PASSWORD \
            -p ${HOST_PORT}:${DB_PORT} \
            postgres:13
        log_success "Container '$CONTAINER_NAME' created and started"
    fi
    
    # Wait for PostgreSQL to be ready
    log_info "Waiting for PostgreSQL to be ready..."
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if docker exec $CONTAINER_NAME pg_isready -U $DB_USER -d $DB_NAME &> /dev/null; then
            log_success "PostgreSQL is ready"
            break
        else
            log_info "Waiting for PostgreSQL... (attempt $attempt/$max_attempts)"
            sleep 2
            ((attempt++))
        fi
    done
    
    if [ $attempt -gt $max_attempts ]; then
        log_error "PostgreSQL failed to start properly"
        exit 1
    fi
}

# Function to create tables
create_tables() {
    log_info "Creating inventory tables..."
    
    # Create movies table
    docker exec -i $CONTAINER_NAME psql -U $DB_USER -d $DB_NAME << 'EOF'
CREATE TABLE IF NOT EXISTS movies (
    id SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    description TEXT
);
EOF
    
    log_success "Movies table created successfully"
    
    # Show table structure
    log_info "Table structure:"
    docker exec $CONTAINER_NAME psql -U $DB_USER -d $DB_NAME -c "\d movies"
}

# Function to show connection info
show_connection_info() {
    log_success "Inventory Database Setup Complete!"
    echo ""
    echo "Connection Details:"
    echo "  Container Name: $CONTAINER_NAME"
    echo "  Database Name: $DB_NAME"
    echo "  Host: localhost"
    echo "  Port: $HOST_PORT"
    echo "  User: $DB_USER"
    echo "  Password: $DB_PASSWORD"
    echo ""
    echo "Connection String:"
    echo "  postgresql://$DB_USER:$DB_PASSWORD@localhost:$HOST_PORT/$DB_NAME"
    echo ""
    echo "Docker Commands:"
    echo "  Stop container: docker stop $CONTAINER_NAME"
    echo "  Start container: docker start $CONTAINER_NAME"
    echo "  Remove container: docker rm $CONTAINER_NAME"
    echo "  Connect to DB: docker exec -it $CONTAINER_NAME psql -U $DB_USER -d $DB_NAME"
}

# Function to verify setup
verify_setup() {
    log_info "Verifying setup..."
    
    # Check container status
    if docker ps --format "table {{.Names}}" | grep -q "^${CONTAINER_NAME}$"; then
        log_success "✓ Container is running"
    else
        log_error "✗ Container is not running"
        return 1
    fi
    
    # Check database connectivity
    if docker exec $CONTAINER_NAME pg_isready -U $DB_USER -d $DB_NAME &> /dev/null; then
        log_success "✓ Database is accessible"
    else
        log_error "✗ Database is not accessible"
        return 1
    fi
    
    # Check table exists
    local table_exists=$(docker exec $CONTAINER_NAME psql -U $DB_USER -d $DB_NAME -tAc "SELECT 1 FROM information_schema.tables WHERE table_name='movies'")
    if [ "$table_exists" = "1" ]; then
        log_success "✓ Movies table exists"
        
        # Show row count
        local count=$(docker exec $CONTAINER_NAME psql -U $DB_USER -d $DB_NAME -tAc "SELECT COUNT(*) FROM movies")
        log_info "  Current movies count: $count"
    else
        log_error "✗ Movies table missing"
        return 1
    fi
}

# Function to show usage
show_usage() {
    echo "Inventory Database Setup Script"
    echo ""
    echo "Usage: $0 [OPTION]"
    echo ""
    echo "Options:"
    echo "  --setup          Setup container and create tables (default)"
    echo "  --verify         Verify existing setup"
    echo "  --info           Show connection information"
    echo "  --help           Show this help message"
}

# Main execution
main() {
    local action=${1:-"--setup"}
    
    case $action in
        --help)
            show_usage
            exit 0
            ;;
        --verify)
            log_info "Verifying inventory database setup..."
            check_docker
            verify_setup
            ;;
        --info)
            show_connection_info
            ;;
        --setup)
            log_info "Setting up inventory database..."
            check_docker
            setup_postgres_container
            create_tables
            verify_setup
            show_connection_info
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
