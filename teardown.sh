#!/bin/bash

echo "========================================="
echo "Redpanda Connect GitOps Demo Teardown"
echo "========================================="
echo ""

# Confirm before destruction
read -p "This will delete the kind cluster 'redpanda-demo' and all data. Continue? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 1
fi

echo ""
echo "[1/2] Deleting kind cluster..."
if kind get clusters | grep -q "redpanda-demo"; then
    kind delete cluster --name redpanda-demo
    echo "✓ Cluster deleted"
else
    echo "Cluster 'redpanda-demo' not found. Nothing to delete."
fi

echo ""
echo "[2/2] Cleanup complete!"
echo ""
echo "========================================="
echo "The demo environment has been removed."
echo "========================================="
echo ""
echo "To recreate the demo, run: ./setup.sh"
echo ""
echo "NOTE: Your Git repository still contains all the configuration files."
echo "To clean up the repository, you'll need to manually delete it from GitHub."
echo ""
