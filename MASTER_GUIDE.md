# MoodLite - LMS DevOps Project
## Complete Master Guide

---

## What You Are Building

**MoodLite** is a minimal Learning Management System (LMS) with a full
production-style DevOps infrastructure built around it. The app itself is simple.
The infrastructure is the real project.

- App name: MoodLite
- Docker Hub image: `yourdockerhubusername/moodlite`
- GitHub repo: `moodlite`
- Kubernetes namespace: `moodlite`

---

## Project Map

```
moodlite/
├── app/                        # Flask application
│   ├── __init__.py             # App factory, extensions
│   ├── models.py               # SQLAlchemy models (User, Course, Content, Assignment)
│   ├── auth/                   # Login, register, logout
│   ├── courses/                # Create course, enroll, view
│   ├── content/                # Upload notes/files, view, download
│   ├── assignments/            # Submit file, instructor view
│   ├── templates/              # Jinja2 HTML templates
│   ├── static/                 # CSS, JS
│   └── config.py               # Config from env vars
├── k8s/
│   ├── namespace.yaml          # moodlite namespace
│   ├── configmap.yaml          # Non-sensitive app config
│   ├── secret.yaml             # DB password, secret key
│   ├── postgres-pv.yaml        # PersistentVolume (host path)
│   ├── postgres-pvc.yaml       # PersistentVolumeClaim
│   ├── postgres-deployment.yaml
│   ├── postgres-service.yaml
│   ├── app-deployment.yaml     # Flask app deployment
│   ├── app-service.yaml        # ClusterIP service
│   ├── ingress.yaml            # Routes moodlite.local → app
│   └── hpa.yaml                # Autoscales app pods 1→5
├── .github/
│   └── workflows/
│       └── build-push.yaml     # GitHub Actions: build → push to Docker Hub
├── monitoring/
│   └── values.yaml             # Prometheus + Grafana Helm overrides
├── Dockerfile                  # Multi-stage Flask image
├── docker-compose.yml          # Local dev without Kubernetes
├── requirements.txt
├── .env.example                # Template for local env vars
├── scripts/
│   ├── present.sh              # Pre-presentation startup script
│   └── load-test.sh            # Triggers HPA for the demo
├── README.md
└── SETUP.md
```

---

## The App: MoodLite Features

### 1. User Authentication
- Register with email, password, and role (student or instructor)
- Login / logout
- Role-based access: instructors see management UI, students see enrollment UI
- Passwords hashed with bcrypt
- Sessions via Flask-Login

### 2. Course Management
- Instructor: create a course (name, description, enroll code)
- Student: enroll in a course using the enroll code
- Both: view course dashboard

### 3. Content Delivery
- Instructor: upload files (PDF, video, notes) to a course
- Student: view list of uploaded content, download files
- Files stored on a Kubernetes PersistentVolume (same volume as PostgreSQL data)

### 4. Assignment Submission
- Instructor: create an assignment (title, description, due date)
- Student: upload a file submission
- Instructor: view all submissions for an assignment

---

## Tech Stack

| Layer | Technology |
|---|---|
| Web framework | Flask 3.x |
| Auth | Flask-Login + bcrypt |
| ORM | Flask-SQLAlchemy |
| Database | PostgreSQL 15 |
| Migrations | Flask-Migrate (Alembic) |
| File uploads | Werkzeug (stored on PV) |
| Templates | Jinja2 + Bootstrap 5 |
| WSGI server | Gunicorn |
| Container | Docker |
| Orchestration | Kubernetes (Minikube) |
| CI/CD | GitHub Actions |
| Monitoring | Prometheus + Grafana (Helm) |
| Public access | ngrok |

---

## DevOps Layer in Detail

### Containerization
- Single Dockerfile, multi-stage build (builder + runtime)
- App container and PostgreSQL container are separate
- docker-compose.yml for local development without Kubernetes
- Image pushed to Docker Hub on every commit to main

### Kubernetes on Minikube
| Resource | Purpose |
|---|---|
| Namespace | Isolates all MoodLite resources |
| ConfigMap | APP_ENV, DB_HOST, DB_NAME |
| Secret | DB_PASSWORD, SECRET_KEY (base64) |
| PersistentVolume | 5 GB hostPath volume on Minikube node |
| PersistentVolumeClaim | Binds the PV to PostgreSQL pod |
| PostgreSQL Deployment | Single replica, mounts the PVC |
| PostgreSQL Service | ClusterIP, internal DNS: postgres-service |
| App Deployment | 1-5 replicas, pulls from Docker Hub |
| App Service | ClusterIP, port 80 → 5000 |
| Ingress | Routes moodlite.local to app service |
| HPA | Scales app pods at 60% CPU |

### CI/CD with GitHub Actions
Trigger: push to `main` branch
Steps:
1. Checkout code
2. Log in to Docker Hub (using GitHub Secrets)
3. Build Docker image
4. Tag as `latest` and `sha-<commit>`
5. Push both tags to Docker Hub

Before presentation:
```bash
kubectl set image deployment/moodlite-app \
  moodlite=yourdockerhubusername/moodlite:latest
kubectl rollout restart deployment/moodlite-app
```

