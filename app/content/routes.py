import os
import uuid
from flask import Blueprint, render_template, redirect, url_for, flash, request, send_from_directory, abort, current_app
from flask_login import login_required, current_user
from app import db
from app.models import Course, Enrollment, Content

content_bp = Blueprint("content", __name__, template_folder="../templates/content")


def allowed_file(filename):
    allowed = current_app.config.get("ALLOWED_EXTENSIONS", set())
    return "." in filename and filename.rsplit(".", 1)[1].lower() in allowed


@content_bp.route("/upload/<int:course_id>", methods=["GET", "POST"])
@login_required
def upload(course_id):
    course = Course.query.get_or_404(course_id)
    if current_user.role != "instructor" or course.instructor_id != current_user.id:
        abort(403)
    if request.method == "POST":
        title = request.form.get("title", "").strip()
        file = request.files.get("file")
        if not title or not file or file.filename == "":
            flash("Title and file are required.", "danger")
            return redirect(url_for("content.upload", course_id=course_id))
        if not allowed_file(file.filename):
            flash("File type not allowed.", "danger")
            return redirect(url_for("content.upload", course_id=course_id))
        original_name = file.filename
        ext = original_name.rsplit(".", 1)[1].lower()
        stored_name = f"{uuid.uuid4().hex}.{ext}"
        upload_path = current_app.config["UPLOAD_FOLDER"]
        os.makedirs(upload_path, exist_ok=True)
        file.save(os.path.join(upload_path, stored_name))
        content = Content(
            title=title,
            filename=stored_name,
            original_filename=original_name,
            course_id=course_id,
            uploaded_by=current_user.id,
        )
        db.session.add(content)
        db.session.commit()
        flash(f'"{title}" uploaded successfully.', "success")
        return redirect(url_for("courses.view_course", course_id=course_id))
    return render_template("content/upload.html", course=course)


@content_bp.route("/download/<int:content_id>")
@login_required
def download(content_id):
    item = Content.query.get_or_404(content_id)
    # Check access: must be enrolled or be the instructor
    course = item.course
    enrolled = Enrollment.query.filter_by(student_id=current_user.id, course_id=course.id).first()
    is_instructor = (current_user.role == "instructor" and course.instructor_id == current_user.id)
    if not enrolled and not is_instructor:
        abort(403)
    upload_path = current_app.config["UPLOAD_FOLDER"]
    return send_from_directory(upload_path, item.filename, as_attachment=True, download_name=item.original_filename)


@content_bp.route("/delete/<int:content_id>", methods=["POST"])
@login_required
def delete(content_id):
    item = Content.query.get_or_404(content_id)
    course = item.course
    if current_user.role != "instructor" or course.instructor_id != current_user.id:
        abort(403)
    file_path = os.path.join(current_app.config["UPLOAD_FOLDER"], item.filename)
    if os.path.exists(file_path):
        os.remove(file_path)
    db.session.delete(item)
    db.session.commit()
    flash("Content deleted.", "info")
    return redirect(url_for("courses.view_course", course_id=course.id))
