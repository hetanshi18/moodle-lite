from flask import Blueprint, render_template, redirect, url_for
from flask_login import current_user, login_required

main_bp = Blueprint("main", __name__)


@main_bp.route("/")
def index():
    if current_user.is_authenticated:
        return redirect(url_for("courses.dashboard"))
    return render_template("index.html")


@main_bp.route("/health")
def health():
    return {"status": "ok"}, 200
