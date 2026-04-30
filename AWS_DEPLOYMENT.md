# MoodLite AWS Deployment Guide (K3s Kubernetes)

Complete step-by-step guide to deploy your MoodLite Kubernetes architecture on AWS using **EC2 (free-tier eligible)** and **K3s (lightweight Kubernetes)**. This replaces the old docker-compose setup and ensures that your `k8s/` manifests run natively in production, matching your local Minikube environment!

---

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [How Code Reaches the Cloud](#how-code-reaches-the-cloud)
3. [Launch EC2 Instance](#launch-ec2-instance)
4. [Install K3s on EC2](#install-k3s-on-ec2)
5. [Configure Local kubectl Access](#configure-local-kubectl-access)
6. [Deploy MoodLite Manifests](#deploy-moodlite-manifests)
7. [Access the Application](#access-the-application)


---

## Architecture Overview

Instead of abandoning your Kubernetes configuration for production, we will run **K3s** (a lightweight, CNCF-certified Kubernetes distribution) directly on a single EC2 instance. This provides a true Kubernetes cluster that is perfectly compatible with free-tier resource limits.

**Services Used:**
- **EC2**: Application server running K3s (t2.micro free tier, or t3.small for more headroom).
- **Docker Hub**: For storing your application images (simplifies CI/CD over ECR).
- **K3s HostPath**: Local persistent storage for PostgreSQL instead of expensive RDS.

**Estimated Cost:** FREE to minimal cost (if you upgrade to t3.small).

---

## How Code Reaches the Cloud

If you've never deployed to the cloud, you might be wondering how your Python scripts actually get to AWS. 

In a modern Kubernetes setup, **you do not upload program files directly to the server**. Instead, the flow looks like this:

1. **Bake (Dockerize):** We package your source code along with Python and all dependencies into a single, immutable package called a **Docker Image**. We use the `Dockerfile` to do this.
2. **Store (Docker Hub):** We upload this "baked" image to a central repository like **Docker Hub**, just like how you upload source code to GitHub. Your repository handles this automatically via the `.github/workflows/build-push.yaml` GitHub Action! Whenever you push code to GitHub, it automatically builds the image and sends it to Docker Hub.
3. **Deploy (Kubernetes):** Inside `k8s/app-deployment.yaml`, we tell Kubernetes which image to run (e.g. `image: yourdockerhubusername/moodlite:latest`). When you run `kubectl apply`, your AWS EC2 instance connects to Docker Hub, downloads the pre-baked image, and spins it up.

**Key Takeaway:** You never manually copy code files. You push to GitHub, a Docker Image is built centrally, and your AWS cluster simply downloads and runs that finished Image!

---

## Launch EC2 Instance

1. Go to [AWS EC2 Console](https://console.aws.amazon.com/ec2)
2. Click **"Launch instances"**
3. Select **"Ubuntu Server 22.04 LTS (HVM)"**
4. Select instance type: **t2.micro** (Free tier) or **t3.small** (better performance for Kubernetes).
5. **Key Pair**: Create or select an existing key pair (e.g. `moodlite-keypair`) and download the `.pem` file.
6. **Network Settings**:
    - Allow SSH traffic from Anywhere
    - Allow HTTP traffic from Anywhere
    - Allow HTTPS traffic from Anywhere
    - Create a custom TCP rule allowing port `6443` (for remote `kubectl` access).
7. **Storage**: Allocate 30 GB gp3 volume.
8. Click **Launch instance** and copy the **Public IPv4 address**.

---

## Install K3s on EC2

SSH into your newly created EC2 instance:
```bash
ssh -i moodlite-keypair.pem ubuntu@<YOUR-EC2-PUBLIC-IP>
```

Prepare the persistent volume directory for PostgreSQL:
```bash
sudo mkdir -p /mnt/moodlite-data
sudo chmod 777 /mnt/moodlite-data
```

Install K3s using the official installation script. We explicitly expose the Kubernetes API so your laptop can connect to it remotely, and disable Traefik (the default K3s ingress) because your manifests use NGINX Ingress:
```bash
curl -sfL https://get.k3s.io | sh -s - server \
  --tls-san <YOUR-EC2-PUBLIC-IP> \
  --write-kubeconfig-mode 644 \
  --disable traefik
```

Verify K3s is running:
```bash
kubectl get nodes
```

---

## Configure Local kubectl Access

Instead of SSH-ing into the server to deploy updates, we'll connect your laptop's `kubectl` directly to the K3s cluster.

On the EC2 instance, view the configuration file:
```bash
cat /etc/rancher/k3s/k3s.yaml
```
Copy all the contents of this file.

On your **local laptop**, create a new file or merge it into your `~/.kube/config`. Alternatively, you can just create a new file `~/.kube/k3s-config` on your laptop, paste the contents, and update the server IP:
```yaml
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: <data>
    server: https://<YOUR-EC2-PUBLIC-IP>:6443  # CHANGE THIS IP TO EC2 PUBLIC IP!
  name: default
...
```

Export the config on your local laptop to use it:
```bash
export KUBECONFIG=~/.kube/k3s-config

# Verify connection from your laptop!
kubectl get nodes
```

---

## Deploy MoodLite Manifests

Since your `k8s/ingress.yaml` uses NGINX Ingress, we first need to install the NGINX Ingress Controller to your K3s cluster (from your laptop):

```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.2/deploy/static/provider/cloud/deploy.yaml
```

Wait until the ingress-nginx-controller pod is running in the `ingress-nginx` namespace.

Now apply your MoodLite manifests exactly as you do with Minikube:

```bash
# Assuming you are in the moodlite project root on your laptop
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/secret.yaml
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/postgres-pv.yaml
kubectl apply -f k8s/postgres-pvc.yaml
kubectl apply -f k8s/postgres-deployment.yaml
kubectl apply -f k8s/postgres-service.yaml
kubectl apply -f k8s/app-deployment.yaml
kubectl apply -f k8s/app-service.yaml
```

Wait for the pods to become ready:
```bash
kubectl get pods -n moodlite -w
```

### Ingress Setup

Finally, apply your `ingress.yaml` file:

```bash
kubectl apply -f k8s/ingress.yaml
```
*Note: If your ingress is mapped to `moodlite.local`, you will need to map your EC2 IP to `moodlite.local` in your laptop's `/etc/hosts` file, or update `ingress.yaml` to match the EC2 public DNS.*

---

## Access the Application

Once pods are running, the application will be exposed via the Ingress controller on port 80 of your EC2 instance. 

You can now visit `http://<YOUR-EC2-PUBLIC-IP>` (or your mapped domain name) in your browser. 

You successfully replaced a messy Docker Compose setup with a highly scalable, real Kubernetes cluster on the AWS Free Tier!
