# Microservices Docker Infrastructure

A containerized microservices architecture with Docker and Docker Compose, featuring inventory management, billing services, and an API gateway with RabbitMQ message queuing.

## Architecture Overview

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Client/Web    │    │   Client/Web    │    │   Client/Web    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
                                 ▼
                    ┌─────────────────────┐
                    │   api-gateway-app   │
                    │      (Port 3000)    │
                    └─────────────────────┘
                                 │
                ┌────────────────┼────────────────┐
                │                │                │
                ▼                ▼                ▼
    ┌───────────────────┐ ┌─────────────┐ ┌─────────────┐
    │   inventory-app   │ │ rabbit-queue│ │ billing-app │
    │   (Port 8080)     │ │  (RabbitMQ) │ │ (Port 8080) │
    └───────────────────┘ └─────────────┘ └─────────────┘
                │                │                │
                ▼                │                ▼
        ┌─────────────┐         │        ┌─────────────┐
        │inventory-db │         │        │ billing-db  │
        │(PostgreSQL) │         │        │(PostgreSQL) │
        └─────────────┘         │        └─────────────┘
                                │
                                ▼
                        ┌─────────────┐
                        │   Message   │
                        │   Queue     │
                        └─────────────┘
```

## Services

### Core Services
- **api-gateway-app**: Entry point for all requests (Port 3000)
- **inventory-app**: Manages movie inventory (Port 8080)
- **billing-app**: Handles billing and consumes queue messages (Port 8080)

### Infrastructure Services
- **inventory-db**: PostgreSQL database for inventory data
- **billing-db**: PostgreSQL database for billing data
- **rabbit-queue**: RabbitMQ message broker

## Prerequisites

- Docker (20.10+)
- Docker Compose (2.0+)
- 4GB RAM minimum
- 2GB free disk space

### Installation

**Ubuntu/Debian:**
```bash
# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Install Docker Compose
sudo apt-get install docker-compose-plugin

# Add user to docker group
sudo usermod -aG docker $USER
```

**macOS:**
```bash
# Install Docker Desktop
brew install --cask docker
```

## Quick Start

1. **Clone and setup environment:**
```bash
git clone <repository-url>
cd <project-directory>
cp .env.example .env  # Edit with your values
```

2. **Start all services:**
```bash
chmod +x docker-start.sh
./docker-start.sh
```

3. **Access services:**
- API Gateway: http://localhost:3000
- RabbitMQ Management: http://localhost:15672 (guest/guest)

4. **Stop services:**
```bash
chmod +x docker-stop.sh
./docker-stop.sh
```

## Configuration

### Environment Variables (.env)

```env
# Database Configuration
INVENTORY_DB_NAME=movies_db
INVENTORY_DB_USER=postgres
INVENTORY_DB_PASSWORD=your_secure_password

BILLING_DB_NAME=billing_db
BILLING_DB_USER=postgres
BILLING_DB_PASSWORD=your_secure_password

# RabbitMQ Configuration
RABBITMQ_USER=admin
RABBITMQ_PASSWORD=your_secure_password
RABBITMQ_QUEUE=billing_queue

# Application Configuration
DEBUG=false
```

### Port Mapping

| Service | Internal Port | External Port | Access |
|---------|---------------|---------------|---------|
| api-gateway-app | 3000 | 3000 | Public |
| inventory-app | 8080 | 8080 | Internal |
| billing-app | 8080 | 8081 | Internal |
| inventory-db | 5432 | 5432 | Internal |
| billing-db | 5432 | 5433 | Internal |
| rabbit-queue | 5672 | 5672 | Internal |
| rabbit-queue (mgmt) | 15672 | 15672 | Public |

## File Structure

```
project/
├── docker-compose.yml          # Main orchestration file
├── .env                       # Environment variables
├── .gitignore                 # Git ignore rules
├── docker-start.sh            # Start script
├── docker-stop.sh             # Stop script
├── README.md                  # This file
└── srcs/
    ├── api-gateway/
    │   ├── Dockerfile
    │   ├── requirements.txt
    │   └── app/
    ├── inventory-app/
    │   ├── Dockerfile
    │   ├── requirements.txt
    │   └── app/
    └── billing-app/
        ├── Dockerfile
        ├── requirements.txt
        └── app/
```

## Management Scripts

### docker-start.sh
```bash
# Start all services
./docker-start.sh

# Start with logs
./docker-start.sh --logs

# Show help
./docker-start.sh --help
```

### docker-stop.sh
```bash
# Stop services
./docker-stop.sh

# Stop and clean up everything
./docker-stop.sh --clean

