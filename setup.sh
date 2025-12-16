#!/bin/bash
set -e

echo "========================================="
echo "Redpanda Connect GitOps Demo Setup"
echo "========================================="
echo ""

# Check prerequisites
echo "[Prerequisites] Checking required tools..."

if ! command -v kind &> /dev/null; then
    echo "ERROR: kind not found. Please install kind first."
    echo "Visit: https://kind.sigs.k8s.io/docs/user/quick-start/#installation"
    exit 1
fi

if ! command -v flux &> /dev/null; then
    echo "ERROR: flux CLI not found. Please install flux first."
    echo "Visit: https://fluxcd.io/flux/installation/"
    exit 1
fi

if ! command -v kubectl &> /dev/null; then
    echo "ERROR: kubectl not found. Please install kubectl first."
    exit 1
fi

if ! command -v docker &> /dev/null; then
    echo "ERROR: docker not found. Please install docker first."
    exit 1
fi

# Check if Docker is running
if ! docker info &> /dev/null; then
    echo "ERROR: Docker is not running. Please start Docker first."
    exit 1
fi

# Check environment variables
if [ -z "$GITHUB_TOKEN" ]; then
    echo "ERROR: GITHUB_TOKEN environment variable is not set."
    echo "Please set it with: export GITHUB_TOKEN=<your-github-token>"
    exit 1
fi

if [ -z "$GITHUB_USER" ]; then
    echo "ERROR: GITHUB_USER environment variable is not set."
    echo "Please set it with: export GITHUB_USER=<your-github-username>"
    exit 1
fi

if [ -z "$GITHUB_REPO" ]; then
    echo "WARNING: GITHUB_REPO not set, using default 'redpanda-connect-demo'"
    export GITHUB_REPO="redpanda-connect-demo"
fi

echo "✓ All prerequisites met"
echo ""

# Step 1: Create kind cluster
echo "[1/5] Creating kind cluster..."
if kind get clusters | grep -q "redpanda-demo"; then
    echo "Cluster 'redpanda-demo' already exists. Skipping creation."
else
    kind create cluster --config kind/cluster-config.yaml
    echo "✓ Cluster created"
fi
echo ""

# Step 2: Verify cluster
echo "[2/5] Verifying cluster..."
kubectl cluster-info --context kind-redpanda-demo
kubectl get nodes
echo "✓ Cluster verified"
echo ""

# Step 3: Bootstrap Flux
echo "[3/5] Bootstrapping Flux..."
flux check --pre

# Bootstrap Flux with GitHub
flux bootstrap github \
  --token-auth \
  --owner=${GITHUB_USER} \
  --repository=${GITHUB_REPO} \
  --branch=main \
  --path=clusters/local-kind \
  --personal

echo "✓ Flux bootstrapped"
echo ""

# Step 4: Wait for Flux to be ready
echo "[4/5] Waiting for Flux to be ready..."
echo "This may take a few minutes..."

kubectl wait --for=condition=ready --timeout=5m \
  -n flux-system pod -l app=source-controller || true

kubectl wait --for=condition=ready --timeout=5m \
  -n flux-system pod -l app=kustomize-controller || true

kubectl wait --for=condition=ready --timeout=5m \
  -n flux-system pod -l app=helm-controller || true

echo "✓ Flux is ready"
echo ""

# Step 5: Verify Flux installation
echo "[5/5] Verifying Flux installation..."
flux get sources git
flux get kustomizations
echo "✓ Flux verified"
echo ""

echo "========================================="
echo "Setup Complete!"
echo "========================================="
echo ""
echo "Flux is now reconciling your GitOps configuration."
echo "This will take 5-10 minutes for all components to be ready."
echo ""
echo "Monitor reconciliation with:"
echo "  flux get all"
echo "  flux get kustomizations --watch"
echo "  kubectl get pods -A"
echo ""
echo "Once ready, access services at:"
echo "  Upload UI:        http://localhost:8085"
echo "  Redpanda Console: http://localhost:8080"
echo "  MinIO Console:    http://localhost:9000 (credentials: minioadmin/minioadmin)"
echo "  Mock API:         http://localhost:9090/notifications"
echo "  Grafana:          http://localhost:3000 (credentials: admin/admin)"
echo ""
echo "View detailed demo instructions: docs/DEMO_SCRIPT.md"
echo ""
