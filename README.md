# Redpanda Connect GitOps Demo

A comprehensive demonstration of **Redpanda Connect** deployed on Kubernetes with **GitOps** using Flux. This demo showcases a file upload and processing pipeline with real-time data transformation and fan-out to multiple destinations.

## Overview

This demo illustrates the power of:
- **Redpanda**: 10x lower latency, 3-6x cost efficiency vs Kafka
- **Redpanda Connect**: 300+ connectors, 3x less compute than Kafka Connect (128MB vs 2-4GB)
- **GitOps with Flux**: Continuous reconciliation, drift detection, Git as single source of truth

## Architecture

```
Upload Web UI → Redpanda Connect → Redpanda Topics → Multiple Outputs
     (CSV/JSON)         ↓                 ↓              ↓
                  Transform         Durable Storage  MinIO (S3)
                 (CSV→JSON)                          Mock API
                                                     Webhook
```

**Components**:
- kind cluster (4 nodes: 1 control-plane, 3 workers)
- Redpanda (3-broker cluster)
- Redpanda Console (web UI)
- Redpanda Connect (file processing pipeline)
- MinIO (S3-compatible storage)
- Upload Web UI (drag-and-drop interface)
- Mock API (webhook receiver)
- Prometheus + Grafana (monitoring)
- Flux (GitOps controller)

## Quick Start

### Prerequisites

- Docker installed and running
- 8GB RAM available
- GitHub account with personal access token

### Setup

```bash
# 1. Clone or create repository
git clone https://github.com/${GITHUB_USER}/redpanda-connect-demo
cd redpanda-connect-demo

# 2. Set environment variables
export GITHUB_TOKEN=<your-github-token>
export GITHUB_USER=<your-github-username>
export GITHUB_REPO=redpanda-connect-demo

# 3. Run setup
./setup.sh
```

**Note**: Setup takes 5-10 minutes for all components to be ready.

### Access Services

Once deployed, access these URLs:

- **Upload UI**: http://localhost:8085 (main demo interface)
- **Redpanda Console**: http://localhost:8080 (view topics and messages)
- **MinIO Console**: http://localhost:9000 (view stored files - minioadmin/minioadmin)
- **Mock API**: http://localhost:9090 (view webhook notifications)
- **Grafana**: http://localhost:3000 (monitoring - admin/admin)

### Try the Demo

1. Open the Upload UI at http://localhost:8085
2. Upload the sample file `docs/sample-data/sample-orders.csv`
3. Watch the file get processed in real-time
4. View results in all three destinations:
   - **Redpanda Console**: Topic `files.processed` with individual row messages
   - **MinIO**: Transformed JSON file in `uploads` bucket
   - **Mock API**: Webhook notification with processing summary

## Demo Flow

### File Upload Demo

```bash
# Upload a file via the web UI or directly via API
curl -F "file=@docs/sample-data/sample-orders.csv" http://localhost:4195/upload
```

### Verify Data Flow

**Redpanda Console** (http://localhost:8080):
- Navigate to Topics → `files.processed`
- See each row as a separate message
- View message details with metadata

**MinIO** (http://localhost:9000):
- Browse the `uploads` bucket
- Download the transformed JSON file
- See file timestamps and metadata

**Mock API** (http://localhost:9090):
- View the webhook notification
- See processing summary with record count
- Check notification timestamp

### GitOps Demonstration

```bash
# 1. Make a change to the pipeline
# Edit apps/redpanda-connect/pipeline.yaml to add a new transformation

# 2. Commit and push
git add apps/redpanda-connect/pipeline.yaml
git commit -m "Add order priority calculation"
git push origin main

# 3. Watch Flux reconcile
flux get kustomizations --watch

# 4. Verify deployment
kubectl rollout status deployment/redpanda-connect -n demo

# 5. Test with same file - see new transformation applied
```

### Drift Detection Demo

```bash
# 1. Manually change replicas (simulate drift)
kubectl scale deployment/redpanda-connect -n demo --replicas=2

# 2. Watch Flux auto-remediate (within 5 minutes)
flux reconcile kustomization apps --with-source

# 3. Verify it's back to 1 replica
kubectl get deployment redpanda-connect -n demo
```

## Key Comparisons

### Redpanda vs Kafka

| Aspect | Kafka | Redpanda |
|--------|-------|----------|
| Nodes (HA Setup) | 9-12 | 3 |
| Latency | Baseline | 10x lower |
| Cost | Baseline | 3-6x lower |
| Dependencies | Zookeeper, Schema Registry | None, built-in |
| Memory per broker | 4-8GB+ | 2GB |

### Redpanda Connect vs Kafka Connect

| Aspect | Kafka Connect | Redpanda Connect |
|--------|---------------|------------------|
| Memory | 2-4GB/worker | 128MB total |
| Deployment | Cluster (3+ nodes) | Single pod |
| Connectors | Plugin-based | 300+ built-in |
| Configuration | REST API + JSON | Declarative YAML |
| Transformations | SMT only | Bloblang processor |

### GitOps vs CI/CD Pipelines

| Aspect | CI/CD Pipelines | GitOps (Flux) |
|--------|-----------------|---------------|
| Model | Push | Pull |
| Credentials | In CI system | In cluster only |
| Drift Detection | Manual | Automatic |
| Rollback | Re-run pipeline | git revert |
| Audit Trail | CI logs + Git | Git only |

## Monitoring

Access Grafana at http://localhost:3000 (admin/admin) to view:
- Redpanda cluster metrics
- Redpanda Connect processing metrics
- File upload throughput
- Message processing rates

## Cleanup

```bash
./teardown.sh
```

This removes the kind cluster but preserves your Git repository.

## Repository Structure

```
.
├── kind/                   # kind cluster configuration
├── clusters/local-kind/    # Flux cluster reconciliation
├── infrastructure/         # Infrastructure components
│   ├── namespaces/
│   ├── sources/            # Helm repositories
│   ├── cert-manager/
│   ├── redpanda/
│   ├── redpanda-console/
│   └── monitoring/
├── apps/                   # Application deployments
│   ├── minio/
│   ├── upload-ui/
│   ├── mock-api/
│   └── redpanda-connect/
└── docs/                   # Documentation
    ├── DEMO_SCRIPT.md
    └── sample-data/
```

## Troubleshooting

### Flux not reconciling

```bash
flux get all
flux logs --level=error
flux reconcile kustomization infrastructure --with-source
```

### Pods not starting

```bash
kubectl get pods -A
kubectl describe pod <pod-name> -n <namespace>
kubectl logs <pod-name> -n <namespace>
```

### Port conflicts

```bash
# Check which ports are in use
lsof -i :8080,8085,9000,9090,3000,4195

# Modify kind/cluster-config.yaml if needed
```

## Resources

- [Redpanda Documentation](https://docs.redpanda.com)
- [Redpanda Connect Docs](https://docs.redpanda.com/redpanda-connect)
- [Flux Documentation](https://fluxcd.io)
- [Demo Script](docs/DEMO_SCRIPT.md)

## License

MIT
