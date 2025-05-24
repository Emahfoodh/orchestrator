import os
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

class Config:
    """Base configuration class."""
    DEBUG = os.getenv('DEBUG', 'False').lower() in ('true', 't', '1')
    SQLALCHEMY_DATABASE_URI = os.getenv('DATABASE_URI', 'postgresql://postgres:password@localhost:5432/movies_db')
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    PORT = int(os.getenv('PORT', 8080))
    HOST = os.getenv('HOST', 'localhost')