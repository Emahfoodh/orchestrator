# CRUD Master - How to Run and Test

This guide explains how to run the CRUD Master microservices and test all APIs.

## Project Overview

The CRUD Master project consists of three microservices:

1. **API Gateway** (Port 5000) - Routes requests to other services
2. **Inventory Service** (Port 8080) - Manages movie inventory
3. **Billing Service** (Port 8081) - Processes billing through message queues

## Architecture

```
┌─────────────────┐    HTTP     ┌─────────────────┐
│   API Gateway   │────────────▶│  Inventory API  │
│   (Port 5000)   │             │   (Port 8080)   │
│                 │             │   PostgreSQL    │
└─────────────────┘             └─────────────────┘
         │
         │ RabbitMQ
         ▼
┌─────────────────┐
│   Billing API   │
│   (Port 8081)   │
│   PostgreSQL    │
│   RabbitMQ      │
└─────────────────┘
```

## Prerequisites

- Python 3.7+
- pip (Python package installer)

## Step-by-Step Setup and Running

### 1. Set up Virtual Environments and Dependencies

Each service needs its own virtual environment:

```bash
# Setup API Gateway
cd srcs/api-gateway
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
deactivate

# Setup Inventory Service
cd ../inventory-app
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
deactivate

# Setup Billing Service
cd ../billing-app
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
deactivate

# Return to project root
cd ../../
```

### 2. Start the Services

**Important**: Start services in separate terminal windows/tabs and keep them running.

#### Terminal 1 - Inventory Service
```bash
cd srcs/inventory-app
source venv/bin/activate
python run.py
```
You should see:
```
* Running on http://127.0.0.1:8080
* Debug mode: on
```

#### Terminal 2 - Billing Service
```bash
cd srcs/billing-app
source venv/bin/activate
python run.py
```
You should see the service starting on port 8081.

#### Terminal 3 - API Gateway
```bash
cd srcs/api-gateway
source venv/bin/activate
python run.py
```
You should see:
```
* Running on http://127.0.0.1:5000
* Debug mode: on
```

### 3. Verify Services are Running

Check that all services respond:

```bash
# Check Inventory Service
curl http://localhost:8080/api/movies

# Check Billing Service
curl http://localhost:8081/api/health

# Check API Gateway
curl http://localhost:5000/api/movies
```

## API Endpoints

### Inventory Service (Direct: Port 8080, Via Gateway: Port 5000)

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/movies` | Get all movies |
| GET | `/api/movies?title=name` | Search movies by title |
| POST | `/api/movies` | Create a new movie |
| GET | `/api/movies/{id}` | Get movie by ID |
| PUT | `/api/movies/{id}` | Update movie by ID |
| DELETE | `/api/movies/{id}` | Delete movie by ID |
| DELETE | `/api/movies` | Delete all movies |

#### Example Requests:

**Create a movie:**
```bash
curl -X POST http://localhost:5000/api/movies \
  -H "Content-Type: application/json" \
  -d '{"title": "The Matrix", "description": "A sci-fi classic"}'
```

**Get all movies:**
```bash
curl http://localhost:5000/api/movies
```

**Search movies:**
```bash
curl "http://localhost:5000/api/movies?title=Matrix"
```

**Update a movie:**
```bash
curl -X PUT http://localhost:5000/api/movies/1 \
  -H "Content-Type: application/json" \
  -d '{"title": "The Matrix Reloaded", "description": "The sequel"}'
```

**Delete a movie:**
```bash
curl -X DELETE http://localhost:5000/api/movies/1
```

### Billing Service

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/billing` | Send billing request (via Gateway only) |
| GET | `/api/orders` | Get all orders (Direct access only) |
| GET | `/api/orders/{id}` | Get order by ID (Direct access only) |
| GET | `/api/health` | Health check (Direct access only) |

#### Example Requests:

**Send billing request (via Gateway):**
```bash
curl -X POST http://localhost:5000/api/billing \
  -H "Content-Type: application/json" \
  -d '{"user_id": "123", "number_of_items": "5", "total_amount": "99.99"}'
```

**Get orders (direct access):**
```bash
curl http://localhost:8081/api/orders
```

**Health check:**
```bash
curl http://localhost:8081/api/health
```

## Testing the APIs

We provide two comprehensive testing tools:

### Option 1: Python Test Suite (Recommended)

Run the comprehensive Python test suite:

```bash
python3 api_testers.py
```

This will:
- Check if all services are running
- Test all endpoints systematically
- Provide detailed results with colored output
- Test both direct service access and gateway routing
- Run integration tests

