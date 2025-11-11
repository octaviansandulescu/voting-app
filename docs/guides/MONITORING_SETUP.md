# Phase 3.2: Monitoring Setup Guide

**Estimated Time**: 15 minutes | **Difficulty**: Intermediate | **Prerequisites**: KUBERNETES_SETUP.md, TESTING_CICD.md

## Overview

In this guide, you'll set up Prometheus and Grafana to monitor your production application. This is the "observability" pillar of DevOPS - you can't manage what you don't measure.

**What you'll learn**:
- ✅ How to collect application metrics with Prometheus
- ✅ How to visualize metrics with Grafana
- ✅ How to set up alerts for critical issues
- ✅ How to troubleshoot production problems
- ✅ How to understand application health

## The Three Pillars of Observability

### 1. Metrics (Numbers)
- Response time
- Error rate
- CPU usage
- Memory usage
- Disk usage
- Requests per second

### 2. Logs (Events)
- API request logs
- Error stack traces
- Deployment events
- Database queries

### 3. Traces (Distributed Calls)
- Request path through services
- Time spent in each service
- Bottlenecks and slow calls

**This guide covers Metrics (Prometheus) and Dashboards (Grafana)**

## Step 1: Understand Prometheus and Grafana

### 1.1 How Prometheus Works

```
Your Application
       ↓
   Exposes Metrics
   (http://app:8000/metrics)
       ↓
  Prometheus Scrapes
   (every 15 seconds)
       ↓
   Stores Time Series
   (database of metrics over time)
       ↓
  Queries Metrics
       ↓
   Grafana Visualizes
```

### 1.2 Metrics Example

```python
# Your application exposes:
# TYPE voting_votes_total counter
voting_votes_total{vote="dogs"} 125
voting_votes_total{vote="cats"} 98

# TYPE voting_vote_duration_seconds histogram
voting_vote_duration_seconds_bucket{le="0.1"} 1543
voting_vote_duration_seconds_bucket{le="0.5"} 1876
voting_vote_duration_seconds_bucket{le="1.0"} 1889

# TYPE voting_api_errors_total counter
voting_api_errors_total{endpoint="/vote",error_type="database"} 3
voting_api_errors_total{endpoint="/results",error_type="timeout"} 1
```

## Step 2: Add Prometheus Client Library

### 2.1 Install Prometheus Client

```bash
cd src/backend

# Add to requirements.txt
echo "prometheus-client==0.19.0" >> requirements.txt

# Or install directly
pip install prometheus-client==0.19.0
```

### 2.2 Check requirements.txt

```bash
cat src/backend/requirements.txt

# Should have:
# fastapi
# uvicorn
# mysql-connector-python
# pytest
# prometheus-client  ← NEW
```

## Step 3: Instrument Your Application

### 3.1 Add Metrics to Backend

Edit `src/backend/main.py` and add at the top:

```python
from prometheus_client import Counter, Histogram, generate_latest, CONTENT_TYPE_LATEST
from prometheus_client import CollectorRegistry
from prometheus_client.wsgi import make_wsgi_app
from fastapi import Response
import time

# Create registry
registry = CollectorRegistry()

# Define metrics
votes_total = Counter(
    'voting_votes_total',
    'Total votes submitted',
    ['vote'],
    registry=registry
)

vote_duration = Histogram(
    'voting_vote_duration_seconds',
    'Time spent submitting a vote',
    registry=registry
)

api_requests_total = Counter(
    'voting_api_requests_total',
    'Total API requests',
    ['endpoint', 'method', 'status'],
    registry=registry
)

api_errors_total = Counter(
    'voting_api_errors_total',
    'Total API errors',
    ['endpoint', 'error_type'],
    registry=registry
)
```

### 3.2 Add Metrics Endpoint

```python
@app.get("/metrics")
async def metrics():
    """Prometheus metrics endpoint"""
    return Response(
        generate_latest(registry),
        media_type=CONTENT_TYPE_LATEST
    )
```

### 3.3 Instrument Vote Endpoint

