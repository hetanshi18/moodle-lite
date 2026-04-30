import os
import uuid
from datetime import datetime
from flask import Blueprint, render_template, redirect, url_for, flash, request, abort, send_from_directory, current_app
from flask_login import login_required, current_user
from app import db
from app.models import Assignment, Course, Enrollment, Submission


def allowed_file(filename):
    allowed = current_app.config.get("ALLOWED_EXTENSIONS", set())
    return "." in filename and filename.rsplit(".", 1)[1].lower() in allowed

assignments_bp = Blueprint("assignments", __name__, template_folder="../templates/assignments")


@assignments_bp.route("/create/<int:course_id>", methods=["GET", "POST"])
@login_required
def create(course_id):
    course = Course.query.get_or_404(course_id)
    if current_user.role != "instructor" or course.instructor_id != current_user.id:
        abort(403)
    if request.method == "POST":
        title = request.form.get("title", "").strip()
        description = request.form.get("description", "").strip()
        due_date_str = request.form.get("due_date", "")
        if not title:
            flash("Assignment title is required.", "danger")
            return redirect(url_for("assignments.create", course_id=course_id))
        due_date = None
        if due_date_str:
            try:
                due_date = datetime.strptime(due_date_str, "%Y-%m-%dT%H:%M")
            except ValueError:
                flash("Invalid due date format.", "danger")
                return redirect(url_for("assignments.create", course_id=course_id))
        assignment = Assignment(
            title=title,
            description=description,
            due_date=due_date,
            course_id=course_id,
        )
        db.session.add(assignment)
        db.session.commit()
        flash(f'Assignment "{title}" created.', "success")
        return redirect(url_for("courses.view_course", course_id=course_id))
    return render_template("assignments/create.html", course=course)


@assignments_bp.route("/submit/<int:assignment_id>", methods=["GET", "POST"])
@login_required
def submit(assignment_id):
    assignment = Assignment.query.get_or_404(assignment_id)
    course = assignment.course
    if current_user.role != "student":
        abort(403)
    enrolled = Enrollment.query.filter_by(student_id=current_user.id, course_id=course.id).first()
    if not enrolled:
        abort(403)
    existing = Submission.query.filter_by(student_id=current_user.id, assignment_id=assignment_id).first()
    if request.method == "POST":
        file = request.files.get("file")
        if not file or file.filename == "":
            flash("A file is required.", "danger")
            return redirect(url_for("assignments.submit", assignment_id=assignment_id))
        if not allowed_file(file.filename):
            flash("File type not allowed.", "danger")
            return redirect(url_for("assignments.submit", assignment_id=assignment_id))
        original_name = file.filename
        ext = original_name.rsplit(".", 1)[1].lower() if "." in original_name else "bin"
        stored_name = f"sub_{uuid.uuid4().hex}.{ext}"
        upload_path = current_app.config["UPLOAD_FOLDER"]
        os.makedirs(upload_path, exist_ok=True)
        file.save(os.path.join(upload_path, stored_name))
        if existing:
            # Replace existing submission file
            old_path = os.path.join(upload_path, existing.filename)
            if os.path.exists(old_path):
                os.remove(old_path)
            existing.filename = stored_name
            existing.original_filename = original_name
            existing.submitted_at = datetime.utcnow()
            db.session.commit()
            flash("Submission updated.", "success")
        else:
            submission = Submission(
                filename=stored_name,
                original_filename=original_name,
                student_id=current_user.id,
                assignment_id=assignment_id,
            )
            db.session.add(submission)
            db.session.commit()
            flash("Assignment submitted successfully!", "success")
        return redirect(url_for("courses.view_course", course_id=course.id))
    return render_template("assignments/submit.html", assignment=assignment, existing=existing)


@assignments_bp.route("/submissions/<int:assignment_id>")
@login_required
def view_submissions(assignment_id):
    assignment = Assignment.query.get_or_404(assignment_id)
    course = assignment.course
    if current_user.role != "instructor" or course.instructor_id != current_user.id:
        abort(403)
    submissions = Submission.query.filter_by(assignment_id=assignment_id).order_by(Submission.submitted_at.desc()).all()
    return render_template("assignments/view_submissions.html", assignment=assignment, submissions=submissions, course=course)


@assignments_bp.route("/download-submission/<int:submission_id>")
@login_required
def download_submission(submission_id):
    submission = Submission.query.get_or_404(submission_id)
    course = submission.assignment.course
    is_instructor = current_user.role == "instructor" and course.instructor_id == current_user.id
    is_own = submission.student_id == current_user.id
    if not is_instructor and not is_own:
        abort(403)
    upload_path = current_app.config["UPLOAD_FOLDER"]
    return send_from_directory(upload_path, submission.filename, as_attachment=True, download_name=submission.original_filename)
