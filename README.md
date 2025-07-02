# CRUD Master - Microservices Architecture

A movie streaming platform built with microservices architecture, featuring an API Gateway, Inventory API, and Billing API deployed across multiple virtual machines.

## Architecture Overview

```
┌─────────────────┐    HTTP     ┌─────────────────┐
│   API Gateway   │────────────▶│  Inventory API  │
│  (gateway-vm)   │             │ (inventory-vm)  │
│                 │             │   PostgreSQL    │
└─────────────────┘             └─────────────────┘
         │
         │ RabbitMQ
         ▼
┌─────────────────┐
│   Billing API   │
│  (billing-vm)   │
│   PostgreSQL    │
│   RabbitMQ      │
└─────────────────┘
```

## Prerequisites

Before starting, ensure you have the following installed:

- **VirtualBox**: Download from [virtualbox.org](https://www.virtualbox.org/)
- **Vagrant**: Download from [vagrantup.com](https://www.vagrantup.com/)
- **Git**: For cloning repositories

### Installation Links
- VirtualBox: https://www.virtualbox.org/wiki/Downloads
- Vagrant: https://www.vagrantup.com/downloads

## Project Structure

```
crud-master/
├── README.md
├── .env                        # Environment variables
├── Vagrantfile                 # VM configuration
├── scripts/                    # Setup scripts for VMs
│   ├── setup_gateway.sh
│   ├── setup_inventory.sh
│   └── setup_billing.sh
└── srcs/                       # Application source code
    ├── api-gateway/
    │   ├── app/
    │   ├── run.py
    │   ├── requirements.txt
    │   └── .env
    ├── inventory-app/
    │   ├── app/
    │   ├── run.py
    │   ├── requirements.txt
    │   └── .env
    └── billing-app/
        ├── app/
        ├── run.py
        ├── consumer.py
        ├── requirements.txt
        └── .env
```

## Quick Start

1. **Clone your existing applications** into the proper structure:
   ```bash
   mkdir -p crud-master/srcs
   cd crud-master/srcs
   
   # Move your existing applications here
   mv /path/to/your/flask_inventory ./inventory-app
   mv /path/to/your/flask_billing ./billing-app
   mv /path/to/your/api_gateway ./api-gateway
   ```

2. **Create the required files** (copy the provided Vagrantfile, scripts, and .env)

3. **Start the infrastructure**:
   ```bash
   cd crud-master
   vagrant up
   ```

4. **Check VM status**:
   ```bash
   vagrant status
   ```

## VM Configuration

### Gateway VM (192.168.56.10)
- **Purpose**: Routes requests to appropriate services
- **Port**: 5000
- **Services**: API Gateway
- **Access**: http://localhost:5000

### Inventory VM (192.168.56.11)
- **Purpose**: Manages movie inventory
- **Port**: 8080
- **Services**: Flask API, PostgreSQL (movies_db)
- **Access**: http://localhost:8080

### Billing VM (192.168.56.12)
- **Purpose**: Processes billing via message queue
- **Ports**: 8081, 15672 (RabbitMQ Management)
- **Services**: Flask API, PostgreSQL (billing_db), RabbitMQ
- **Access**: http://localhost:8081, http://localhost:15672

## API Endpoints

### Through API Gateway (http://localhost:5000)

#### Inventory Endpoints
- `GET /api/movies` - Get all movies
- `GET /api/movies?title=[name]` - Search movies by title
- `POST /api/movies` - Create new movie
- `DELETE /api/movies` - Delete all movies
- `GET /api/movies/:id` - Get movie by ID
- `PUT /api/movies/:id` - Update movie by ID
- `DELETE /api/movies/:id` - Delete movie by ID

#### Billing Endpoint
- `POST /api/billing` - Send billing message to queue

Example billing request:
```json
{
  "user_id": "3",
  "number_of_items": "5",
  "total_amount": "180"
}
```

## Managing Applications with PM2

Access any VM via SSH:
```bash
vagrant ssh gateway-vm
vagrant ssh inventory-vm
vagrant ssh billing-vm
```

Inside VMs, use PM2 commands:
```bash
sudo pm2 list                    # List all applications
sudo pm2 stop api-gateway        # Stop specific application
sudo pm2 start api-gateway       # Start specific application
sudo pm2 restart api-gateway     # Restart application
sudo pm2 logs api-gateway        # View logs
```

### Application Names by VM:
- **gateway-vm**: `api-gateway`
- **inventory-vm**: `inventory-api`
- **billing-vm**: `billing-api`, `billing-consumer`

## Testing the Infrastructure

### 1. Test Inventory API
```bash
# Get all movies
curl http://localhost:5000/api/movies

# Create a new movie
curl -X POST http://localhost:5000/api/movies \
  -H "Content-Type: application/json" \
  -d '{"title": "The Matrix", "description": "A sci-fi classic"}'
```

### 2. Test Billing API
```bash
# Send billing request
curl -X POST http://localhost:5000/api/billing \
  -H "Content-Type: application/json" \
  -d '{"user_id": "1", "number_of_items": "2", "total_amount": "50"}'
```

### 3. Test Resilience
```bash
# SSH into billing VM
vagrant ssh billing-vm

# Stop billing consumer
sudo pm2 stop billing-consumer

# Send billing requests (should still work)
curl -X POST http://localhost:5000/api/billing \
  -H "Content-Type: application/json" \
  -d '{"user_id": "2", "number_of_items": "3", "total_amount": "75"}'

# Start billing consumer (processes queued messages)
sudo pm2 start billing-consumer
```

## Environment Variables

All environment variables are centralized in the `.env` file at the project root. Key variables include:

- `POSTGRES_USER`, `POSTGRES_PASSWORD`: Database credentials
- `API_GATEWAY_PORT`, `INVENTORY_API_PORT`, `BILLING_API_PORT`: Service ports
- `GATEWAY_VM_IP`, `INVENTORY_VM_IP`, `BILLING_VM_IP`: VM IP addresses
- `RABBITMQ_*`: RabbitMQ configuration

## Troubleshooting

### VM Issues
```bash
# Destroy and recreate VMs
vagrant destroy -f
vagrant up

# Provision specific VM
vagrant provision gateway-vm
```

### Application Issues
```bash
# SSH into problematic VM
vagrant ssh [vm-name]

# Check PM2 status and logs
sudo pm2 list
sudo pm2 logs [app-name]

# Restart application
sudo pm2 restart [app-name]
```

### Network Issues
- Ensure VirtualBox host-only adapter is configured
- Check if ports are already in use on host machine
- Verify firewall settings

## Development

To develop locally before deploying to VMs:

1. **Set up Python virtual environments** for each application
2. **Install dependencies** using `pip install -r requirements.txt`
3. **Configure local databases and RabbitMQ**
4. **Test each component individually**
5. **Deploy to VMs using Vagrant**

## Technology Stack

- **Backend**: Python Flask
- **Databases**: PostgreSQL
- **Message Queue**: RabbitMQ
- **Process Manager**: PM2
- **Virtualization**: Vagrant + VirtualBox
- **ORM**: SQLAlchemy
- **HTTP Client**: Requests (for gateway)
- **Message Queue Client**: Pika

## Design Decisions

1. **Separate VMs**: Each service runs in isolation for better fault tolerance
2. **PM2 Process Management**: Ensures applications restart on failure
3. **Environment Variables**: Centralized configuration management
4. **Message Queuing**: Asynchronous billing processing for better performance
5. **RESTful APIs**: Standard HTTP methods for inventory operations

## Production Considerations

This setup is for development/testing purposes. For production:

- Use container orchestration (Docker + Kubernetes)
- Implement proper security (HTTPS, authentication)
- Add monitoring and logging solutions
- Use managed database services
- Implement proper error handling and retry mechanisms
- Add API rate limiting and caching