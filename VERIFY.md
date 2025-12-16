# Verification Guide

This guide walks you through verifying that your Redpanda GitOps deployment is working correctly.

## Prerequisites

Ensure you have the following tools installed:
- `kubectl` - Kubernetes CLI
- `flux` - Flux CLI
- Access to your Kubernetes cluster

## Step 1: Verify Flux System

Check that Flux is running and healthy:

```bash
# Check Flux components
kubectl get pods -n flux-system

# All pods should be in Running state
```

Expected output: All Flux pods (source-controller, kustomize-controller, helm-controller, notification-controller) should be Running.

## Step 2: Verify GitRepository Sync

Check that Flux is successfully syncing with your Git repository:

```bash
# Check GitRepository status
flux get sources git

# Should show Ready=True
```

Expected output:
```
NAME       	REVISION          	SUSPENDED	READY	MESSAGE
flux-system	main@sha1:xxxxxxxx	False    	True 	stored artifact for revision 'main@sha1:xxxxxxxx'
```

## Step 3: Verify Kustomizations

Check that all Kustomizations are applied successfully:

```bash
# Check all Kustomizations
flux get kustomizations

# Should show Ready=True for both infrastructure and apps
```

Expected output:
```
NAME           	REVISION          	SUSPENDED	READY	MESSAGE
flux-system    	main@sha1:xxxxxxxx	False    	True 	Applied revision: main@sha1:xxxxxxxx
infrastructure 	main@sha1:xxxxxxxx	False    	True 	Applied revision: main@sha1:xxxxxxxx
apps           	main@sha1:xxxxxxxx	False    	True 	Applied revision: main@sha1:xxxxxxxx
```

## Step 4: Verify Helm Repositories

Check that Helm repositories are configured and synced:

```bash
# List all Helm repositories
flux get sources helm -A
```

Expected output:
```
NAMESPACE  	NAME    	REVISION       	SUSPENDED	READY	MESSAGE
flux-system	jetstack	sha256:xxxxxxxx	False    	True 	stored artifact: revision 'sha256:xxxxxxxx'
redpanda   	redpanda	sha256:xxxxxxxx	False    	True 	stored artifact: revision 'sha256:xxxxxxxx'
```

## Step 5: Verify HelmReleases

Check that all Helm charts are successfully deployed:

```bash
# List all HelmReleases across all namespaces
flux get helmreleases -A
```

Expected output:
```
NAMESPACE       	NAME            	REVISION	SUSPENDED	READY	MESSAGE
cert-manager    	cert-manager    	v1.13.3 	False    	True 	Helm install succeeded
redpanda        	redpanda        	5.7.x   	False    	True 	Helm install succeeded
redpanda        	redpanda-console	3.x     	False    	True 	Helm install succeeded
redpanda-connect	redpanda-connect	3.1.0   	False    	True 	Helm install succeeded
```

All HelmReleases should show `READY=True`.

## Step 6: Verify Namespaces

Check that all required namespaces exist:

```bash
# List namespaces
kubectl get namespaces | grep -E "(cert-manager|redpanda)"
```

Expected output:
```
cert-manager        Active   Xm
redpanda            Active   Xm
redpanda-connect    Active   Xm
```

## Step 7: Verify Pods

Check that all pods are running successfully:

```bash
# Check cert-manager pods
kubectl get pods -n cert-manager

# Check Redpanda pods
kubectl get pods -n redpanda

# Check Redpanda Connect pods
kubectl get pods -n redpanda-connect
```

All pods should be in `Running` state with `READY` showing the correct number (e.g., `1/1`).

## Step 8: Verify Redpanda Connect Pipeline

Test the hello world pipeline is working:

```bash
# View the last 20 lines of logs
kubectl logs -n redpanda-connect -l "app.kubernetes.io/name=redpanda-connect" --tail=20
```

Expected output:
```json
{"message":"HELLO, REDPANDA CONNECT!"}
{"message":"HELLO, REDPANDA CONNECT!"}
{"message":"HELLO, REDPANDA CONNECT!"}
...
```

To watch the logs in real-time:

```bash
# Follow logs continuously
kubectl logs -n redpanda-connect -l "app.kubernetes.io/name=redpanda-connect" -f
```

Press `Ctrl+C` to stop following the logs.

## Step 9: Verify Redpanda Broker

Check that the Redpanda broker is healthy:

```bash
# Check Redpanda StatefulSet
kubectl get statefulsets -n redpanda

# Get pod details
kubectl get pods -n redpanda -o wide
```

For a more detailed health check:

```bash
# Execute rpk command inside a Redpanda pod
kubectl exec -n redpanda redpanda-0 -- rpk cluster health
```

Expected output should show all brokers are healthy.

## Step 10: Access Redpanda Console

Redpanda Console provides a web UI to interact with your Redpanda cluster, view topics, messages, consumer groups, and more.

### Option 1: Port Forward (Recommended for Local Development)

