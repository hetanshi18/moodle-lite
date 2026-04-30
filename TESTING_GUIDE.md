# MoodLite LMS - Testing Guide

This guide provides step-by-step instructions to test all features and functionalities of the MoodLite Learning Management System.

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Account Setup](#account-setup)
3. [Instructor Workflow](#instructor-workflow)
4. [Student Workflow](#student-workflow)
5. [End-to-End Scenarios](#end-to-end-scenarios)
6. [Common Issues & Troubleshooting](#common-issues--troubleshooting)

---

## Prerequisites

- MoodLite application running on `http://localhost:5000`
- Web browser (Chrome, Firefox, Safari, or Edge)
- Test files ready (PDF, Word, or text files for uploads)

---

## Account Setup

### 1. Create an Instructor Account

1. Go to `http://localhost:5000`
2. Click **"Register"** or navigate to the registration page
3. Fill in the form:
   - **Name**: `Test Instructor`
   - **Email**: `instructor@test.com`
   - **Password**: `securepass123`
   - **Confirm Password**: `securepass123`
   - **Role**: Select **"Instructor"** from dropdown
4. Click **Register**
5. You should see: _"Account created! Please log in."_
6. Click **Login** and use the credentials above

### 2. Create a Student Account

1. Log out (click **Logout** in top navigation)
2. Click **Register** again
3. Fill in the form:
   - **Name**: `Test Student`
   - **Email**: `student@test.com`
   - **Password**: `studentpass123`
   - **Confirm Password**: `studentpass123`
   - **Role**: Select **"Student"** from dropdown
4. Click **Register**
5. You now have both accounts ready

---

## Instructor Workflow

### Step 1: Login as Instructor

1. Go to `http://localhost:5000/login`
2. Enter:
   - **Email**: `instructor@test.com`
   - **Password**: `securepass123`
3. Click **Login**
4. You should see the **Instructor Dashboard** with "Create New Course" button

### Step 2: Create a Course

1. Click **"Create New Course"** button
2. Fill in the form:
   - **Course Name**: `Introduction to Python Programming`
   - **Description**: `Learn Python basics from fundamentals to advanced concepts`
3. Click **Create Course**
4. You will see a success message with the **Enroll Code** (e.g., `A1B2C3D4`)
   - **Important**: Copy this code - students will use it to enroll
5. You should be redirected to the course view page

### Step 3: Upload Course Content

1. On the course page, find the **"Upload Content"** button
2. Click it
3. Fill in:
   - **Title**: `Python Basics - Chapter 1`
   - **File**: Upload a test file (PDF, Word, or text file)
4. Click **Upload**
5. Success message: _"Python Basics - Chapter 1 uploaded successfully."_
6. Return to course page and verify the content appears in the **Course Materials** section

**Optional**: Upload additional content files:
   - `Python Variables and Data Types.pdf`
   - `Control Flow and Loops.pdf`
   - `Functions and Modules.pdf`

### Step 4: Create an Assignment

1. On the course page, find the **"Create Assignment"** button
2. Fill in:
   - **Assignment Title**: `Python Assignment 1 - Hello World Program`
   - **Description**: `Write a program that prints 'Hello, World!' and asks for your name`
   - **Due Date**: Select a date 3-5 days in future (optional)
3. Click **Create Assignment**
4. Success message: _"Assignment 'Python Assignment 1...' created."_

**Optional**: Create more assignments:
   - `Assignment 2 - Calculator Program`
   - `Assignment 3 - List Operations`

### Step 5: View Student Submissions

1. On the course page, locate the assignment you created
2. Click **"View Submissions"** button
3. Currently shows: No submissions yet (will populate after students submit)
4. Later, after students submit, you'll see:
   - Student name
   - Submission date/time
   - **Download** button to view their submission

---

## Student Workflow

### Step 1: Login as Student

1. Go to `http://localhost:5000/login`
2. Enter:
   - **Email**: `student@test.com`
   - **Password**: `studentpass123`
3. Click **Login**
4. You should see the **Student Dashboard** with "Enroll in Course" button

### Step 2: Enroll in a Course

1. Click **"Enroll in Course"** button
2. Enter the **Enroll Code** from the instructor (e.g., `A1B2C3D4`)
3. Click **Enroll**
4. Success message: _"Successfully enrolled in 'Introduction to Python Programming'!"_
5. Course now appears on your dashboard

### Step 3: View Course Content and Download Materials

1. Click on the course name to enter the course
2. You should see:
   - Course name and description
   - **Course Materials** section with uploaded files
   - **Assignments** section with available assignments
3. Click **Download** next to any course material
4. File should download to your computer
5. Verify you can open and view the downloaded file

### Step 4: Submit an Assignment

1. On the course page, find the assignment (e.g., `Python Assignment 1 - Hello World Program`)
2. Click **"Submit Assignment"** button
3. Click **"Choose File"** and select a test file from your computer
4. Click **Submit**
5. Success message: _"Assignment submitted successfully!"_
6. Return to course page

### Step 5: Update a Submission (Resubmit)

1. Go back to the same assignment
2. Click **"Submit Assignment"** again
3. Select a different file
4. Click **Submit**
5. Success message: _"Submission updated."_
6. Only the latest submission is kept (previous one is replaced)

---

## End-to-End Scenarios

### Scenario 1: Complete Course Workflow

**Setup Phase (Instructor)**
1. Create course: `Data Science Fundamentals`
2. Upload 3 content files: Introduction, Datasets, Visualization
3. Create 2 assignments: Data Analysis Project, Presentation

**Enrollment Phase (Student)**
1. Enroll using the course enroll code
2. Download all 3 content files
3. Review assignment requirements

**Submission Phase (Student)**
1. Submit both assignments
2. Update the first assignment with improved version

**Review Phase (Instructor)**
1. View submissions for both assignments
2. Download student submissions to review

---

### Scenario 2: Multiple Students in One Course

**Setup (Instructor)**
1. Create a course: `Web Development 101`
2. Note the enroll code
3. Create 1 assignment

**Enrollment (Multiple Students)**
1. Create 3 student accounts (in separate browser windows/incognito)
2. Each student enrolls using the same enroll code
3. All students see the same course materials

**Submission Verification (Instructor)**
1. View submissions for the assignment
2. Should see 3 different submissions from 3 students

---

### Scenario 3: Access Control Testing

**Instructor Cannot:**
- ❌ Enroll in courses as a student
- ❌ Submit assignments
- ❌ Download submissions they didn't create

**Student Cannot:**
- ❌ Create courses
- ❌ Upload course content
- ❌ Create assignments
- ❌ View submissions (only instructors can)

**Unauthenticated Users Cannot:**
- ❌ Access any courses, assignments, or content
- ❌ Upload or download files

---

## Common Issues & Troubleshooting

### Issue: "Invalid enroll code"
**Solution**: Make sure you're using the exact enroll code from the instructor's course creation screen. It's case-sensitive and automatically generated.

### Issue: "You are already enrolled in this course"
**Solution**: The student account is already in this course. Use a different student account or create a new one.

### Issue: File upload fails with "File type not allowed"
**Solution**: Check `ALLOWED_EXTENSIONS` in the config. Common supported formats:
- Documents: `.pdf`, `.doc`, `.docx`, `.txt`
- Spreadsheets: `.xlsx`, `.csv`
- Archives: `.zip`, `.tar`

### Issue: Cannot access a course as student
**Solution**: Make sure you're enrolled first. Unenrolled students get a "403 Forbidden" error.

### Issue: Assignment due date not showing
**Solution**: Due date is optional. If not set, no deadline is displayed.

### Issue: File download shows "404 Not Found"
**Solution**: 
1. Make sure the upload folder exists: `/app/uploads`
2. Verify Docker has proper volume mounting for uploads
3. Restart the application

---

## Testing Checklist

### Authentication
- [ ] Register as instructor
- [ ] Register as student
- [ ] Login with correct credentials
- [ ] Login fails with wrong password
- [ ] Logout functionality works

### Instructor Features
- [ ] Create course
- [ ] View generated enroll code
- [ ] Upload course content
- [ ] Download course content
- [ ] Delete course content
- [ ] Create assignment
- [ ] View student submissions
- [ ] Download student submission

### Student Features
- [ ] Enroll in course with code
- [ ] Cannot enroll twice in same course
- [ ] View enrolled courses on dashboard
- [ ] Download course materials
- [ ] Submit assignment
- [ ] Update (resubmit) assignment
- [ ] Cannot view submissions (instructor feature)

### Authorization
- [ ] Instructors cannot submit assignments
- [ ] Students cannot create courses
- [ ] Students cannot upload content
- [ ] Students cannot view other students' submissions
- [ ] Unauthenticated users redirected to login

### UI/UX
- [ ] Flash messages appear for all actions
- [ ] Forms validate input correctly
- [ ] Course dashboard displays correctly
- [ ] Timestamps are accurate
- [ ] File names preserved when downloading

---

## Performance Tips for Testing

1. **Use Incognito/Private Browsing** for multiple concurrent sessions
2. **Keep files small** (< 10MB) for faster uploads
3. **Test with various file formats** to ensure compatibility
4. **Clear browser cache** between tests if experiencing issues
5. **Check browser console** (F12) for any JavaScript errors

---

## API & Database Verification

### Check Created Data in Database

If using Docker, you can verify data was created:

```bash
# Access PostgreSQL inside Docker
docker-compose exec postgres psql -U moodlite -d moodlite

# Then run these queries:
\dt                          # List all tables
SELECT * FROM users;         # View all users
SELECT * FROM courses;       # View all courses
SELECT * FROM enrollments;   # View all enrollments
SELECT * FROM assignments;   # View all assignments
SELECT * FROM submissions;   # View all submissions
SELECT * FROM content;       # View all content
```

---

## Success Criteria

✅ All features are accessible
✅ Data persists across sessions
✅ Authorization rules are enforced
✅ File uploads and downloads work correctly
✅ No unhandled errors in browser console
✅ UI is responsive and user-friendly
✅ Flash messages provide clear feedback

---

## Additional Resources

- See [README.md](README.md) for deployment options
- See [SETUP.md](SETUP.md) for infrastructure setup
- See [MASTER_GUIDE.md](MASTER_GUIDE.md) for full documentation

---

**Happy Testing! 🚀**
