# MoodLite LMS

> A minimal Learning Management System with a full production-style DevOps infrastructure.

[![Build & Push](https://github.com/yourgithubusername/moodlite/actions/workflows/build-push.yaml/badge.svg)](https://github.com/yourgithubusername/moodlite/actions/workflows/build-push.yaml)

---

## What Is This?

**MoodLite** is a Flask-based LMS that lets instructors create courses and deliver content, and students enroll, download files, and submit assignments. The application itself is minimal — the DevOps infrastructure is the real project.

### App Features

| Feature | Instructor | Student |
|---|---|---|
| Register / Login | Yes | Yes |
| Create course + enroll code | Yes | — |
| Enroll in course | — | Yes |
| Upload course content | Yes | — |
| Download content | Yes | Yes |
| Create assignments | Yes | — |
| Submit assignment | — | Yes |
| View all submissions | Yes | — |

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
├── scripts/                    # DevOps scripts
├── Dockerfile                  # Multi-stage build
├── docker-compose.yml          # Local dev
└── requirements.txt
```

---

## CI/CD Pipeline

Push to `main` → GitHub Actions → Docker Hub

Secrets required in GitHub repo Settings → Secrets and variables → Actions:
- `DOCKERHUB_USERNAME`
- `DOCKERHUB_TOKEN`

Once set, every push to `main` automatically builds and pushes `yourusername/moodlite:latest` to Docker Hub.

To deploy the new image to Kubernetes after a push:

```bash
kubectl rollout restart deployment/moodlite-app -n moodlite
```

---

## Quick Start — Public App (Docker Compose + ngrok)

This is the simplest way to get the app running and publicly accessible.

### Prerequisites
- Docker and Docker Compose installed
- ngrok account at ngrok.com (free)

### Step 1 — Start the app

```bash
docker-compose up -d
```

### Step 2 — Verify it is running

```bash
curl http://localhost:5000/health
# Expected: {"status": "ok"}
```

### Step 3 — Configure ngrok

```bash
ngrok config add-authtoken YOUR_NGROK_TOKEN
```

### Step 4 — Expose publicly

```bash
ngrok http 5000
```

ngrok will print a public HTTPS URL like `https://abc123.ngrok-free.app`. Share that URL with anyone — they can access MoodLite from anywhere as long as your laptop is on and ngrok is running.

### Stopping without losing data

```bash
docker-compose down        # stops containers, keeps database
docker-compose down -v     # WARNING: also deletes the database
```

### Viewing logs

```bash
docker-compose logs -f app       # Flask app logs
docker-compose logs -f postgres  # Database logs
```

---

## Scalability Demo — Kubernetes + Minikube

This section demonstrates auto-scaling using Kubernetes HPA (Horizontal Pod Autoscaler), Prometheus metrics collection, and Grafana dashboards.

### Prerequisites
- Minikube installed
- kubectl installed
- Helm installed
- hey (HTTP load generator) installed

Install hey:

```bash
# Using Go
go install github.com/rakyll/hey@latest
# Add to PATH (Fish shell)
set -Ux fish_user_paths ~/go/bin $fish_user_paths

# Or direct binary
curl -LO https://hey-release.s3.us-east-2.amazonaws.com/hey_linux_amd64
chmod +x hey_linux_amd64
sudo mv hey_linux_amd64 /usr/local/bin/hey
```

---

### Step 1 — Start Minikube

```bash
minikube start --cpus 4 --memory 6144 --driver docker
```

Enable required addons:

```bash
minikube addons enable ingress
minikube addons enable metrics-server
```

Create the directory required by the PersistentVolume:

```bash
minikube ssh "sudo mkdir -p /mnt/moodlite-data && sudo chmod 777 /mnt/moodlite-data"
```

---

### Step 2 — Deploy MoodLite to Kubernetes

```bash
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/secret.yaml
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/postgres-pv.yaml
kubectl apply -f k8s/postgres-pvc.yaml
kubectl apply -f k8s/postgres-deployment.yaml
kubectl apply -f k8s/postgres-service.yaml
kubectl apply -f k8s/app-deployment.yaml
kubectl apply -f k8s/app-service.yaml
kubectl apply -f k8s/hpa.yaml
```

Wait for pods to be ready:

```bash
kubectl get pods -n moodlite -w
```

Both `moodlite-app` and `postgres` pods should show `Running`.

---

### Step 3 — Run Database Migrations

```bash
# Bash
POD=$(kubectl get pod -n moodlite -l app=moodlite-app -o jsonpath='{.items[0].metadata.name}')
kubectl exec -it $POD -n moodlite -- flask db upgrade

# Fish shell
set POD (kubectl get pod -n moodlite -l app=moodlite-app -o jsonpath='{.items[0].metadata.name}')
kubectl exec -it $POD -n moodlite -- flask db upgrade
```

---

### Step 4 — Access the App

```bash
kubectl port-forward svc/moodlite-service 8080:80 -n moodlite
```

Open `http://localhost:8080` in your browser.

To expose publicly via ngrok at the same time:

```bash
ngrok http 8080
```

---

### Step 5 — Install Monitoring (Prometheus + Grafana)

Only needs to be done once:

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
kubectl create namespace monitoring
helm install monitoring prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --set alertmanager.enabled=false
```

Wait for all monitoring pods to be running:

```bash
kubectl get pods -n monitoring -w
```

---

### Step 6 — Access Grafana

Get the Grafana admin password:

```bash
kubectl get secret --namespace monitoring monitoring-grafana \
  -o jsonpath="{.data.admin-password}" | base64 --decode ; echo
```

Port-forward Grafana:

```bash
kubectl port-forward svc/monitoring-grafana 3001:80 -n monitoring
```

Open `http://localhost:3001` and login with username `admin` and the password from above.

Port-forward Prometheus (optional):

```bash
kubectl port-forward svc/monitoring-kube-prometheus-prometheus 9091:9090 -n monitoring
```

Open `http://localhost:9091` to query raw metrics.

---

### Step 7 — Grafana Visualization Queries

In Grafana, go to **Explore** on the left sidebar, select **Prometheus** as the data source, and run these queries:

**Live CPU usage per pod:**
```
rate(container_cpu_usage_seconds_total{namespace="moodlite", container!=""}[1m])
```

**Memory usage per pod:**
```
container_memory_working_set_bytes{namespace="moodlite", container!=""}
```

**Pod count in moodlite namespace:**
```
count(kube_pod_info{namespace="moodlite"})
```

**CPU rate over 5 minutes:**
```
rate(container_cpu_usage_seconds_total{namespace="moodlite"}[5m])
```

Set the legend to `{{pod}}` on each panel to see per-pod breakdown.

For a pre-built dashboard, go to **Dashboards > Browse** and open:
- `Kubernetes / Compute Resources / Namespace (Pods)` — set namespace to `moodlite`
- `Kubernetes / Compute Resources / Node` — node-level CPU and memory

---

### Step 8 — Run the Load Test and Watch Scaling

Open three terminals simultaneously:

**Terminal 1 — Watch HPA and pods:**
```bash
watch -n 2 'kubectl get hpa -n moodlite && echo "" && kubectl get pods -n moodlite'
```

**Terminal 2 — Run load test:**
```bash
hey -z 120s -c 100 http://localhost:8080/
```

**Terminal 3 — Run additional load (optional, for faster scaling):**
```bash
hey -z 120s -c 100 http://localhost:8080/
```

As CPU crosses 60% of the pod's request, the HPA will scale `moodlite-app` from 1 replica up to a maximum of 5. Watch the pod count increase in Terminal 1 and the CPU spike in Grafana Explore simultaneously.

HPA configuration:
- Min replicas: 1
- Max replicas: 5
- Scale up trigger: CPU above 60% or memory above 75%
- Scale up speed: 2 pods per 60 seconds
- Scale down: 1 pod per 60 seconds after 120 second stabilization window

---

## Full Demo Startup — All Services at Once

Run these in separate terminals in order:

```bash
# Terminal 1 — Public app
docker-compose up -d

# Terminal 2 — Public ngrok tunnel
ngrok http 5000

# Terminal 3 — Minikube app port-forward
minikube start
kubectl port-forward svc/moodlite-service 8080:80 -n moodlite

# Terminal 4 — Grafana
kubectl port-forward svc/monitoring-grafana 3001:80 -n monitoring

# Terminal 5 — Prometheus (optional)
kubectl port-forward svc/monitoring-kube-prometheus-prometheus 9091:9090 -n monitoring

# Terminal 6 — Load test
hey -z 120s -c 100 http://localhost:8080/

# Terminal 7 — Watch scaling
watch -n 2 'kubectl get hpa -n moodlite && echo "" && kubectl get pods -n moodlite'
```

### Access Points

| Service | URL | Purpose |
|---|---|---|
| Public app | ngrok URL from Terminal 2 | Share with users |
| Local Kubernetes app | http://localhost:8080 | Load testing target |
| Grafana | http://localhost:3001 | Live metrics dashboard |
| Prometheus | http://localhost:9091 | Raw metrics queries |

---

## Useful kubectl Commands

```bash
# Pod status
kubectl get pods -n moodlite

# Pod logs
kubectl logs -f deployment/moodlite-app -n moodlite

# HPA status
kubectl get hpa -n moodlite

# Resource usage
kubectl top pods -n moodlite
kubectl top nodes

# Restart app after new Docker image is pushed
kubectl rollout restart deployment/moodlite-app -n moodlite

# Watch rollout progress
kubectl rollout status deployment/moodlite-app -n moodlite

# Describe a pod for debugging
kubectl describe pod -n moodlite -l app=moodlite-app

# Get all resources in moodlite namespace
kubectl get all -n moodlite
```

---

## Kubernetes Architecture

| Resource | Purpose |
|---|---|
| Namespace | Isolates all MoodLite resources |
| ConfigMap | APP_ENV, DB_HOST, DB_NAME, UPLOAD_FOLDER |
| Secret | DB_PASSWORD, SECRET_KEY, DB_USER |
| PersistentVolume | 5GB hostPath volume on Minikube node |
| PersistentVolumeClaim | Binds PV to PostgreSQL pod |
| PostgreSQL Deployment | Single replica, mounts PVC |
| PostgreSQL Service | ClusterIP, internal DNS: postgres-service |
| App Deployment | 1-5 replicas, pulls from Docker Hub |
| App Service | ClusterIP, port 80 to 5000 |
| HPA | Scales app pods at 60% CPU or 75% memory |

---

## Troubleshooting

**Pods stuck in ContainerCreating:**
```bash
kubectl describe pod -n moodlite -l app=moodlite-app | tail -20
# Check Events section for the exact error
```

**Database connection refused:**
```bash
# Verify DATABASE_URL is set correctly in the pod
kubectl exec -it $POD -n moodlite -- env | grep DATABASE
# Should show postgres-service, not localhost
```

**HPA shows unknown metrics:**
```bash
# metrics-server may not be running yet, wait 2-3 minutes
kubectl get hpa -n moodlite
# Or re-enable metrics-server
minikube addons enable metrics-server
```

**Port already in use:**
```bash
# Use a different local port
kubectl port-forward svc/monitoring-grafana 3002:80 -n monitoring
```

**Minikube PV path missing:**
```bash
minikube ssh "sudo mkdir -p /mnt/moodlite-data && sudo chmod 777 /mnt/moodlite-data"
```

**Docker Compose database lost:**
```bash
# Never run docker-compose down -v unless you want to wipe all data
# Safe stop:
docker-compose down
# Safe start:
docker-compose up -d
```