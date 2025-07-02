import json
import pika
import sys
import time
import logging
from app import create_app
from app.models import db, Order
from app.config import Config

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

def process_message(ch, method, properties, body):
    """
    Process a message from RabbitMQ.
    
    Args:
        ch: Channel
        method: Method
        properties: Properties
        body: Message body
    """
    try:
        # Parse the message body
        message = json.loads(body.decode('utf-8'))
        logger.info(f"Received message: {message}")
        
        # Create a new order
        order = Order.from_dict(message)
        
        # Add the order to the database
        with app.app_context():
            db.session.add(order)
            db.session.commit()
            logger.info(f"Created order: {order.to_dict()}")
        
        # Acknowledge the message
        ch.basic_ack(delivery_tag=method.delivery_tag)
        
    except json.JSONDecodeError:
        logger.error(f"Failed to parse message body: {body}")
        # Negative acknowledgment
        ch.basic_nack(delivery_tag=method.delivery_tag, requeue=False)
        
    except Exception as e:
        logger.error(f"Error processing message: {e}")
        # Negative acknowledgment and requeue
        ch.basic_nack(delivery_tag=method.delivery_tag, requeue=True)

def setup_rabbitmq_connection():
    """
    Set up a connection to RabbitMQ.
    
    Returns:
        connection: Pika connection
        channel: Pika channel
    """
    config = Config()
    
    # Set up RabbitMQ connection parameters
    credentials = pika.PlainCredentials(config.RABBITMQ_USER, config.RABBITMQ_PASSWORD)
    parameters = pika.ConnectionParameters(
        host=config.RABBITMQ_HOST,
        port=config.RABBITMQ_PORT,
        credentials=credentials,
        heartbeat=600,
        blocked_connection_timeout=300
    )
    
    # Connect to RabbitMQ
    connection = pika.BlockingConnection(parameters)
    channel = connection.channel()
    
    # Declare the queue
    channel.queue_declare(queue=config.RABBITMQ_QUEUE, durable=True)
    
    # Set QoS prefetch count to 1 to evenly distribute messages
    channel.basic_qos(prefetch_count=1)
    
    return connection, channel

def start_consumer():
    """Start the RabbitMQ consumer."""
    connection = None
    
    try:
        # Initialize Flask app for database access
        global app
        app = create_app()
        
        while True:
            try:
                # Set up RabbitMQ connection
                connection, channel = setup_rabbitmq_connection()
                logger.info("Connected to RabbitMQ")
                
                # Set up consumer
                channel.basic_consume(
                    queue=Config().RABBITMQ_QUEUE,
                    on_message_callback=process_message
                )
                
                logger.info(f"Started consuming from {Config().RABBITMQ_QUEUE}")
                
                # Start consuming
                channel.start_consuming()
                
            except pika.exceptions.AMQPConnectionError:
                logger.error("Lost connection to RabbitMQ, retrying in 5 seconds...")
                time.sleep(5)
                
            except pika.exceptions.ChannelClosedByBroker:
                logger.error("Channel closed by broker, retrying in 5 seconds...")
                time.sleep(5)
                
            except KeyboardInterrupt:
                logger.info("Interrupted by user, shutting down...")
                if connection and connection.is_open:
                    connection.close()
                sys.exit(0)
    
    except KeyboardInterrupt:
        logger.info("Interrupted by user, shutting down...")
        if connection and connection.is_open:
            connection.close()
        sys.exit(0)

if __name__ == '__main__':
    start_consumer()