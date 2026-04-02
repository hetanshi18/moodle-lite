from datetime import datetime
from app import db, login_manager
from flask_login import UserMixin


@login_manager.user_loader
def load_user(user_id):
    return User.query.get(int(user_id))


class User(db.Model, UserMixin):
    __tablename__ = "users"

    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(120), nullable=False)
    email = db.Column(db.String(150), unique=True, nullable=False, index=True)
    password_hash = db.Column(db.String(256), nullable=False)
    role = db.Column(db.String(20), nullable=False, default="student")  # student | instructor
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    # Relationships
    courses_taught = db.relationship("Course", backref="instructor", lazy=True, foreign_keys="Course.instructor_id")
    enrollments = db.relationship("Enrollment", backref="student", lazy=True, foreign_keys="Enrollment.student_id")
    submissions = db.relationship("Submission", backref="student", lazy=True, foreign_keys="Submission.student_id")
    uploaded_content = db.relationship("Content", backref="uploader", lazy=True, foreign_keys="Content.uploaded_by")

    def __repr__(self):
        return f"<User {self.email} [{self.role}]>"


class Course(db.Model):
    __tablename__ = "courses"

    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(200), nullable=False)
    description = db.Column(db.Text, nullable=True)
    enroll_code = db.Column(db.String(20), unique=True, nullable=False, index=True)
    instructor_id = db.Column(db.Integer, db.ForeignKey("users.id"), nullable=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    # Relationships
    enrollments = db.relationship("Enrollment", backref="course", lazy=True, cascade="all, delete-orphan")
    content_items = db.relationship("Content", backref="course", lazy=True, cascade="all, delete-orphan")
    assignments = db.relationship("Assignment", backref="course", lazy=True, cascade="all, delete-orphan")

    def __repr__(self):
        return f"<Course {self.name}>"


class Enrollment(db.Model):
    __tablename__ = "enrollments"

    id = db.Column(db.Integer, primary_key=True)
    student_id = db.Column(db.Integer, db.ForeignKey("users.id"), nullable=False)
    course_id = db.Column(db.Integer, db.ForeignKey("courses.id"), nullable=False)
    enrolled_at = db.Column(db.DateTime, default=datetime.utcnow)

    __table_args__ = (
        db.UniqueConstraint("student_id", "course_id", name="uq_enrollment"),
    )

    def __repr__(self):
        return f"<Enrollment student={self.student_id} course={self.course_id}>"


class Content(db.Model):
    __tablename__ = "content"

    id = db.Column(db.Integer, primary_key=True)
    title = db.Column(db.String(200), nullable=False)
    filename = db.Column(db.String(300), nullable=False)
    original_filename = db.Column(db.String(300), nullable=False)
    course_id = db.Column(db.Integer, db.ForeignKey("courses.id"), nullable=False)
    uploaded_by = db.Column(db.Integer, db.ForeignKey("users.id"), nullable=False)
    uploaded_at = db.Column(db.DateTime, default=datetime.utcnow)

    def __repr__(self):
        return f"<Content {self.title}>"


class Assignment(db.Model):
    __tablename__ = "assignments"

    id = db.Column(db.Integer, primary_key=True)
    title = db.Column(db.String(200), nullable=False)
    description = db.Column(db.Text, nullable=True)
    due_date = db.Column(db.DateTime, nullable=True)
    course_id = db.Column(db.Integer, db.ForeignKey("courses.id"), nullable=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    # Relationships
    submissions = db.relationship("Submission", backref="assignment", lazy=True, cascade="all, delete-orphan")

    def __repr__(self):
        return f"<Assignment {self.title}>"


class Submission(db.Model):
    __tablename__ = "submissions"

    id = db.Column(db.Integer, primary_key=True)
    filename = db.Column(db.String(300), nullable=False)
    original_filename = db.Column(db.String(300), nullable=False)
    student_id = db.Column(db.Integer, db.ForeignKey("users.id"), nullable=False)
    assignment_id = db.Column(db.Integer, db.ForeignKey("assignments.id"), nullable=False)
    submitted_at = db.Column(db.DateTime, default=datetime.utcnow)

    def __repr__(self):
        return f"<Submission student={self.student_id} assignment={self.assignment_id}>"
