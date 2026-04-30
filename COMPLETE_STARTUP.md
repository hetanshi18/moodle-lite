# MoodLite Complete Startup Guide

Quick guide to get **everything** up and running in one go.

---

## 🚀 Quick Start (One Command)

```bash
# From project root directory
bash scripts/start-all.sh
```

This will:
1. ✅ Start **Flask App + PostgreSQL** (Docker Compose)
2. ✅ Start **Monitoring Stack** (Prometheus + Grafana)
3. ✅ Optionally start **Minikube + Kubernetes** (if you want)

Then wait 30-45 seconds for everything to be ready.

---

## 📊 All Services on One Page

| Service | Port | URL | Purpose |
|---------|------|-----|---------|
| **Flask App** | 5000 | http://localhost:5000 | MoodLite LMS |
| **Postgres DB** | 5432 | localhost:5432 | Database |
| **Prometheus** | 9090 | http://localhost:9090 | Metrics collection |
| **Grafana** | 3000 | http://localhost:3000 | Dashboard (admin/admin) |
| **Alertmanager** | 9093 | http://localhost:9093 | Alert management |
| **Node Exporter** | 9100 | http://localhost:9100 | System metrics |

---

## ⚙️ What Gets Started?

### 1. Main Application (Always)
```
Docker Compose runs:
├── Flask Application (Port 5000)
│   └─ Gunicorn server
│   └─ Connected to database
│   └─ File uploads to local directory
└── PostgreSQL Database (Port 5432)
    └─ Moodlite database
    └─ Persistent volume
```

### 2. Monitoring Stack (Always)
```
Docker Compose runs:
├── Prometheus (Port 9090)
│   └─ Scrapes metrics every 15 seconds
│   └─ Alert rule evaluation
├── Grafana (Port 3000)
│   └─ Beautiful dashboards
│   └─ Connects to Prometheus
├── Alertmanager (Port 9093)
│   └─ Alert routing
│   └─ Notification handling
└── Node Exporter (Port 9100)
    └─ System metrics (CPU, Memory, Disk)
```

### 3. Kubernetes (Optional)
```
If you choose yes:
├── Minikube cluster (6 CPU, 10GB RAM)
├── Docker registry (local)
├── Kubernetes namespace (moodlite)
├── App pod
├── Database pod
├── Persistent volumes
└── Ingress controller
```

---

## 🛠️ Step-by-Step

### Step 1: Prerequisites Check
```bash
# Make sure you have:
✓ Docker installed and running
✓ Docker Compose installed
✓ ~20GB free disk space
✓ At least 4GB RAM free
```

### Step 2: Run Master Startup
```bash
bash scripts/start-all.sh
```

Follow the prompts:
- Press Enter to start services
- When asked about Minikube, answer **y** for full stack or **n** for just Docker Compose

### Step 3: Wait for Services
```
Step 1/3: Starting Docker Compose...
✅ Building images
✅ Starting services
✅ Waiting for health checks
```

Takes 3-5 minutes first time (building Docker image)

### Step 4: Access Services
Once complete, you'll see:
```
🎉 All services are running!

📊 Access Points:
   🟢 Flask App:      http://localhost:5000
   🟢 Prometheus:    http://localhost:9090
   🟢 Grafana:       http://localhost:3000
   🟢 Alertmanager:  http://localhost:9093
```

Open each in your browser!

---

## 📝 Common Tasks

### View All Logs
```bash
# App logs
docker-compose logs -f app

# Database logs
docker-compose logs -f postgres

# All monitoring logs
docker-compose -f docker-compose.monitoring.yml logs -f

# Specific service
docker-compose logs -f grafana
```

### Stop Everything
```bash
bash scripts/stop-all.sh
```

### Check What's Running
```bash
bash scripts/status.sh
```

### Restart a Single Service
```bash
# Restart Flask app
docker-compose restart app

# Restart Prometheus
docker-compose -f docker-compose.monitoring.yml restart prometheus

# Restart everything
docker-compose restart
docker-compose -f docker-compose.monitoring.yml restart
```

### Clean Up (Remove all data)
```bash
# WARNING: This deletes databases and saved data
docker-compose down -v
docker-compose -f docker-compose.monitoring.yml down -v
```

### Update Application Code
```bash
# Stop app
docker-compose down

# Edit code in your editor
# Code in ./ is mounted as volume

# Rebuild and restart
docker-compose up -d
```

---

## 🐛 Troubleshooting

