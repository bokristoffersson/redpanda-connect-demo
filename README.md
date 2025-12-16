# Set Up GitOps for the Redpanda Helm Chart

## Overview

This guide explains how to deploy Redpanda using GitOps principles with Flux on a local Kubernetes cluster. GitOps leverages Git as the authoritative source for infrastructure configuration, enabling automated deployments and continuous monitoring.

## Key Benefits of Using Flux

- **Version Control**: Track changes, collaborate, and revert to previous configurations if needed
- **Drift Detection**: Flux monitors cluster state and automatically corrects deviations from desired configurations
- **Collaboration**: Teams can propose changes through pull requests with built-in code review capabilities

## Prerequisites

You'll need:
- A GitHub account
- Flux CLI installed
- kubectl (v1.24+) and Helm (v3.6.0+)
- kind and Docker

## Repository Structure

This repository follows a standard GitOps structure:

```
.
├── clusters/
│   └── local-kind/          # Cluster-specific configuration
│       ├── infrastructure.yaml
│       └── kustomization.yaml
└── infrastructure/          # Infrastructure components
    ├── namespaces/          # Kubernetes namespaces
    ├── sources/             # Helm repository sources
    ├── cert-manager/        # cert-manager deployment
    └── redpanda/            # Redpanda deployment
```
The main steps involve:

1. Creating a local Kubernetes cluster with one control plane and three worker nodes using kind
```
cat <<EOF >kind.yaml
---
apiVersion: kind.x-k8s.io/v1alpha4
kind: Cluster
nodes:
  - role: control-plane
  - role: worker
  - role: worker
  - role: worker
EOF
```
```
kind create cluster --config kind.yaml
```
2. Forking this repository
3. Running `flux bootstrap github` with your credentials and the path `clusters/local-kind`
4. Verifying deployment success via HelmRelease status

## Run this example
Fork this repository, and configure Flux to connect to your fork and deploy the Redpanda Helm chart.

[NOTE]
====
Make sure to do the following:

- Provide Flux with your https://fluxcd.io/flux/installation/bootstrap/github/#github-pat[GitHub personal access token (PAT)].
- Configure the `path` flag with the value `kubernetes/gitops-helm`. This is the path where the example manifests are stored in the repository.
====

Export your GITHUB values:
```
export GITHUB_USER=<github_user_name>
export GITHUB_REPO=<name_of_repo>
export GITHUB_TOKEN=<your_github_token>
```

Example bootstrap command:
```bash
flux bootstrap github \
  --token-auth \
  --owner=$GITHUB_USER \
  --repository=$GITHUB_REPO \
  --path=clusters/local-kind \
  --branch=main \
  --personal
```

## Managing Updates

Configuration changes are made to the Helm release files in the `infrastructure/` directory, then automatically applied by Flux upon Git push.

To update Redpanda configuration, edit `infrastructure/redpanda/release.yaml` and commit the changes. Flux will detect and apply the updates automatically.

## Verifying Deployment

Check the status of your deployments:
```bash
# Check all Flux kustomizations
flux get kustomizations

# Check HelmReleases
flux get helmreleases -A

# Check Redpanda pods
kubectl get pods -n redpanda
```

== Delete the cluster

To delete the Kubernetes cluster as well as all the Docker resources that kind created, run:

[,bash]
----
kind delete cluster
----
