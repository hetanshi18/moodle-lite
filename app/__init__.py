import os
from flask import Flask
from flask_sqlalchemy import SQLAlchemy
from flask_migrate import Migrate
from flask_bcrypt import Bcrypt
from flask_login import LoginManager
from dotenv import load_dotenv

load_dotenv()

db = SQLAlchemy()
migrate = Migrate()
bcrypt = Bcrypt()
login_manager = LoginManager()
login_manager.login_view = "auth.login"
login_manager.login_message = "Please log in to access this page."
login_manager.login_message_category = "warning"


def create_app():
    app = Flask(__name__)

    env = os.environ.get("FLASK_ENV", "development")
    from app.config import config_map
    app.config.from_object(config_map.get(env, config_map["default"]))

    # Ensure upload folder exists
    os.makedirs(app.config["UPLOAD_FOLDER"], exist_ok=True)

    # Init extensions
    db.init_app(app)
    migrate.init_app(app, db)
    bcrypt.init_app(app)
    login_manager.init_app(app)

    # Register blueprints
    from app.auth.routes import auth_bp
    from app.courses.routes import courses_bp
    from app.content.routes import content_bp
    from app.assignments.routes import assignments_bp
    from app.main.routes import main_bp

    app.register_blueprint(auth_bp, url_prefix="/auth")
    app.register_blueprint(courses_bp, url_prefix="/courses")
    app.register_blueprint(content_bp, url_prefix="/content")
    app.register_blueprint(assignments_bp, url_prefix="/assignments")
    app.register_blueprint(main_bp)

    # Import models so Migrate sees them
    from app import models  # noqa: F401

    return app