# Show status
./docker-stop.sh --status
```

## Docker Commands

### Basic Operations
```bash
# Build and start services
docker-compose up --build -d

# Stop services
docker-compose down

# View logs
docker-compose logs -f

# View specific service logs
docker-compose logs -f api-gateway-app

# Check service status
docker-compose ps

# Scale a service
docker-compose up --scale billing-app=3 -d
```

### Debugging
```bash
# Execute commands in container
docker-compose exec inventory-app bash

# Connect to database
docker-compose exec inventory-db psql -U postgres -d movies_db

# View container resources
docker stats

# Inspect container
docker inspect inventory-app
```

## API Endpoints

### Health Checks
- `GET /health` - Service health status

### Inventory API (via Gateway)
- `GET /api/inventory/movies` - List all movies
- `POST /api/inventory/movies` - Add new movie
- `GET /api/inventory/movies/{id}` - Get movie details
- `PUT /api/inventory/movies/{id}` - Update movie
- `DELETE /api/inventory/movies/{id}` - Delete movie

### Billing API (via Gateway)
- `GET /api/billing/orders` - List all orders
- `POST /api/billing/orders` - Create new order
- `GET /api/billing/orders/{id}` - Get order details

## Database Schema

### Inventory Database (movies_db)
```sql
CREATE TABLE movies (
    id SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    description TEXT
);
```

### Billing Database (billing_db)
```sql
CREATE TABLE orders (
    id SERIAL PRIMARY KEY,
    user_id VARCHAR(50) NOT NULL,
    number_of_items INTEGER NOT NULL,
    total_amount DOUBLE PRECISION NOT NULL
);
```

## Monitoring and Logging

### Health Checks
All services include health check endpoints:
- Response time: 30s interval
- Timeout: 10s
- Retries: 5

### Logs
```bash
# View all logs
docker-compose logs -f

# View specific service
docker-compose logs -f api-gateway-app

# View last 100 lines
docker-compose logs --tail=100 inventory-app
```

### Volumes
- `inventory-db-volume`: Persistent inventory database data
- `billing-db-volume`: Persistent billing database data  
- `api-gateway-logs`: API Gateway log files

## Security

### Network Security
- All services run in isolated Docker network
- Only API Gateway exposed to external traffic
- Inter-service communication via internal network

### Container Security
- Non-root user execution
- Minimal Alpine Linux base images
- No unnecessary packages installed
- Environment variable based configuration

## Troubleshooting

### Common Issues

**Services won't start:**
```bash
# Check Docker daemon
sudo systemctl status docker

# Check port conflicts
sudo netstat -tulpn | grep :3000

# View detailed logs
docker-compose logs api-gateway-app
```

**Database connection errors:**
```bash
# Check database health
docker-compose exec inventory-db pg_isready -U postgres

# Reset database
docker-compose down
docker volume rm $(docker volume ls -q | grep -E "(inventory|billing)")
docker-compose up -d
```

**RabbitMQ issues:**
```bash
# Check RabbitMQ status
docker-compose exec rabbit-queue rabbitmqctl status

# Access management UI
open http://localhost:15672
```

### Performance Tuning

**Memory optimization:**
```yaml
# Add to docker-compose.yml services
deploy:
  resources:
    limits:
      memory: 512M
    reservations:
      memory: 256M
```

**Database optimization:**
```bash
# Increase shared buffers
docker-compose exec inventory-db psql -U postgres -c "ALTER SYSTEM SET shared_buffers = '256MB';"
```

## Development

### Local Development
```bash
# Start only databases
docker-compose up inventory-db billing-db rabbit-queue -d

# Run applications locally
cd srcs/inventory-app && python run.py
cd srcs/billing-app && python run.py  
cd srcs/api-gateway && python run.py
```

### Testing
```bash
# Run health checks
curl http://localhost:3000/health

# Test inventory endpoint
curl http://localhost:3000/api/inventory/movies

# Test billing endpoint
curl -X POST http://localhost:3000/api/billing/orders \
  -H "Content-Type: application/json" \
  -d '{"user_id": "user123", "number_of_items": 2, "total_amount": 25.50}'
```

## Deployment

### Production Considerations
1. Use production-ready database configurations
2. Set up proper logging aggregation
3. Configure monitoring and alerting
4. Use Docker Swarm or Kubernetes for orchestration
5. Set up CI/CD pipelines
6. Configure backup strategies

### Environment Variables for Production
```env
DEBUG=false
POSTGRES_PASSWORD=<strong-password>
RABBITMQ_PASSWORD=<strong-password>
```

## Contributing

1. Create feature branch
2. Make changes
3. Test with Docker environment
4. Submit pull request

## License

This project is licensed under the MIT License.