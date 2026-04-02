from flask import Blueprint, render_template, redirect, url_for, flash, request
from flask_login import login_user, logout_user, login_required, current_user
from app import db, bcrypt
from app.models import User

auth_bp = Blueprint("auth", __name__, template_folder="../templates/auth")


@auth_bp.route("/register", methods=["GET", "POST"])
def register():
    if current_user.is_authenticated:
        return redirect(url_for("main.index"))
    if request.method == "POST":
        name = request.form.get("name", "").strip()
        email = request.form.get("email", "").strip().lower()
        password = request.form.get("password", "")
        confirm = request.form.get("confirm_password", "")
        role = request.form.get("role", "student")

        if not name or not email or not password:
            flash("All fields are required.", "danger")
            return redirect(url_for("auth.register"))
        if password != confirm:
            flash("Passwords do not match.", "danger")
            return redirect(url_for("auth.register"))
        if User.query.filter_by(email=email).first():
            flash("An account with that email already exists.", "danger")
            return redirect(url_for("auth.register"))
        if role not in ("student", "instructor"):
            role = "student"

        pw_hash = bcrypt.generate_password_hash(password).decode("utf-8")
        user = User(name=name, email=email, password_hash=pw_hash, role=role)
        db.session.add(user)
        db.session.commit()
        flash("Account created! Please log in.", "success")
        return redirect(url_for("auth.login"))
    return render_template("auth/register.html")


@auth_bp.route("/login", methods=["GET", "POST"])
def login():
    if current_user.is_authenticated:
        return redirect(url_for("main.index"))
    if request.method == "POST":
        email = request.form.get("email", "").strip().lower()
        password = request.form.get("password", "")
        user = User.query.filter_by(email=email).first()
        if user and bcrypt.check_password_hash(user.password_hash, password):
            login_user(user, remember=request.form.get("remember") == "on")
            next_page = request.args.get("next")
            flash(f"Welcome back, {user.name}!", "success")
            return redirect(next_page or url_for("main.index"))
        flash("Invalid email or password.", "danger")
    return render_template("auth/login.html")


@auth_bp.route("/logout")
@login_required
def logout():
    logout_user()
    flash("You have been logged out.", "info")
    return redirect(url_for("auth.login"))
