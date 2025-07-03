# Database and Service Setup Scripts

This directory contains scripts for setting up and managing the PostgreSQL databases and services for the CRUD Master microservices project.

## Files

### Database Setup Scripts
- `setup_database.sh` - Legacy database setup script (for single PostgreSQL instance)
- `setup_inventory_db.sh` - Setup script for inventory database Docker container
- `setup_billing_db.sh` - Setup script for billing database Docker container

### Service Startup Scripts
- `start_inventory.sh` - Start inventory service script
- `start_billing.sh` - Start billing service script (includes RabbitMQ setup)
- `start_gateway.sh` - Start API gateway script
- `start_all.sh` - Master script to start all services

## Database Setup Scripts

### setup_inventory_db.sh

Creates a dedicated PostgreSQL Docker container for the inventory service.

**Features:**
- **Container Management**: Creates and manages `inventory_postgres` container
- **Port Configuration**: Maps to host port 5435
- **Database**: Creates `movies_db` database with `movies` table
- **Health Checks**: Verifies container and database connectivity
- **Idempotent Operations**: Safe to run multiple times

**Usage:**
```bash
chmod +x setup_inventory_db.sh

# Setup container and create tables (default)
./setup_inventory_db.sh
./setup_inventory_db.sh --setup

# Verify existing setup
./setup_inventory_db.sh --verify

# Show connection information
./setup_inventory_db.sh --info

# Show help
./setup_inventory_db.sh --help
```

**Connection Details:**
- **Container**: inventory_postgres
- **Host Port**: 5435
- **Database**: movies_db
- **Connection String**: postgresql://postgres:postgres@localhost:5435/movies_db

### setup_billing_db.sh

Creates a dedicated PostgreSQL Docker container for the billing service.

**Features:**
- **Container Management**: Creates and manages `billing_postgres` container
- **Port Configuration**: Maps to host port 5436
- **Database**: Creates `billing_db` database with `orders` table
- **Health Checks**: Verifies container and database connectivity
- **Idempotent Operations**: Safe to run multiple times

**Usage:**
```bash
chmod +x setup_billing_db.sh

# Setup container and create tables (default)
./setup_billing_db.sh
./setup_billing_db.sh --setup

# Verify existing setup
./setup_billing_db.sh --verify

# Show connection information
./setup_billing_db.sh --info

# Show help
./setup_billing_db.sh --help
```

**Connection Details:**
- **Container**: billing_postgres
- **Host Port**: 5436
- **Database**: billing_db
- **Connection String**: postgresql://postgres:postgres@localhost:5436/billing_db

### setup_database.sh (Legacy)

Original database setup script for single PostgreSQL instance. Still functional but deprecated in favor of separate containers.

## Service Startup Scripts

### start_inventory.sh

Sets up virtual environment and starts the inventory service.

**Features:**
- **Virtual Environment**: Creates and activates Python venv
- **Dependencies**: Installs requirements automatically
- **Configuration**: Loads from .env file
- **Port**: Runs on 8080

**Usage:**
```bash
./start_inventory.sh
```

### start_billing.sh

Sets up RabbitMQ, virtual environment, and starts the billing service.

**Features:**
- **RabbitMQ Management**: Automatically creates and manages RabbitMQ container
- **Virtual Environment**: Creates and activates Python venv
- **Dependencies**: Installs requirements automatically
- **Configuration**: Loads from .env file
- **Port**: Runs on 8081
- **Management UI**: RabbitMQ UI available at http://localhost:15672

**Usage:**
```bash
./start_billing.sh
```

### start_gateway.sh

Sets up virtual environment and starts the API Gateway.

**Features:**
- **Virtual Environment**: Creates and activates Python venv
- **Dependencies**: Installs requirements automatically
- **Configuration**: Loads from .env file
- **Port**: Runs on 5000
- **Routing**: Routes requests to inventory (8080) and billing (8081) services

**Usage:**
```bash
./start_gateway.sh
```

### start_all.sh

Master script that orchestrates the entire system startup.

**Features:**
- **Prerequisites Check**: Verifies Python, Docker, PostgreSQL
- **Database Setup**: Automatically sets up databases
- **Service Management**: Starts all services in correct order
- **Health Checks**: Verifies all services are responding
- **Process Management**: Background execution with PID tracking
- **Comprehensive Logging**: Detailed status reporting