### Option 2: Bash/curl Test Suite

Run the curl-based test suite:

```bash
./curl_tests.sh
```

This provides the same functionality using curl commands.

### Manual Testing Examples

You can also test manually:

```bash
# 1. Create some movies
curl -X POST http://localhost:5000/api/movies \
  -H "Content-Type: application/json" \
  -d '{"title": "Inception", "description": "A mind-bending thriller"}'

curl -X POST http://localhost:5000/api/movies \
  -H "Content-Type: application/json" \
  -d '{"title": "The Dark Knight", "description": "Batman epic"}'

# 2. Get all movies
curl http://localhost:5000/api/movies

# 3. Search for movies
curl "http://localhost:5000/api/movies?title=Inception"

# 4. Send billing requests
curl -X POST http://localhost:5000/api/billing \
  -H "Content-Type: application/json" \
  -d '{"user_id": "user1", "number_of_items": "2", "total_amount": "29.99"}'

curl -X POST http://localhost:5000/api/billing \
  -H "Content-Type: application/json" \
  -d '{"user_id": "user2", "number_of_items": "1", "total_amount": "14.99"}'

# 5. Check processed orders
curl http://localhost:8081/api/orders
```

## Service Details

### API Gateway
- **Port**: 5000
- **Purpose**: Routes requests to appropriate microservices
- **Features**: 
  - Proxies inventory requests to Inventory Service
  - Sends billing requests to RabbitMQ queue
  - CORS enabled

### Inventory Service
- **Port**: 8080
- **Database**: SQLite (configured in .env)
- **Features**:
  - Full CRUD operations for movies
  - Search functionality
  - RESTful API design

### Billing Service
- **Port**: 8081
- **Database**: SQLite (configured in .env)
- **Message Queue**: RabbitMQ (if available, otherwise uses internal processing)
- **Features**:
  - Processes billing requests asynchronously
  - Stores orders in database
  - Health check endpoint

## Troubleshooting

### Services Won't Start

1. **Port already in use**: 
   ```bash
   # Check what's using the port
   lsof -i :5000  # for API Gateway
   lsof -i :8080  # for Inventory
   lsof -i :8081  # for Billing
   ```

2. **Python dependencies missing**:
   ```bash
   # Reinstall dependencies
   cd srcs/[service-name]
   source venv/bin/activate
   pip install -r requirements.txt
   ```

3. **Database connection errors**:
   - Services are configured to use SQLite by default
   - Database files will be created automatically

### API Tests Failing

1. **Services not running**: Make sure all three services are started
2. **Wrong ports**: Verify services are running on expected ports
3. **Database issues**: Delete database files and restart services to reset

### Quick Reset

To reset everything:

```bash
# Stop all services (Ctrl+C in each terminal)
# Remove database files (if any)
find . -name "*.db" -delete
# Restart services
```

## API Documentation

A comprehensive OpenAPI/Swagger specification is available in `swagger.yaml`. This file documents all endpoints, request/response schemas, and provides interactive documentation.

To view the interactive documentation:

1. **Online Swagger Editor**: 
   - Go to https://editor.swagger.io/
   - Copy and paste the contents of `swagger.yaml`

2. **Local Swagger UI** (if you have it installed):
   ```bash
   # If you have swagger-ui-serve installed
   swagger-ui-serve swagger.yaml
   ```

3. **VS Code**: Install the "OpenAPI (Swagger) Editor" extension to view and edit the spec.

## File Structure

```
crud-master/
├── api_testers.py          # Python test suite
├── curl_tests.sh           # Bash test suite
├── swagger.yaml            # OpenAPI/Swagger API documentation
├── HOW_TO_RUN.md          # This file
├── README.md              # Project overview
└── srcs/
    ├── api-gateway/       # API Gateway service
    │   ├── app/
    │   ├── run.py
    │   ├── requirements.txt
    │   └── .env
    ├── inventory-app/     # Inventory service
    │   ├── app/
    │   ├── run.py
    │   ├── requirements.txt
    │   └── .env
    └── billing-app/       # Billing service
        ├── app/
        ├── run.py
        ├── consumer.py    # RabbitMQ consumer
        ├── requirements.txt
        └── .env
```

## Next Steps

1. **Start all services** following the setup guide above
2. **Run the test suite** to verify everything works: `python3 api_testers.py`
3. **Experiment with the APIs** using the provided examples
4. **Check the logs** in each terminal to see request processing

For production deployment, refer to the main README.md for Vagrant/VM setup instructions.
