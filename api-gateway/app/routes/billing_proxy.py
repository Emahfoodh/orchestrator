import json
import pika
from flask import Blueprint, request, jsonify
from app.config import Config

bp = Blueprint('billing_proxy', __name__)

@bp.route('/api/billing', methods=['POST'])
def proxy_billing():
    """
    Handle POST requests to /api/billing and send them to RabbitMQ
    """
    try:
        # Get the request data
        billing_data = request.get_json()
        
        if not billing_data:
            return jsonify({"error": "No data provided"}), 400
        
        # Validate required fields
        required_fields = ['user_id', 'number_of_items', 'total_amount']
        for field in required_fields:
            if field not in billing_data:
                return jsonify({"error": f"Missing required field: {field}"}), 400
        
        # Send the data to RabbitMQ
        send_to_rabbitmq(billing_data)
        
        return jsonify({"message": "Message posted to billing queue"}), 200
        
    except Exception as e:
        return jsonify({"error": str(e)}), 500

def send_to_rabbitmq(data):
    """
    Send data to RabbitMQ queue
    """
    try:
        # Convert the data to a JSON string
        message = json.dumps(data)
        
        # Connect to RabbitMQ
        connection = pika.BlockingConnection(
            pika.ConnectionParameters(host=Config.RABBITMQ_HOST)
        )
        channel = connection.channel()
        
        # Declare the queue (creates it if it doesn't exist)
        channel.queue_declare(queue=Config.RABBITMQ_QUEUE, durable=True)
        
        # Publish the message
        channel.basic_publish(
            exchange='',
            routing_key=Config.RABBITMQ_QUEUE,
            body=message,
            properties=pika.BasicProperties(
                delivery_mode=2,  # Make message persistent
            )
        )
        
        # Close the connection
        connection.close()
        
    except Exception as e:
        raise Exception(f"Failed to send message to RabbitMQ: {str(e)}")