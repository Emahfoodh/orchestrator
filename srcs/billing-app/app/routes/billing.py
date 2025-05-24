from flask import Blueprint, jsonify
from app.models import db, Order

# Create a blueprint for billing routes
billing_bp = Blueprint('billing', __name__)

@billing_bp.route('/orders', methods=['GET'])
def get_orders():
    """
    Get all orders.
    
    GET /api/orders
    """
    orders = Order.query.all()
    return jsonify([order.to_dict() for order in orders]), 200

@billing_bp.route('/orders/<int:id>', methods=['GET'])
def get_order(id):
    """
    Get a specific order by ID.
    
    GET /api/orders/:id
    """
    order = Order.query.get_or_404(id)
    return jsonify(order.to_dict()), 200

@billing_bp.route('/health', methods=['GET'])
def health_check():
    """
    Health check endpoint.
    
    GET /api/health
    """
    return jsonify({"status": "ok", "message": "Billing service is running"}), 200