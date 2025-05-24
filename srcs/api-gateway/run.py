from app import create_app
from app.config import Config

app = create_app()

if __name__ == '__main__':
    print(f"Starting API Gateway on port {Config.API_GATEWAY_PORT}")
    print(f"Routing inventory requests to: {Config.INVENTORY_API_URL}")
    print(f"Routing billing requests to RabbitMQ queue: {Config.RABBITMQ_QUEUE}")
    
    app.run(host='0.0.0.0', port=Config.API_GATEWAY_PORT, debug=True)