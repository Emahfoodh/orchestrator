from app import create_app, db
from app.config import Config

app = create_app()

if __name__ == '__main__':
    with app.app_context():
        db.create_all()
    
    # Use configuration from environment variables
    app.run(
        host=Config.HOST,
        port=Config.PORT,
        debug=Config.DEBUG
    )