Forward the console port to your local machine:

```bash
# Port forward Redpanda Console to localhost:8080
kubectl port-forward -n redpanda svc/redpanda-console 8080:8080
```

Then open your browser to: **http://localhost:8080**

Press `Ctrl+C` to stop port forwarding when done.

### Option 2: Port Forward to a Different Local Port

If port 8080 is already in use:

```bash
# Forward to localhost:9090 instead
kubectl port-forward -n redpanda svc/redpanda-console 9090:8080
```

Then open your browser to: **http://localhost:9090**

### Option 3: Port Forward in Background

To run port-forward in the background:

```bash
# Start port-forward in background
kubectl port-forward -n redpanda svc/redpanda-console 8080:8080 &

# Note the PID to kill it later
# To stop: kill <PID>
```

### What You Can Do in Redpanda Console

Once connected, you can:

1. **View Topics** - See all Kafka topics in your cluster
2. **Browse Messages** - View message contents, headers, and metadata
3. **Monitor Consumer Groups** - Track consumer lag and offsets
4. **Cluster Overview** - View broker health and configuration
5. **Schema Registry** - Manage schemas (if enabled)
6. **ACLs** - View and manage access control lists

### Verify Console is Working

```bash
# Check that the console pod is running
kubectl get pods -n redpanda -l app.kubernetes.io/name=console

# View console logs if needed
kubectl logs -n redpanda -l app.kubernetes.io/name=console
```

### Troubleshooting Console Access

If you can't access the console:

```bash
# Verify the service exists
kubectl get svc -n redpanda redpanda-console

# Check service endpoints
kubectl get endpoints -n redpanda redpanda-console

# Test connectivity from within the cluster
kubectl run -it --rm debug --image=curlimages/curl --restart=Never -- curl -v http://redpanda-console.redpanda.svc.cluster.local:8080
```

## Troubleshooting

### HelmRelease Not Ready

If a HelmRelease shows `READY=False`:

```bash
# Get detailed status
kubectl describe helmrelease <name> -n <namespace>

# Check HelmChart status
kubectl get helmcharts -A

# Force reconciliation
flux reconcile helmrelease <name> -n <namespace>
```

### Pods CrashLooping

If pods are crashing:

```bash
# View pod logs
kubectl logs <pod-name> -n <namespace>

# View previous pod logs (if it restarted)
kubectl logs <pod-name> -n <namespace> --previous

# Describe pod for events
kubectl describe pod <pod-name> -n <namespace>
```

### Flux Not Syncing

If Flux isn't picking up changes from Git:

```bash
# Force reconciliation of GitRepository
flux reconcile source git flux-system

# Force reconciliation of Kustomization
flux reconcile kustomization flux-system --with-source

# Check Flux logs
kubectl logs -n flux-system deploy/source-controller
kubectl logs -n flux-system deploy/kustomize-controller
kubectl logs -n flux-system deploy/helm-controller
```

### Check Flux Events

View recent Flux events:

```bash
# Get events for all Flux resources
flux events --for Kustomization/infrastructure
flux events --for Kustomization/apps
flux events --for HelmRelease/redpanda-connect -n redpanda-connect
```

## Quick Verification Script

Run this one-liner to check everything at once:

```bash
echo "=== Flux Kustomizations ===" && \
flux get kustomizations && \
echo -e "\n=== Helm Repositories ===" && \
flux get sources helm -A && \
echo -e "\n=== HelmReleases ===" && \
flux get helmreleases -A && \
echo -e "\n=== Redpanda Pods ===" && \
kubectl get pods -n redpanda && \
echo -e "\n=== Redpanda Connect Pods ===" && \
kubectl get pods -n redpanda-connect && \
echo -e "\n=== Redpanda Connect Logs (last 5) ===" && \
kubectl logs -n redpanda-connect -l "app.kubernetes.io/name=redpanda-connect" --tail=5
```

## Success Criteria

Your deployment is successful when:

- ✅ All Flux Kustomizations show `READY=True`
- ✅ All HelmReleases show `READY=True` (cert-manager, redpanda, redpanda-console, redpanda-connect)
- ✅ All pods are in `Running` state
- ✅ Redpanda Connect logs show continuous `{"message":"HELLO, REDPANDA CONNECT!"}` output
- ✅ Redpanda Console is accessible via port-forward at http://localhost:8080
- ✅ No error messages in Flux events or pod logs

## Next Steps

Once verification is complete, you can:

1. **Access Redpanda Console** - Port forward and explore your Redpanda cluster through the web UI
2. **Modify the pipeline** - Edit `apps/redpanda-connect/release.yaml` to change the pipeline configuration
3. **Commit and push changes** - Let Flux automatically apply your updates
4. **Create topics** - Use the Console or `rpk` to create Kafka topics
5. **Explore more pipelines** - Check out the [Redpanda Connect documentation](https://docs.redpanda.com/redpanda-connect/) for examples
