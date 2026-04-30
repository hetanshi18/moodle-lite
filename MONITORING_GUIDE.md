# MoodLite AWS Monitoring Guide (Kubernetes-Native)

This guide shows you how to securely monitor your production AWS K3s cluster seamlessly from your local laptop, without convoluted SSH tunnels.

---

## Table of Contents

1. [Overview](#overview)
2. [Install kube-prometheus-stack](#install-kube-prometheus-stack)
3. [Port-Forward to Your Laptop](#port-forward-to-your-laptop)
4. [Customizing Dashboards](#customizing-dashboards)
5. [Monitoring Checkup](#monitoring-checkup)

---

## Overview

Since your application now runs on K3s Kubernetes in AWS, we can use the **industry standard** approach for monitoring: `kube-prometheus-stack` via Helm. 

By utilizing Kubernetes securely over the network via your `kubeconfig`, you can view the Grafana dashboards running securely within AWS directly from `localhost:3000` on your laptop!

---

## Install kube-prometheus-stack

We will use Helm to install Prometheus and Grafana directly into your K3s cluster. 

*Prerequisites: ensure your `KUBECONFIG` is pointing to your AWS K3s cluster (see AWS_DEPLOYMENT.md).*

```bash
# 1. Add the prometheus-community Helm repo (local laptop)
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# 2. Create a monitoring namespace inside the cluster
kubectl create namespace monitoring

# 3. Install the Prometheus/Grafana stack
helm install monitoring prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --set alertmanager.enabled=false \
  --set prometheus.prometheusSpec.retention='7d'
```

Wait roughly 2 minutes for the monitoring pods to spin up inside your AWS K3s cluster:
```bash
kubectl get pods -n monitoring -w
```
*(You should see `prometheus`, `grafana`, `kube-state-metrics`, and `node-exporter` pods running)*

---

## Port-Forward to Your Laptop

With Kubernetes, you **do not** need to expose internal administration dashboards (like Grafana) to the public internet via AWS Security Groups or Ingress. Instead, you securely tunnel the connection over the Kubernetes API using `kubectl port-forward`.

On your **local laptop**, run:
```bash
kubectl port-forward svc/monitoring-grafana 3000:80 -n monitoring
```

**What this does:** It bridges your laptop's `localhost:3000` directly to the Grafana pod running securely inside your AWS EC2 cluster.

Open your browser to: **http://localhost:3000**

**Login Credentials:**
- **Username:** `admin`
- **Password:** `prom-operator` (This is the default password Helm generates, you'll be prompted to change it).

---

## Customizing Dashboards

`kube-prometheus-stack` automatically sets up dozens of beautiful dashboards for Kubernetes! 

Inside Grafana:
1. Click **Dashboards** > **Browse**
2. Check out `Kubernetes / Compute Resources / Namespace (Pods)` to see the resource usage of your `moodlite` namespace.
3. Check out `Node / USE Method / Node Dashboard` to see the CPU and memory of your EC2 instance.

Everything works out of the box because K3s is fully CNCF certified and exposes standard kubelet metrics.

---

## Monitoring Checkup

If you ever need to quickly verify application health without opening Grafana, you can check K3s node metrics and pod health straight from your laptop terminal:

```bash
# Check node CPU/Memory usage
kubectl top nodes

# Check exactly how much RAM your app pods are using
kubectl top pods -n moodlite

# Instantly stream logs from the active production app
kubectl logs -f deployment/moodlite-app -n moodlite
```

**Happy monitoring! 📊**