### Monitoring
- Prometheus + Grafana deployed via Helm into `monitoring` namespace
- Grafana accessible via port-forward during presentation
- Default dashboard shows: pod CPU, memory, request rate
- No custom instrumentation needed - kube-state-metrics handles it

### Public Access (ngrok)
- ngrok tunnels port 80 of Minikube Ingress to a public HTTPS URL
- Run once before presentation, share the URL
- Free tier is enough for a single demo session

---

## Step-by-Step Build Order

### Phase 1 - Accounts and Tools (~30 min)
1. GitHub account - create repo `moodlite`
2. Docker Hub account - create repo `moodlite`
3. ngrok account - get auth token
4. Install on your laptop:
   - Git
   - Docker + Docker Compose
   - Minikube
   - kubectl
   - Helm
   - ngrok

### Phase 2 - Build the Flask App (~2-3 hours)
1. Scaffold the project structure
2. Write models (User, Course, Enrollment, Content, Assignment, Submission)
3. Write auth routes (register, login, logout)
4. Write course routes (create, enroll, dashboard)
5. Write content routes (upload, list, download)
6. Write assignment routes (create, submit, view submissions)
7. Write templates (Bootstrap 5, one base template, one per feature)
8. Test locally with SQLite first, then switch to PostgreSQL via docker-compose

### Phase 3 - Dockerise (~30 min)
1. Write Dockerfile
2. Write docker-compose.yml (app + postgres)
3. Test: `docker-compose up` → visit localhost:5000
4. Verify file uploads and database persistence work

### Phase 4 - GitHub Actions (~30 min)
1. Add DOCKERHUB_USERNAME and DOCKERHUB_TOKEN to GitHub repo Secrets
2. Write `.github/workflows/build-push.yaml`
3. Push to main → verify image appears on Docker Hub

### Phase 5 - Kubernetes (~1 hour)
1. Start Minikube with enough resources
2. Enable ingress and metrics-server addons
3. Apply all manifests in order
4. Run database migrations inside the app pod
5. Add moodlite.local to /etc/hosts
6. Test: visit http://moodlite.local

### Phase 6 - Monitoring (~30 min)
1. Install Helm
2. Add prometheus-community Helm repo
3. Install kube-prometheus-stack into monitoring namespace
4. Port-forward Grafana to localhost:3000
5. Log in and verify pod metrics are showing

### Phase 7 - ngrok (~10 min)
1. Install ngrok, add auth token
2. Run: `ngrok http http://$(minikube ip):80`
3. Note the public URL
4. Update /etc/hosts or use the ngrok URL directly in browser

### Phase 8 - Load Test and HPA Demo (~15 min)
1. Run load-test.sh against the ngrok URL or moodlite.local
2. Watch HPA scale pods in a second terminal
3. Show Grafana dashboard spiking

---

## Presentation Flow (10-15 min demo)

1. Open the public ngrok URL in browser - show the LMS is live
2. Register as an instructor, create a course, upload a file
3. Register as a student, enroll, download the file, submit an assignment
4. Show `kubectl get pods` - healthy pods
5. Show `kubectl get hpa` - current state
6. Run load test - show pods scaling live
7. Show Grafana - CPU/memory graphs spiking and recovering
8. Show GitHub Actions run - CI/CD pipeline success

---

## Pre-Presentation Checklist

Run `scripts/present.sh` which does all of this automatically:

- [ ] Minikube running
- [ ] All pods in Running state
- [ ] Ingress IP assigned
- [ ] moodlite.local resolves correctly
- [ ] Latest Docker image pulled and deployed
- [ ] Prometheus and Grafana running
- [ ] Grafana port-forward active on localhost:3000
- [ ] ngrok tunnel running, public URL printed
- [ ] Load test script ready

---

## Scope Boundaries (intentionally excluded)

- No HTTPS/TLS (ngrok provides HTTPS on its end)
- No email sending (all email features mocked or omitted)
- No video streaming (file download only)
- No Redis/Celery (no background tasks)
- No multi-node Kubernetes (single Minikube node)
- No Istio or service mesh
- No Helm chart for the app itself (raw manifests only)

---

## System Requirements

| Resource | Required |
|---|---|
| RAM | 12 GB minimum (16 GB ideal) |
| CPU | 4 cores minimum |
| Disk | 30 GB free |
| OS | Any Linux distro |
| Internet | Required for Docker Hub pulls and ngrok |

Minikube will be started with 6 CPUs and 10 GB RAM.

---

## Review Points Before I Build

Please confirm or change:

1. App name: MoodLite - fine?
2. Database: PostgreSQL - fine? (MySQL is an alternative)
3. File storage: files stored on the same PersistentVolume as the database? Or separate?
4. Bootstrap 5 for the frontend - fine, or do you want something else?
5. Should the Grafana dashboard be accessible via ngrok too,
   or just via localhost port-forward during the presentation?
6. Do you want a `present.sh` script that starts everything automatically
   before the presentation (Minikube, pods, ngrok, Grafana port-forward)?
