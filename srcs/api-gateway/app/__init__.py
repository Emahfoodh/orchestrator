from flask import Flask
from flask_cors import CORS
from app.config import Config

def create_app():
    app = Flask(__name__)
    CORS(app)
    
    # Register routes
    from app.routes import inventory_proxy, billing_proxy
    app.register_blueprint(inventory_proxy.bp)
    app.register_blueprint(billing_proxy.bp)
    
    return app