### Issue: Port 5000 already in use
```bash
# Find what's using it
lsof -i :5000

# Stop it or use different port
# Edit docker-compose.yml and change port
```

### Issue: Docker build fails
```bash
# Clear Docker cache
docker system prune -a

# Rebuild
docker-compose build --no-cache
```

### Issue: Database won't connect
```bash
# Check postgres is running
docker-compose logs postgres

# Reset database
docker-compose down -v
docker-compose up -d
```

### Issue: out of disk space
```bash
# See what's taking space
docker system df

# Clean up unused images/volumes
docker system prune -a --volumes
```

### Issue: Grafana password forgotten
```bash
# Default is admin/admin
# Reset admin password
docker-compose exec grafana grafana-cli admin reset-admin-password newpassword
```

### Issue: Prometheus not collecting metrics
```bash
# Check targets
# Visit: http://localhost:9090/targets

# If targets are "DOWN", check:
# 1. Service actually running
# 2. Port is correct
# 3. Firewall isn't blocking
```

---

## 🔄 Service Dependencies

```
Start order (automatic):
1. Network created
2. Postgres starts + becomes healthy
3. Flask app starts (depends on Postgres)
4. Prometheus starts (independent)
5. Grafana starts (depends on Prometheus)
6. Alertmanager starts (independent)
7. Node-exporter starts (independent)

All services are also set to "restart: unless-stopped"
So they'll auto-restart if they crash
```

---

## 📊 Next Steps After Everything Runs

### 1. Test the App
- Register a new account (instructor or student)
- Create a course
- Upload content
- Submit assignments

### 2. Monitor the App
- Go to Grafana (http://localhost:3000)
- Login with admin/admin
- Create dashboards to visualize metrics

### 3. Check Health
- Run: `bash scripts/status.sh`
- See what services are running and respond

### 4. Deploy to AWS
- Follow [AWS_DEPLOYMENT.md](../AWS_DEPLOYMENT.md)
- Use the same scripts to monitor on AWS

### 5. Deploy to Kubernetes
- Run Minikube setup
- Use kubectl to manage deployments
- Scale up/down pods

---

## 🎯 Performance Tips

### For Local Development
- Run **ONLY** Docker Compose (without Minikube)
- `bash scripts/start-all.sh` → answer "n" for Minikube

### For Production Testing
- Include Minikube + Kubernetes
- `bash scripts/start-all.sh` → answer "y" for Minikube

### For Monitoring
- Always run Monitoring Stack
- Keep Prometheus retention: 30 days
- Grafana RAM: ~200MB

### Resource Usage
- Docker Compose: ~2GB RAM, ~10GB disk
- Monitoring: ~500MB RAM, ~5GB disk
- Minikube: ~6GB RAM, ~20GB disk
- **Total:**  ~1GB + Minikube optional

---

## 🔗 Related Documentation

- [Docker Compose Details →](../SETUP.md#3-local-development-docker-compose)
- [Monitoring Guide →](../MONITORING_GUIDE.md)
- [AWS Deployment →](../AWS_DEPLOYMENT.md)
- [Testing Guide →](../TESTING_GUIDE.md)
- [Kubernetes Setup →](../SETUP.md#4-full-infrastructure-kubernetes)

---

## 💡 Pro Tips

**Tip 1: Use Terminal Multiplexer**
```bash
# Run in separate windows with tmux or iTerm2
# Window 1: docker-compose logs -f
# Window 2: docker-compose -f docker-compose.monitoring.yml logs -f
# Window 3: Your editor/browser
```

**Tip 2: Create Shell Aliases**
```bash
# Add to ~/.bashrc or ~/.zshrc
alias moodlite-start='bash ~/Desktop/moodle-lite/scripts/start-all.sh'
alias moodlite-stop='bash ~/Desktop/moodle-lite/scripts/stop-all.sh'
alias moodlite-status='bash ~/Desktop/moodle-lite/scripts/status.sh'
alias moodlite-logs='docker-compose -f ~/Desktop/moodle-lite logs -f'
```

**Tip 3: Keep Services Running**
```bash
# Even if you close terminal, services keep running
# Check with: docker ps
# Access anytime at http://localhost:5000
```

**Tip 4: Backup Your Data**
```bash
# Docker volumes are in: /var/lib/docker/volumes/
# Or use: docker cp <container>:/path /local/path
```

---

**Ready? Run:** `bash scripts/start-all.sh` 🚀
