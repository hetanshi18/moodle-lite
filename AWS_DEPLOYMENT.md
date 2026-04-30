# MoodLite AWS Deployment Guide

Complete step-by-step guide to deploy MoodLite on AWS using **EC2 (free tier)**, **RDS PostgreSQL**, and **S3** for file uploads.

---

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [AWS Account Setup](#aws-account-setup)
3. [Create RDS PostgreSQL Database](#create-rds-postgresql-database)
4. [Create S3 Bucket for Uploads](#create-s3-bucket-for-uploads)
5. [Create IAM User for App](#create-iam-user-for-app)
6. [Modify Application for S3](#modify-application-for-s3)
7. [Push Docker Image to ECR](#push-docker-image-to-ecr)
8. [Launch EC2 Instance](#launch-ec2-instance)
9. [Deploy Application on EC2](#deploy-application-on-ec2)
10. [Setup Custom Domain & HTTPS](#setup-custom-domain--https)
11. [Monitoring & Maintenance](#monitoring--maintenance)

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                        AWS Cloud                             │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌──────────────────┐                                        │
│  │   You            │                                        │
│  │ (any location)   │                                        │
│  └────────┬─────────┘                                        │
│           │ HTTPS                                            │
│           ▼                                                   │
│  ┌─────────────────────────────┐                             │
│  │    EC2 Instance (t2.micro)  │                             │
│  │  - Docker Container         │                             │
│  │  - Flask Application        │                             │
│  │  - Gunicorn Server          │                             │
│  └──────┬──────────────────────┘                             │
│         │                                                     │
│    ┌────┴────────────┬──────────────────┐                    │
│    │                 │                  │                    │
│    ▼                 ▼                  ▼                     │
│  ┌──────────┐  ┌─────────────┐  ┌──────────────┐            │
│  │ RDS PostgreSQL  │  │ S3 Bucket   │  │ CloudWatch  │            │
│  │ Database  │  │  Uploads    │  │ Logs & Metrics  │            │
│  └──────────┘  └─────────────┘  └──────────────┘            │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

**Services Used:**
- **EC2**: Application server (free tier: t2.micro)
- **RDS**: Managed PostgreSQL database
- **S3**: File storage for user uploads
- **IAM**: Access control
- **CloudWatch**: Logs and monitoring
- **Route 53**: DNS (optional, for custom domain)
- **ACM**: SSL/TLS certificates (free)

**Estimated Cost (First Year):**
- EC2: FREE (t2.micro free tier)
- RDS: ~$10-15/month (if not in free tier) or FREE (if eligible)
- S3: FREE (up to 5GB storage)
- Total: FREE to minimal cost

---

## AWS Account Setup

### 1. Create AWS Account

1. Go to [aws.amazon.com](https://aws.amazon.com)
2. Click **"Create an AWS Account"**
3. Follow the sign-up process
4. Verify your email and add payment method
5. Wait for account activation (usually instant)

### 2. Access AWS Console

1. Sign in to [AWS Management Console](https://console.aws.amazon.com)
2. Select region: **us-east-1** (free tier available)
   - Click region dropdown (top right) → select "N. Virginia" or "us-east-1"

### 3. Configure AWS CLI (on your local machine)

```bash
# Install AWS CLI v2
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Verify installation
aws --version

# Configure credentials
aws configure
# When prompted:
# AWS Access Key ID: [you'll create this next]
# AWS Secret Access Key: [you'll create this next]
# Default region name: us-east-1
# Default output format: json
```

---

## Create RDS PostgreSQL Database

### 1. Navigate to RDS

1. Go to [AWS RDS Console](https://console.aws.amazon.com/rds)
2. Click **"Create database"**

### 2. Database Configuration

Fill in the following:

| Field | Value |
|-------|-------|
| Engine | PostgreSQL |
| Version | PostgreSQL 15.x |
| Templates | Free tier |
| DB Instance ID | `moodlite-db-prod` |
| Master Username | `moodliteadmin` |
| Master Password | `<strong-password>` (save this!) |
| Database Name | `moodlite` |
| Storage | 20 GB (free tier) |

### 3. Network Settings

- **Publicly Accessible**: Yes
- **VPC**: default
- **DB Subnet Group**: Create new (default name is fine)
- **Security Group**: Create new named `moodlite-db-sg`

### 4. Backup & Maintenance

- **Backup retention**: 7 days
- **Enable encryption**: Yes (default)
- **Enable multi-AZ**: No (for cost savings)

### 5. Create Database

Click **"Create database"** and wait 5-10 minutes for creation.

### 6. Get Database Connection Details

Once created:
1. Click on the database instance
2. Copy the **Endpoint** (e.g., `moodlite-db-prod.xxxx.us-east-1.rds.amazonaws.com`)
3. Note the port: **5432** (default)

**Save this in a safe place:**
```
DATABASE_URL=postgresql://moodliteadmin:<password>@moodlite-db-prod.xxxx.us-east-1.rds.amazonaws.com:5432/moodlite
```

### 7. Allow Database Access from EC2

This will be configured after EC2 is created. For now, note the security group name: `moodlite-db-sg`

---

## Create S3 Bucket for Uploads

### 1. Navigate to S3

1. Go to [AWS S3 Console](https://console.aws.amazon.com/s3)
2. Click **"Create bucket"**

### 2. Bucket Configuration

| Field | Value |
|-------|-------|
| Bucket Name | `moodlite-uploads-<your-username>` (must be globally unique) |
| Region | `us-east-1` |
| Block all public access | ✅ Keep checked (we'll use signed URLs) |

### 3. Create Bucket

Click **"Create bucket"**

### 4. Enable Versioning (optional but recommended)

1. Click on the bucket
2. Go to **Properties** tab
3. Find **Versioning** → **Enable**

---

## Create IAM User for App

### 1. Navigate to IAM

1. Go to [AWS IAM Console](https://console.aws.amazon.com/iam)
2. Click **"Users"** → **"Create user"**

### 2. Create User

- **User Name**: `moodlite-app`
- Click **"Create user"**

### 3. Create Access Key

1. Click on the new user
2. Go to **Security credentials** tab
3. Click **"Create access key"**
4. Select **"Application running on an AWS compute service"**
5. Click **"Create access key"**
6. **Save both key and secret** (you won't see this again!)

```
Access Key ID: AKIAXXXXXXXXXXXXXXXX
Secret Access Key: wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
```

### 4. Attach Policies

1. Go back to the user
2. Click **"Add permissions"** → **"Attach policies directly"**
3. Attach these policies:
   - `AmazonS3FullAccess` (for S3)
   - `AmazonRDSDataFullAccess` (optional, for RDS management)

---

## Modify Application for S3

We need to update the application to use S3 instead of local storage.

### 1. Install boto3 (AWS SDK)

Update `requirements.txt`:

```bash
cat >> requirements.txt << 'EOF'
boto3==1.28.0
botocore==1.31.0
EOF
```

### 2. Update Config

Modify [app/config.py](app/config.py):

```python
import os

class Config:
    SECRET_KEY = os.environ.get("SECRET_KEY", "dev-secret-key-change-in-production")
    SQLALCHEMY_DATABASE_URI = os.environ.get(
        "DATABASE_URL", "sqlite:///moodlite.db"
    )
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    MAX_CONTENT_LENGTH = int(os.environ.get("MAX_CONTENT_LENGTH", 52428800))  # 50 MB
    ALLOWED_EXTENSIONS = {"pdf", "png", "jpg", "jpeg", "gif", "docx", "txt", "mp4", "zip"}
    WTF_CSRF_ENABLED = True
    
    # S3 Configuration
    AWS_ACCESS_KEY_ID = os.environ.get("AWS_ACCESS_KEY_ID")
    AWS_SECRET_ACCESS_KEY = os.environ.get("AWS_SECRET_ACCESS_KEY")
    AWS_S3_BUCKET = os.environ.get("AWS_S3_BUCKET")
    AWS_S3_REGION = os.environ.get("AWS_S3_REGION", "us-east-1")
    USE_S3 = os.environ.get("USE_S3", "false").lower() == "true"
```

### 3. Create S3 Storage Helper

Create new file `app/storage.py`:

```python
import os
import boto3
from flask import current_app

s3_client = None

def get_s3_client():
    global s3_client
    if s3_client is None:
        s3_client = boto3.client(
            's3',
            aws_access_key_id=current_app.config.get('AWS_ACCESS_KEY_ID'),
            aws_secret_access_key=current_app.config.get('AWS_SECRET_ACCESS_KEY'),
            region_name=current_app.config.get('AWS_S3_REGION', 'us-east-1')
        )
    return s3_client

def upload_file_to_s3(file, filename):
    """Upload file to S3 and return the key"""
    try:
        s3 = get_s3_client()
        bucket = current_app.config.get('AWS_S3_BUCKET')
        
        s3.upload_fileobj(
            file,
            bucket,
            filename,
            ExtraArgs={'ContentType': file.content_type}
        )
        return True
    except Exception as e:
        print(f"S3 upload error: {e}")
        return False

def get_download_url(filename, expires=3600):
    """Generate signed URL for downloading file"""
    try:
        s3 = get_s3_client()
        bucket = current_app.config.get('AWS_S3_BUCKET')
        
        url = s3.generate_presigned_url(
            'get_object',
            Params={'Bucket': bucket, 'Key': filename},
            ExpiresIn=expires
        )
        return url
    except Exception as e:
        print(f"S3 URL generation error: {e}")
        return None

def delete_file_from_s3(filename):
    """Delete file from S3"""
    try:
        s3 = get_s3_client()
        bucket = current_app.config.get('AWS_S3_BUCKET')
        s3.delete_object(Bucket=bucket, Key=filename)
        return True
    except Exception as e:
        print(f"S3 delete error: {e}")
        return False
```

### 4. Update Content Upload Route

Modify `app/content/routes.py` (replace upload function):

```python
from app.storage import upload_file_to_s3

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
        stored_name = f"content_{uuid.uuid4().hex}.{ext}"
        
        # Upload to S3
        if current_app.config.get("USE_S3"):
            if not upload_file_to_s3(file, f"content/{stored_name}"):
                flash("Failed to upload file.", "danger")
                return redirect(url_for("content.upload", course_id=course_id))
            stored_name = f"content/{stored_name}"
        else:
            # Local storage fallback
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
```

### 5. Update Download Route

Modify `app/content/routes.py` (replace download function):

```python
from app.storage import get_download_url, delete_file_from_s3

@content_bp.route("/download/<int:content_id>")
@login_required
def download(content_id):
    item = Content.query.get_or_404(content_id)
    course = item.course
    enrolled = Enrollment.query.filter_by(student_id=current_user.id, course_id=course.id).first()
    is_instructor = (current_user.role == "instructor" and course.instructor_id == current_user.id)
    if not enrolled and not is_instructor:
        abort(403)
    
    # Use S3 signed URL or local download
    if current_app.config.get("USE_S3"):
        url = get_download_url(item.filename)
        if url:
            return redirect(url)
        flash("Failed to generate download link.", "danger")
        return redirect(url_for("courses.view_course", course_id=course.id))
    else:
        upload_path = current_app.config["UPLOAD_FOLDER"]
        return send_from_directory(upload_path, item.filename, as_attachment=True, download_name=item.original_filename)
```

### 6. Do the Same for Assignments

Apply similar changes to `app/assignments/routes.py`:
- Add S3 upload in `submit()` route
- Add S3 download in `download_submission()` route
- Add S3 delete in the resubmission logic

---

## Push Docker Image to ECR

### 1. Create ECR Repository

```bash
aws ecr create-repository --repository-name moodlite --region us-east-1
```

Save the repository URI: `<account-id>.dkr.ecr.us-east-1.amazonaws.com/moodlite`

### 2. Login to ECR

```bash
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin <account-id>.dkr.ecr.us-east-1.amazonaws.com
```

### 3. Build Docker Image

```bash
docker build -t moodlite:latest .
```

### 4. Tag Image for ECR

```bash
docker tag moodlite:latest <account-id>.dkr.ecr.us-east-1.amazonaws.com/moodlite:latest
```

### 5. Push to ECR

```bash
docker push <account-id>.dkr.ecr.us-east-1.amazonaws.com/moodlite:latest
```

---

## Launch EC2 Instance

### 1. Navigate to EC2

1. Go to [AWS EC2 Console](https://console.aws.amazon.com/ec2)
2. Click **"Launch instances"**

### 2. Choose AMI

- Select **"Ubuntu Server 22.04 LTS (HVM), SSD Volume Type"** (free tier eligible)

### 3. Instance Type

- Select **t2.micro** (free tier eligible)
- Click **"Next: Configure instance details"**

### 4. Network Settings

- **VPC**: default
- **Auto-assign public IP**: Enable
- **IAM instance profile**: Select `moodlite-app` (if created, otherwise skip)

### 5. Storage

- **Root volume**: 30 GB (free tier allows up to 30 GB)
- **Encrypted**: No (for cost savings)

### 6. Security Group

Create new security group:

| Type | Protocol | Port | Source |
|------|----------|------|--------|
| HTTP | TCP | 80 | 0.0.0.0/0 |
| HTTPS | TCP | 443 | 0.0.0.0/0 |
| SSH | TCP | 22 | Your IP |

Name: `moodlite-app-sg`

### 7. Key Pair

- Create new key pair: `moodlite-keypair`
- Download and save securely: `moodlite-keypair.pem`

```bash
# Set permissions
chmod 400 moodlite-keypair.pem
```

### 8. Launch Instance

Review and click **"Launch instances"**

### 9. Get Instance Details

1. Once launched, go to Instances
2. Select your instance
3. Copy the **Public IPv4 address** (e.g., `54.123.45.67`)

---

## Deploy Application on EC2

### 1. SSH into EC2

```bash
ssh -i moodlite-keypair.pem ubuntu@54.123.45.67
```

### 2. Update System

```bash
sudo apt update && sudo apt upgrade -y
```

### 3. Install Docker

```bash
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker ubuntu
```

### 4. Install Docker Compose

```bash
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```

### 5. Configure AWS Credentials on EC2

```bash
aws configure
# Enter the IAM user credentials created earlier
```

### 6. Clone Repository (or scp files)

```bash
git clone https://github.com/<your-username>/moodlite.git
cd moodlite
```

Or upload via SCP:
```bash
scp -r -i moodlite-keypair.pem ./ ubuntu@54.123.45.67:~/moodlite/
```

### 7. Create Production Environment File

```bash
cat > .env.prod << 'EOF'
FLASK_APP=wsgi.py
FLASK_ENV=production
SECRET_KEY=<generate-random-key>
DATABASE_URL=postgresql://moodliteadmin:<password>@moodlite-db-prod.xxxx.us-east-1.rds.amazonaws.com:5432/moodlite
UPLOAD_FOLDER=/app/uploads
MAX_CONTENT_LENGTH=52428800

# S3 Configuration
USE_S3=true
AWS_ACCESS_KEY_ID=<your-access-key>
AWS_SECRET_ACCESS_KEY=<your-secret-key>
AWS_S3_BUCKET=moodlite-uploads-<your-username>
AWS_S3_REGION=us-east-1
EOF
```

Generate SECRET_KEY:
```bash
python3 -c "import secrets; print(secrets.token_hex(32))"
```

### 8. Create Production Docker Compose File

Create `docker-compose.prod.yml`:

```yaml
version: '3.8'

services:
  app:
    image: <account-id>.dkr.ecr.us-east-1.amazonaws.com/moodlite:latest
    ports:
      - "80:8000"
      - "443:8000"  # Will be handled by nginx reverse proxy
    environment:
      - FLASK_ENV=production
      - DATABASE_URL=${DATABASE_URL}
      - SECRET_KEY=${SECRET_KEY}
      - USE_S3=${USE_S3}
      - AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}
      - AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}
      - AWS_S3_BUCKET=${AWS_S3_BUCKET}
      - AWS_S3_REGION=${AWS_S3_REGION}
    restart: always
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
```

### 9. Run Migrations

```bash
# Using a one-off container
docker-compose -f docker-compose.prod.yml run app flask db upgrade
```

### 10. Start Application

```bash
docker-compose -f docker-compose.prod.yml up -d
```

### 11. Verify Application is Running

```bash
curl http://localhost/
# Should return HTML (the homepage)
```

---

## Setup Custom Domain & HTTPS (Optional)

### 1. Get a Domain

- Purchase from Route 53, Namecheap, GoDaddy, etc.
- Example: `moodlite.example.com`

### 2. Request SSL Certificate (ACM)

1. Go to [AWS Certificate Manager](https://console.aws.amazon.com/acm)
2. Click **"Request certificate"**
3. Add domain: `moodlite.example.com` (and `*.moodlite.example.com` for subdomains)
4. Verify via email or DNS record

### 3. Setup Nginx Reverse Proxy (on EC2)

```bash
sudo apt install nginx -y
```

Create `/etc/nginx/sites-available/moodlite`:

```nginx
server {
    listen 80;
    server_name moodlite.example.com www.moodlite.example.com;
    
    location / {
        proxy_pass http://localhost:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

Enable and restart:

```bash
sudo ln -s /etc/nginx/sites-available/moodlite /etc/nginx/sites-enabled/
sudo systemctl restart nginx
```

### 4. Setup DNS

Point your domain's nameservers or A record to the EC2 public IP: `54.123.45.67`

### 5. Setup HTTPS with Let's Encrypt (Free)

```bash
sudo apt install certbot python3-certbot-nginx -y
sudo certbot --nginx -d moodlite.example.com -d www.moodlite.example.com
```

This automatically updates Nginx config and renews certificates.

---

## Monitoring & Maintenance

### 1. View Logs

```bash
# Application logs
docker-compose -f docker-compose.prod.yml logs -f app

# System logs (SSH'd into EC2)
journalctl -u docker -f
```

### 2. Monitor CPU/Memory

Visit [CloudWatch Dashboard](https://console.aws.amazon.com/cloudwatch):
- Shows EC2 instance metrics
- Set up alarms for CPU > 80%

### 3. Database Monitoring

Visit [RDS Console](https://console.aws.amazon.com/rds):
- View metrics for database performance
- Check backup status
- Monitor storage usage

### 4. S3 Storage Monitoring

Visit [S3 Console](https://console.aws.amazon.com/s3):
- View bucket size
- Manage storage costs

### 5. Auto-Restart Application

```bash
# Add to crontab to restart daily at 2 AM
0 2 * * * cd /home/ubuntu/moodlite && docker-compose -f docker-compose.prod.yml restart app
```

### 6. Backup Database

```bash
# Manual backup (AWS RDS handles automated backups)
aws rds create-db-snapshot \
  --db-instance-identifier moodlite-db-prod \
  --db-snapshot-identifier moodlite-backup-$(date +%s) \
  --region us-east-1
```

### 7. Update Application

To deploy a new version:

```bash
# Build and push new image
docker build -t <account-id>.dkr.ecr.us-east-1.amazonaws.com/moodlite:latest .
docker push <account-id>.dkr.ecr.us-east-1.amazonaws.com/moodlite:latest

# On EC2, restart:
docker-compose -f docker-compose.prod.yml pull
docker-compose -f docker-compose.prod.yml up -d
```

---

## Cost Estimation (Monthly)

| Service | Free Tier | Paid | Notes |
|---------|-----------|------|-------|
| EC2 (t2.micro) | 750 hrs/mo | $0 | Free for 12 months |
| RDS (db.t2.micro) | 750 hrs/mo | $0-15 | Free for 12 months if eligible |
| S3 | 5 GB storage | $0.023/GB | First 5GB free |
| Data Transfer | 100 GB/mo out | $0 | First 100GB free |
| **Total** | — | **$0-20/mo** | **FREE first year** |

---

## Troubleshooting

### Issue: Cannot connect to RDS

**Solution:**
1. Check RDS security group allows EC2 security group
2. Verify DATABASE_URL is correct
3. Ensure RDS is publicly accessible:
   - RDS Console → Modify → Public Accessibility → Yes

### Issue: Application crashes on startup

**Solution:**
```bash
# Check logs
docker-compose -f docker-compose.prod.yml logs app

# Rebuild image
docker-compose -f docker-compose.prod.yml build --no-cache
docker-compose -f docker-compose.prod.yml up -d
```

### Issue: Files not uploading to S3

**Solution:**
1. Verify IAM credentials have S3 permissions
2. Check S3 bucket name is correct
3. Ensure boto3 is installed: `pip install boto3`
4. Test S3 access manually:
   ```bash
   aws s3 ls s3://moodlite-uploads-<username>/
   ```

### Issue: High AWS costs

**Solution:**
1. Ensure using t2.micro (free tier)
2. Delete unused resources (snapshots, volumes)
3. Set CloudWatch alarms for cost monitoring
4. Review S3 lifecycle policies to delete old uploads

---

## Next Steps

1. ✅ Create AWS account
2. ✅ Set up RDS database
3. ✅ Create S3 bucket
4. ✅ Modify application for S3
5. ✅ Push to ECR
6. ✅ Launch EC2 instance
7. ✅ Deploy application
8. ✅ (Optional) Setup custom domain & HTTPS
9. ✅ Monitor and maintain

Once complete, your website is accessible from anywhere at: `http://<your-ec2-public-ip>` or `https://yourdomain.com`

---

## Support & Resources

- [AWS Free Tier Documentation](https://aws.amazon.com/free/)
- [Flask Deployment Guide](https://flask.palletsprojects.com/en/2.3.x/deploying/)
- [Docker Documentation](https://docs.docker.com/)
- [AWS CLI Reference](https://docs.aws.amazon.com/cli/)

**Happy deploying! 🚀**