**Usage:**
```bash
# Full setup and start (default)
./start_all.sh
./start_all.sh --full

# Only setup databases
./start_all.sh --setup-only

# Only start services (assumes setup is done)
./start_all.sh --start-services

# Show help
./start_all.sh --help
```

## Complete Setup Workflow

### Option 1: Separate Database Containers (Recommended)

```bash
# 1. Setup separate database containers
./setup_inventory_db.sh --setup
./setup_billing_db.sh --setup

# 2. Start services
./start_inventory.sh    # Terminal 1
./start_billing.sh      # Terminal 2  
./start_gateway.sh      # Terminal 3

# Or use master script
./start_all.sh --start-services
```

### Option 2: All-in-One Setup

```bash
# Setup everything and start all services
./start_all.sh --full
```

### Option 3: Legacy Single Database

```bash
# Use original database setup
./setup_database.sh --full

# Start services manually
./start_inventory.sh    # Terminal 1
./start_billing.sh      # Terminal 2  
./start_gateway.sh      # Terminal 3
```

## Database Architecture

### Separate Containers (Current)
```
┌─────────────────────┐    ┌─────────────────────┐
│ Inventory Service   │────│ inventory_postgres  │
│     (Port 8080)     │    │    (Port 5435)      │
│                     │    │    Database: movies │
└─────────────────────┘    └─────────────────────┘

┌─────────────────────┐    ┌─────────────────────┐
│ Billing Service     │────│ billing_postgres    │
│     (Port 8081)     │    │    (Port 5436)      │
│                     │    │   Database: billing │
└─────────────────────┘    └─────────────────────┘

┌─────────────────────┐    ┌─────────────────────┐
│ API Gateway         │    │      RabbitMQ       │
│     (Port 5000)     │    │    (Port 5672)      │
│                     │    │   Management: 15672 │
└─────────────────────┘    └─────────────────────┘
```

## Environment Configuration

All scripts read configuration from:
- **Main .env**: Project root `.env` file
- **Service .env**: Individual service `.env` files in `srcs/*/`

Key environment variables:
- `INVENTORY_DB_PORT=5435`
- `BILLING_DB_PORT=5436`
- `POSTGRES_USER=postgres`
- `POSTGRES_PASSWORD=postgres`

## Prerequisites

- **Docker**: For database containers and RabbitMQ
- **Python 3.7+**: For microservices
- **PostgreSQL Client Tools**: For database operations (psql, pg_isready)

## Troubleshooting

### Port Conflicts
```bash
# Check what's using ports
lsof -i :5435  # Inventory DB
lsof -i :5436  # Billing DB
lsof -i :5672  # RabbitMQ
lsof -i :8080  # Inventory Service
lsof -i :8081  # Billing Service
lsof -i :5000  # API Gateway
```

### Container Issues
```bash
# Check container status
docker ps -a

# Restart containers
docker restart inventory_postgres billing_postgres rabbitmq

# Remove and recreate
docker rm -f inventory_postgres billing_postgres
./setup_inventory_db.sh --setup
./setup_billing_db.sh --setup
```

### Service Issues
```bash
# Check if virtual environments exist
ls -la ../srcs/*/venv/

# Reinstall dependencies
cd ../srcs/inventory-app && rm -rf venv && python3 -m venv venv && source venv/bin/activate && pip install -r requirements.txt
```

## Testing

After setup, test the services:

```bash
# Test inventory service
curl http://localhost:8080/api/movies

# Test billing service  
curl http://localhost:8081/api/health

# Test API gateway
curl http://localhost:5000/api/movies

# Run comprehensive tests
cd .. && python3 api_testers.py
```

## Production Considerations

- **Container Orchestration**: Consider Docker Compose or Kubernetes for production
- **Data Persistence**: Use Docker volumes for database data persistence
- **Backup Strategy**: Implement database backup procedures
- **Monitoring**: Add health check endpoints and monitoring
- **Security**: Configure proper authentication and network security
- **High Availability**: Consider database replication and load balancing

## Related Files

- `../.env` - Main project environment configuration
- `../srcs/*/app/models.py` - Database models and schemas
- `../api_testers.py` - Comprehensive API testing suite
- `../HOW_TO_RUN.md` - Manual setup instructions
