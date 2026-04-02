# MoodLite Setup Guide

This guide covers everything you and your teammates need to get **MoodLite** running, from local development to the full production-style Kubernetes infrastructure.

---

## 1. Environment Variables (`.env`)

The application uses environment variables for configuration. We have a template provided in `.env.example`.

### Step 1: Create your `.env` file
Copy the example file to a new file named `.env`:

```bash
cp .env.example .env
```

### Step 2: Configure the variables
Open `.env` and update the values as needed:

| Variable | Description | Default / Example |
| :--- | :--- | :--- |
| `FLASK_APP` | The entry point of the application. | `wsgi.py` |
| `FLASK_ENV` | Development or production mode. | `development` |
| `SECRET_KEY` | Used for session security. **Change this** to a random string. | `change-me-to-a-random-secret-key` |
| `DATABASE_URL` | Connection string for PostgreSQL. | `postgresql://moodlite:moodlite_pass@localhost:5432/moodlite` |
| `UPLOAD_FOLDER` | Where user-uploaded files are stored. | `/app/uploads` |
| `MAX_CONTENT_LENGTH` | Max file upload size (in bytes). | `52428800` (50MB) |

---

## 2. Local Development (Native)

Use this method if you want to run the app directly on your machine without Docker.

### Prerequisites
- Python 3.10+
- PostgreSQL (running locally)

### Steps
1. **Create a virtual environment:**
   ```bash
   python3 -m venv venv
   source venv/bin/activate
   ```
2. **Install dependencies:**
   ```bash
   pip install -r requirements.txt
   ```
3. **Set up the database:**
   Create a database named `moodlite` in your local PostgreSQL instance.
4. **Run migrations:**
   ```bash
   flask db upgrade
   ```
5. **Start the app:**
   ```bash
   flask run
   ```
   The app will be available at `http://localhost:5000`.

---

## 3. Local Development (Docker Compose)

The easiest way to get the app and its database running together without manual setup.

### Prerequisites
- Docker & Docker Compose

### Steps
1. **Build and start the containers:**
   ```bash
   docker-compose up --build
   ```
2. **Access the app:**
   Visit `http://localhost:5000` in your browser.
3. **Stop the app:**
   ```bash
   docker-compose down
   ```

---

## 4. Full Infrastructure (Kubernetes)

This mimics a production environment using Minikube.

### Prerequisites
- Minikube
- kubectl
- Helm
- ngrok (for public access)

### The "One-Command" Setup
We provide a master script that handles everything: starting Minikube, deploying resources, running migrations, setting up monitoring, and starting the ngrok tunnel.

```bash
bash scripts/present.sh
```

### Individual Steps (If you want manual control)
1. **Start Minikube:** `bash scripts/start-minikube.sh`
2. **Deploy K8s Resources:** `bash scripts/deploy-k8s.sh`
3. **Run Migrations:** `bash scripts/migrate-db.sh`
4. **Setup Monitoring:** `bash scripts/setup-monitoring.sh`
5. **Port-forward Grafana:** `bash scripts/forward-grafana.sh` (access at `http://localhost:3000`)
6. **Start ngrok:** `bash scripts/start-ngrok.sh`

---

## 5. Monitoring & Load Testing

Once the Kubernetes infrastructure is running:

### Grafana
- **URL:** `http://localhost:3000`
- **Login:** `admin` / `moodlite-grafana`

### Load Testing (HPA Demo)
To see the Horizontal Pod Autoscaler in action:
```bash
bash scripts/load-test.sh
```
In another terminal, watch the pods scale:
```bash
kubectl get hpa -n moodlite --watch
```

---

## 6. Common Troubleshooting

- **Database Connection Errors:** Ensure your `DATABASE_URL` in `.env` matches your local Postgres credentials or the Docker Compose service name.
- **Permission Denied (Scripts):** If scripts aren't running, give them execution permissions: `chmod +x scripts/*.sh`.
- **Minikube Resources:** Ensure your machine has at least 12GB RAM and 4 CPUs free for the full K8s stack.