```python
@app.post("/vote")
async def submit_vote(vote_request: VoteRequest):
    """Submit a vote - with metrics"""
    start_time = time.time()
    
    try:
        # Your existing vote logic
        vote = vote_request.vote.lower()
        
        if vote not in ["dogs", "cats"]:
            raise ValueError("Invalid vote")
        
        # Record metric
        votes_total.labels(vote=vote).inc()
        
        # Submit to database
        # ... existing code ...
        
        # Record request
        api_requests_total.labels(
            endpoint="/vote",
            method="POST",
            status=200
        ).inc()
        
        return {"message": "Vote recorded", "vote": vote}
    
    except Exception as e:
        # Record error
        api_errors_total.labels(
            endpoint="/vote",
            error_type=type(e).__name__
        ).inc()
        
        raise
    
    finally:
        # Record duration
        duration = time.time() - start_time
        vote_duration.observe(duration)
```

### 3.4 Test Metrics Endpoint

```bash
# Start application
cd src/backend
uvicorn main:app --host 0.0.0.0 --port 8000 &

# View metrics
curl http://localhost:8000/metrics

# Should see:
# # HELP voting_votes_total Total votes submitted
# # TYPE voting_votes_total counter
# voting_votes_total{vote="dogs"} 0.0
# voting_votes_total{vote="cats"} 0.0
```

## Step 4: Deploy Prometheus and Grafana to Kubernetes

### 4.1 Create Monitoring Namespace

```bash
kubectl create namespace monitoring

# Set default namespace
kubectl config set-context --current --namespace=monitoring
```

### 4.2 Install Prometheus Operator (Recommended)

Using Helm (simpler):

```bash
# Add Prometheus Helm repo
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Install Prometheus stack
helm install prometheus prometheus-community/kube-prometheus-stack \
  -n monitoring \
  --set prometheus.prometheusSpec.retention=15d \
  --set grafana.adminPassword=admin123

# Wait for pods
kubectl -n monitoring get pods -w
```

### 4.3 Manual Installation (If not using Helm)

Create `prometheus-deployment.yaml`:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: prometheus-config
  namespace: monitoring
data:
  prometheus.yml: |
    global:
      scrape_interval: 15s
    scrape_configs:
      - job_name: 'voting-app-backend'
        static_configs:
          - targets: ['voting-app-backend.voting-app:8000']
      - job_name: 'kubernetes-pods'
        kubernetes_sd_configs:
          - role: pod
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: prometheus
  namespace: monitoring
spec:
  replicas: 1
  selector:
    matchLabels:
      app: prometheus
  template:
    metadata:
      labels:
        app: prometheus
    spec:
      containers:
      - name: prometheus
        image: prom/prometheus:latest
        ports:
        - containerPort: 9090
        volumeMounts:
        - name: config
          mountPath: /etc/prometheus
        - name: data
          mountPath: /prometheus
      volumes:
      - name: config
        configMap:
          name: prometheus-config
      - name: data
        emptyDir: {}
---
apiVersion: v1
kind: Service
metadata:
  name: prometheus
  namespace: monitoring
spec:
  selector:
    app: prometheus
  ports:
  - port: 9090
    targetPort: 9090
  type: LoadBalancer
```

Deploy:
```bash
kubectl apply -f prometheus-deployment.yaml
```

### 4.4 Deploy Grafana

Create `grafana-deployment.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: grafana
  namespace: monitoring
spec:
  replicas: 1
  selector:
    matchLabels:
      app: grafana
  template:
    metadata:
      labels:
        app: grafana
    spec:
      containers:
      - name: grafana
        image: grafana/grafana:latest
        ports:
        - containerPort: 3000
        env:
        - name: GF_SECURITY_ADMIN_PASSWORD
          value: admin123
        volumeMounts:
        - name: storage
          mountPath: /var/lib/grafana
      volumes:
      - name: storage
        emptyDir: {}
---
apiVersion: v1
kind: Service
metadata:
  name: grafana
  namespace: monitoring
spec:
  selector:
    app: grafana
  ports:
  - port: 3000
    targetPort: 3000
  type: LoadBalancer
```

Deploy:
```bash
kubectl apply -f grafana-deployment.yaml

