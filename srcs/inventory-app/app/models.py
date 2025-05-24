from flask_sqlalchemy import SQLAlchemy

db = SQLAlchemy()

class Movie(db.Model):
    """Movie model for storing movie related details."""
    __tablename__ = 'movies'

    id = db.Column(db.Integer, primary_key=True)
    title = db.Column(db.String(255), nullable=False)
    description = db.Column(db.Text, nullable=True)

    def __init__(self, title, description=None):
        self.title = title
        self.description = description

    def to_dict(self):
        """Convert the model instance to a dictionary."""
        return {
            'id': self.id,
            'title': self.title,
            'description': self.description
        }
    
    @staticmethod
    def from_dict(data):
        """Create a model instance from dictionary."""
        return Movie(
            title=data.get('title'),
            description=data.get('description')
        )  