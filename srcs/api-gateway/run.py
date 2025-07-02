from app import create_app
from app.config import Config

app = create_app()

if __name__ == '__main__':
    # Use configuration from environment variables
    app.run(
        host=Config.HOST,
        port=Config.PORT,
        debug=Config.DEBUG
    )