# Get external IP
kubectl -n monitoring get service grafana
```

## Step 5: Configure Grafana Data Source

### 5.1 Access Grafana

```bash
# Get external IP
GRAFANA_IP=$(kubectl -n monitoring get service grafana \
  -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

# Open in browser
open http://${GRAFANA_IP}:3000

# Or use SSH tunnel
kubectl -n monitoring port-forward svc/grafana 3000:3000
```

Default credentials:
- Username: `admin`
- Password: `admin123` (or whatever you set)

### 5.2 Add Prometheus Data Source

1. Click Configuration (gear icon) → Data Sources
2. Click "Add data source"
3. Select "Prometheus"
4. Set URL to: `http://prometheus:9090`
5. Click "Save & Test"

Should show: "Data source is working"

## Step 6: Create Dashboards

### 6.1 Import Community Dashboard

Grafana has community dashboards:

1. Click "+" → Import
2. Enter dashboard ID: `1860` (Node Exporter dashboard)
3. Select Prometheus data source
4. Click "Import"

### 6.2 Create Custom Dashboard

Create dashboard for voting app:

1. Click "+" → Dashboard
2. Click "Add panel"
3. Create panels for:
   - **Total Votes**: `voting_votes_total`
   - **Vote Rate**: `rate(voting_votes_total[5m])`
   - **API Errors**: `voting_api_errors_total`
   - **Response Time**: `voting_vote_duration_seconds`

### 6.3 Example Dashboard Query

For "Votes per Second":

```promql
# Query
rate(voting_votes_total[5m])

# This shows: votes received per second in last 5 minutes
```

For "Error Rate":

```promql
# Query
rate(voting_api_errors_total[5m]) / rate(voting_api_requests_total[5m]) * 100

# This shows: percentage of requests that errored
```

## Step 7: Set Up Alerts

### 7.1 Create Alert Rules

Create `prometheus-rules.yaml`:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: prometheus-rules
  namespace: monitoring
data:
  alerts.yml: |
    groups:
    - name: voting-app
      rules:
      - alert: HighErrorRate
        expr: rate(voting_api_errors_total[5m]) > 0.05
        for: 5m
        annotations:
          summary: "High error rate detected"
          description: "Error rate is above 5%"
      
      - alert: PodRestarting
        expr: rate(kube_pod_container_status_restarts_total[15m]) > 0.1
        for: 5m
        annotations:
          summary: "Pod is restarting frequently"
          description: "Pod restarts detected"
      
      - alert: HighMemoryUsage
        expr: container_memory_usage_bytes > 512000000
        for: 5m
        annotations:
          summary: "High memory usage"
          description: "Memory usage above 512MB"
```

Apply:
```bash
kubectl apply -f prometheus-rules.yaml
```

### 7.2 Configure Alert Notification

In Prometheus, configure where alerts go:
- Email
- Slack
- PagerDuty
- Webhook

Example Slack webhook configuration in Prometheus:

```yaml
global:
  slack_api_url: 'https://hooks.slack.com/services/YOUR/WEBHOOK/URL'

route:
  receiver: 'slack'
  routes:
  - match:
      severity: critical
    receiver: 'pagerduty'
```

## Step 8: Key Metrics to Monitor

### Application Health

```promql
# Is the application responding?
up{job="voting-app-backend"}

# Request rate
rate(voting_api_requests_total[5m])

# Error rate
rate(voting_api_errors_total[5m])

# Response time (99th percentile)
histogram_quantile(0.99, voting_vote_duration_seconds)
```

### Infrastructure Health

```promql
# Pod restart count
rate(kube_pod_container_status_restarts_total[15m])

# CPU usage
container_cpu_usage_seconds_total

# Memory usage
container_memory_usage_bytes

# Disk usage
kubelet_volume_stats_used_bytes
```

### Database Health

```promql
# MySQL connections
mysql_global_status_threads_connected

# Slow queries
mysql_global_status_slow_queries

# Query time
mysql_slave_status_seconds_behind_master
```

## Step 9: Prometheus Query Language (PromQL)

### Common Queries

```promql
# Get current value
voting_votes_total

# Get rate over 5 minutes
rate(voting_votes_total[5m])

# Count rate per label
sum by (vote) (rate(voting_votes_total[5m]))

# Get value 5 minutes ago
voting_votes_total offset 5m

# Alert if value > 10
voting_api_errors_total > 10

# Alert if rate > 0.1/sec for 5 minutes
rate(voting_api_errors_total[5m]) > 0.1

# 95th percentile
histogram_quantile(0.95, voting_vote_duration_seconds)
```

## Step 10: Troubleshooting with Metrics

### Problem: Application is slow

**Query**:
```promql
histogram_quantile(0.99, voting_vote_duration_seconds)
```

**Actions**:
- If p99 > 1 second: Profile application
- Check database connection pool
- Check CPU usage

### Problem: High error rate

**Query**:
```promql
rate(voting_api_errors_total[5m]) / rate(voting_api_requests_total[5m])
```

**Actions**:
- Check logs for error messages
- Check database connectivity
- Check memory usage (OOM errors?)

### Problem: Pod restarts

**Query**:
```promql
rate(kube_pod_container_status_restarts_total[15m])
```

**Actions**:
- Check logs for crash reason
- Check resource limits
- Check for OOM killer

## Step 11: Grafana Best Practices

### Dashboard Layout

Good dashboard has:
- ✅ 3-5 key metrics (not 20+)
- ✅ Auto-refresh (30 seconds)
- ✅ Clear titles and legends
- ✅ Meaningful thresholds
- ✅ Alert status visible

### Alerting Best Practices

```yaml
Good Alert:
- Name: HighErrorRate
- Threshold: 5% for 5 minutes
- Action: Page on-call engineer

Bad Alert:
- Name: errors_high
- Threshold: 1 error ever
- Action: ???
- Result: Alert fatigue, alerts ignored
```

## Step 12: Monitoring Checklist

Before going to production, verify:

- ✅ Prometheus is scraping metrics
- ✅ Grafana can query Prometheus
- ✅ At least one custom dashboard created
- ✅ Alert rules are defined
- ✅ Alert notifications are working
- ✅ Historical data is being retained (7+ days)
- ✅ On-call engineer knows how to use dashboards
- ✅ Runbooks exist for each alert

Check Prometheus scrape status:

```bash
# Access Prometheus UI
kubectl port-forward svc/prometheus 9090:9090

# Open http://localhost:9090
# Go to Status → Targets
# All should be "UP"
```

## Step 13: Useful Dashboards to Create

### Dashboard 1: Application Overview
- Total votes per second
- Vote breakdown (dogs vs cats)
- Error rate
- Average response time

### Dashboard 2: Infrastructure Health
- Pod restart rate
- CPU usage per pod
- Memory usage per pod
- Network I/O

### Dashboard 3: Database Metrics
- Active connections
- Queries per second
- Query response time
- Replication lag

## Step 14: Performance Optimization Using Metrics

### Slow Endpoint Detection

```promql
# Which endpoints are slow?
histogram_quantile(0.95, rate(voting_vote_duration_seconds_bucket[5m]))
```

**If vote endpoint is slow**:
1. Add database index
2. Cache results
3. Connection pooling
4. Async processing

### Error Pattern Detection

```promql
# What errors are most common?
topk(5, voting_api_errors_total)
```

**If database errors dominant**:
1. Check connection pool
2. Check database performance
3. Add retry logic
4. Circuit breaker pattern

## Step 15: Cost Optimization

### Prometheus Storage

Rule of thumb:
- 1 metric per second = ~15 bytes
- 100 metrics = 1.5 MB per second
- Monthly: ~40 GB

**To reduce**:
- Decrease scrape interval (30s instead of 15s)
- Drop unnecessary metrics
- Reduce retention (7 days instead of 15)

### Infrastructure

- Prometheus: ~2 CPU, 2 GB RAM
- Grafana: ~1 CPU, 1 GB RAM
- Total cost: ~$50-100/month on GKE

## Next Steps

Congratulations! Production monitoring is live! 📊

**What you've accomplished**:
- ✅ Prometheus collecting metrics
- ✅ Grafana dashboards created
- ✅ Alerts configured
- ✅ Can troubleshoot production issues

**Production Monitoring Checklist**:
- ✅ Metrics collection working
- ✅ Dashboards accessible
- ✅ Alerts firing correctly
- ✅ Runbooks documented
- ✅ On-call engineer trained

## Resources

- **Prometheus Documentation**: https://prometheus.io/docs/
- **Grafana Documentation**: https://grafana.com/docs/
- **PromQL Tutorial**: https://prometheus.io/docs/prometheus/latest/querying/examples/
- **Kubernetes Metrics**: https://kubernetes.io/docs/tasks/debug-application-cluster/resource-metrics-pipeline/

---

**Your DevOPS Course is Complete!** 🎉

**What You've Built**:
1. ✅ Testing foundation (TESTING_FUNDAMENTALS.md)
2. ✅ Security practices (SECURITY.md)
3. ✅ Local deployment (LOCAL_SETUP.md)
4. ✅ Docker containerization (DOCKER_SETUP.md)
5. ✅ Kubernetes production (KUBERNETES_SETUP.md)
6. ✅ CI/CD automation (TESTING_CICD.md)
7. ✅ Production monitoring (MONITORING_SETUP.md)

**Next: Project Cleanup and GitHub Deployment**

Continue to Phase 4 → `docs/guides/PROJECT_CLEANUP.md` (to be created)
