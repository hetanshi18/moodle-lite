import secrets
from flask import Blueprint, render_template, redirect, url_for, flash, request, abort
from flask_login import login_required, current_user
from app import db
from app.models import Course, Enrollment, Content, Assignment

courses_bp = Blueprint("courses", __name__, template_folder="../templates/courses")


@courses_bp.route("/")
@login_required
def dashboard():
    if current_user.role == "instructor":
        courses = Course.query.filter_by(instructor_id=current_user.id).all()
    else:
        enrollments = Enrollment.query.filter_by(student_id=current_user.id).all()
        courses = [e.course for e in enrollments]
    return render_template("courses/dashboard.html", courses=courses)


@courses_bp.route("/create", methods=["GET", "POST"])
@login_required
def create():
    if current_user.role != "instructor":
        abort(403)
    if request.method == "POST":
        name = request.form.get("name", "").strip()
        description = request.form.get("description", "").strip()
        if not name:
            flash("Course name is required.", "danger")
            return redirect(url_for("courses.create"))
        enroll_code = secrets.token_urlsafe(6).upper()
        # Ensure unique
        while Course.query.filter_by(enroll_code=enroll_code).first():
            enroll_code = secrets.token_urlsafe(6).upper()
        course = Course(
            name=name,
            description=description,
            enroll_code=enroll_code,
            instructor_id=current_user.id,
        )
        db.session.add(course)
        db.session.commit()
        flash(f'Course "{name}" created! Enroll code: {enroll_code}', "success")
        return redirect(url_for("courses.view_course", course_id=course.id))
    return render_template("courses/create.html")


@courses_bp.route("/enroll", methods=["GET", "POST"])
@login_required
def enroll():
    if current_user.role != "student":
        abort(403)
    if request.method == "POST":
        code = request.form.get("enroll_code", "").strip().upper()
        course = Course.query.filter_by(enroll_code=code).first()
        if not course:
            flash("Invalid enroll code.", "danger")
            return redirect(url_for("courses.enroll"))
        existing = Enrollment.query.filter_by(student_id=current_user.id, course_id=course.id).first()
        if existing:
            flash("You are already enrolled in this course.", "warning")
            return redirect(url_for("courses.view_course", course_id=course.id))
        enrollment = Enrollment(student_id=current_user.id, course_id=course.id)
        db.session.add(enrollment)
        db.session.commit()
        flash(f'Successfully enrolled in "{course.name}"!', "success")
        return redirect(url_for("courses.view_course", course_id=course.id))
    return render_template("courses/enroll.html")


@courses_bp.route("/<int:course_id>")
@login_required
def view_course(course_id):
    course = Course.query.get_or_404(course_id)
    is_instructor = (current_user.role == "instructor" and course.instructor_id == current_user.id)
    is_enrolled = Enrollment.query.filter_by(student_id=current_user.id, course_id=course_id).first() is not None
    if not is_instructor and not is_enrolled:
        abort(403)
    content_items = Content.query.filter_by(course_id=course_id).order_by(Content.uploaded_at.desc()).all()
    assignments = Assignment.query.filter_by(course_id=course_id).order_by(Assignment.due_date.asc()).all()
    enrollments_count = Enrollment.query.filter_by(course_id=course_id).count()
    return render_template(
        "courses/view.html",
        course=course,
        is_instructor=is_instructor,
        content_items=content_items,
        assignments=assignments,
        enrollments_count=enrollments_count,
    )
