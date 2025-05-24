# API Gateway

This is the API Gateway component that routes requests to the appropriate service:
- HTTP requests to the Inventory API
- RabbitMQ messages to the Billing API

## Features

- Routes all `/api/movies` requests to the Inventory API
- Processes `/api/billing` POST requests and sends them to the Billing API via RabbitMQ
- Works even when the Billing API is not running

## Setup

1. Install dependencies:
```
pip install -r requirements.txt
```

2. Configure environment variables:
- Create a `.env` file in the root directory with the following variables:
  ```
  INVENTORY_API_URL=http://localhost:8080
  RABBITMQ_HOST=localhost
  RABBITMQ_QUEUE=billing_queue
  API_GATEWAY_PORT=5000
  ```

3. Run the API Gateway:
```
python run.py
```

## Endpoints

- `GET /api/movies`: Routes to Inventory API to get all movies
- `GET /api/movies?title=[name]`: Routes to Inventory API to search movies by title
- `POST /api/movies`: Routes to Inventory API to create a new movie
- `DELETE /api/movies`: Routes to Inventory API to delete all movies
- `GET /api/movies/:id`: Routes to Inventory API to get a specific movie
- `PUT /api/movies/:id`: Routes to Inventory API to update a specific movie
- `DELETE /api/movies/:id`: Routes to Inventory API to delete a specific movie
- `POST /api/billing`: Sends a message to the Billing API via RabbitMQ