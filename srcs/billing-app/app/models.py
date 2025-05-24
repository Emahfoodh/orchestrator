from flask_sqlalchemy import SQLAlchemy

db = SQLAlchemy()

class Order(db.Model):
    """Order model for storing order related details."""
    __tablename__ = 'orders'

    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.String(50), nullable=False)
    number_of_items = db.Column(db.Integer, nullable=False)
    total_amount = db.Column(db.Float, nullable=False)

    def __init__(self, user_id, number_of_items, total_amount):
        self.user_id = user_id
        self.number_of_items = number_of_items
        self.total_amount = total_amount

    def to_dict(self):
        """Convert the model instance to a dictionary."""
        return {
            'id': self.id,
            'user_id': self.user_id,
            'number_of_items': self.number_of_items,
            'total_amount': self.total_amount
        }
    
    @staticmethod
    def from_dict(data):
        """Create a model instance from dictionary."""
        return Order(
            user_id=data.get('user_id'),
            number_of_items=int(data.get('number_of_items', 0)),
            total_amount=float(data.get('total_amount', 0.0))
        )