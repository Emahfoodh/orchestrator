Flask Billing API
===============

A billing service that consumes messages from RabbitMQ and stores order information in a PostgreSQL database.

## Project Structure

```
flask_billing/
├── app/
│   ├── __init__.py
│   ├── routes/
│   │   ├── __init__.py
│   │   └── billing.py
│   ├── models.py
│   └── config.py
├── run.py
├── consumer.py
├── requirements.txt
└── README.md
```

## Installation

1. Clone the repository
2. Create a virtual environment:
```bash
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
```
3. Install dependencies:
```bash
pip install -r requirements.txt
```
4. Create PostgreSQL database:
```bash
# Using Docker
docker exec -it inventory psql -U postgres
CREATE DATABASE billing_db;
\q
python run.py
```
5. Run the RabbitMQ consumer:
```bash
docker run -d --name rabbitmq -p 5672:5672 -p 15672:15672 rabbitmq:3-management
python consumer.py
```

## API Description

The Billing API consumes messages from the "billing_queue" in RabbitMQ. Messages should be in JSON format:
```json
{ "user_id": "3", "number_of_items": "5", "total_amount": "180" }
```

The API processes these messages and stores them in the "orders" table in the "billing_db" database.

## Testing

To test the API:
1. Publish a message to the "billing_queue" in RabbitMQ
2. With the consumer running, the message will be processed immediately
3. Without the consumer running, messages will be queued
4. When the consumer is started again, all queued messages will be processed