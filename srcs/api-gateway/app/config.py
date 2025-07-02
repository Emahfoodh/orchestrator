import os
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

# Configuration settings
class Config:
    INVENTORY_API_URL = os.getenv('INVENTORY_API_URL', 'http://localhost:8080')
    RABBITMQ_HOST = os.getenv('RABBITMQ_HOST', 'localhost')
    RABBITMQ_QUEUE = os.getenv('RABBITMQ_QUEUE', 'billing_queue')
    API_GATEWAY_PORT = int(os.getenv('API_GATEWAY_PORT', 5000))
    DEBUG = os.getenv('DEBUG', 'False').lower() in ['true', '1', 'yes']
    # Server configuration
    HOST = os.getenv('HOST', '0.0.0.0')
    PORT = int(os.getenv('API_GATEWAY_PORT', 5000))