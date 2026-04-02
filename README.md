# MoodLite LMS

> A minimal Learning Management System with a full production-style DevOps infrastructure.

[![Build & Push](https://github.com/yourgithubusername/moodlite/actions/workflows/build-push.yaml/badge.svg)](https://github.com/yourgithubusername/moodlite/actions/workflows/build-push.yaml)

---

## What Is This?

**MoodLite** is a Flask-based LMS that lets instructors create courses and deliver content, and students enroll, download files, and submit assignments. The application itself is minimal — **the DevOps infrastructure is the real project**.

### App Features
| Feature | Instructor | Student |
|---|---|---|
| Register / Login | ✅ | ✅ |
| Create course + enroll code | ✅ | — |
| Enroll in course | — | ✅ |
| Upload course content | ✅ | — |
| Download content | ✅ | ✅ |
| Create assignments | ✅ | — |
| Submit assignment | — | ✅ |
| View all submissions | ✅ | — |

### Tech Stack
| Layer | Technology |
|---|---|
| Web framework | Flask 3.x + Gunicorn |
| Auth | Flask-Login + bcrypt |
| ORM / DB | Flask-SQLAlchemy + PostgreSQL 15 |
| Migrations | Flask-Migrate (Alembic) |
| UI | Bootstrap 5 (dark, glassmorphism) |
| Container | Docker (multi-stage build) |
| Orchestration | Kubernetes (Minikube) |
| CI/CD | GitHub Actions → Docker Hub |
| Monitoring | Prometheus + Grafana (Helm) |
| Public access | ngrok |

---

## Quick Start (Local Dev — Docker Compose)

```bash
# 1. Clone and copy env
git clone https://github.com/yourgithubusername/moodlite
cd moodlite
cp .env.example .env        # Edit if needed

# 2. Start app + postgres
docker-compose up --build

# 3. Visit http://localhost:5000
```

---

## Kubernetes + Full Infrastructure

See **[SETUP.md](SETUP.md)** for the complete step-by-step setup guide.

**Before a presentation**, run:

```bash
bash scripts/present.sh
```

This calls all individual scripts in sequence:

| Script | What it does |
|---|---|
| `start-minikube.sh` | Start Minikube (6 CPU / 10 GB RAM) + addons |
| `deploy-k8s.sh` | Apply all manifests, wait for pods Ready |
| `migrate-db.sh` | Run `flask db upgrade` inside app pod |
| `setup-monitoring.sh` | Install Prometheus + Grafana via Helm |
| `forward-grafana.sh` | Port-forward Grafana → localhost:3000 |
| `start-ngrok.sh` | ngrok tunnel → prints public HTTPS URL |

You can also run any script individually.

---

## Project Structure

```
moodlite/
├── app/                        # Flask application
│   ├── __init__.py             # App factory
│   ├── models.py               # SQLAlchemy models
│   ├── auth/                   # Login, register, logout
│   ├── courses/                # Create, enroll, view
│   ├── content/                # Upload, download
│   ├── assignments/            # Create, submit, view
│   ├── main/                   # Landing page, /health
│   ├── templates/              # Jinja2 HTML templates
│   └── static/                 # CSS, JS
├── k8s/                        # Kubernetes manifests
├── .github/workflows/          # GitHub Actions CI/CD
├── monitoring/                 # Prometheus + Grafana Helm values
├── scripts/                    # Modular DevOps scripts
├── Dockerfile                  # Multi-stage build
├── docker-compose.yml          # Local dev
└── requirements.txt
```

---

## CI/CD Pipeline

Push to `main` → GitHub Actions → Docker Hub

Secrets required in GitHub repo:
- `DOCKERHUB_USERNAME`
- `DOCKERHUB_TOKEN`

---

## Monitoring

After running `setup-monitoring.sh` and `forward-grafana.sh`:

| Service | URL |
|---|---|
| Grafana | http://localhost:3000 |
| Login | admin / moodlite-grafana |

---

## Load Testing / HPA Demo

```bash
# Trigger autoscaling
bash scripts/load-test.sh

# Watch pods scale in another terminal
kubectl get hpa -n moodlite --watch
```

HPA scales 1→5 replicas at 60% CPU.
