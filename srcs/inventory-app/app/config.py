import os
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

class Config:
    # Database configuration from environment variables
    SQLALCHEMY_DATABASE_URI = os.getenv('DATABASE_URI', 'postgresql://postgres:postgres@localhost:5432/movies_db')
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    
    # Debug mode from environment
    DEBUG = os.getenv('DEBUG', 'False').lower() in ['true', '1', 'yes']
    
    # Server configuration
    HOST = os.getenv('HOST', '0.0.0.0')
    PORT = int(os.getenv('PORT', 8080))
