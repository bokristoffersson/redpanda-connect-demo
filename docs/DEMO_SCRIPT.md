# Redpanda Connect GitOps Demo Script

## Preparation (Before Demo)

1. Ensure `./setup.sh` has been run and all pods are ready
2. Have browser tabs open for:
   - Upload UI: http://localhost:8085
   - Redpanda Console: http://localhost:8080
   - MinIO Console: http://localhost:9000
   - Mock API: http://localhost:9090
   - Grafana: http://localhost:3000
3. Have sample files ready: `docs/sample-data/sample-orders.csv`
4. Terminal window with: `kubectl get pods -A` visible

## Part 1: Introduction (2 minutes)

**Script**:

"Today I'm going to demonstrate Redpanda Connect - a modern streaming data platform that solves the same problems as Kafka, but with significantly better performance and lower operational costs.

The key value propositions:
- **Redpanda**: 10x lower latency and 3-6x cost reduction compared to Kafka
- **Redpanda Connect**: Replaces Kafka Connect with 300+ built-in connectors using only 128MB RAM vs 2-4GB
- **GitOps**: Automated deployments with drift detection - no more manual kubectl commands

This entire demo runs on my laptop using kind, but it's production-ready architecture deployed via GitOps."

## Part 2: Architecture Overview (3 minutes)

**Show**: Architecture diagram from README.md

**Script**:

"Let's look at the architecture. The demo showcases a file processing pipeline:

1. Users upload CSV or JSON files via a web interface
2. Redpanda Connect receives, validates, and transforms the data (CSV → JSON)
3. Data flows through Redpanda topics for durability
4. Fan-out to 3 destinations simultaneously:
   - Redpanda topic (streaming data for real-time processing)
   - MinIO S3 storage (transformed file archive)
   - HTTP webhook (processing notification)

This fan-out pattern would require 3 separate Kafka Connect instances with ~6-12GB RAM. With Redpanda Connect, it's one pod using 128MB."

**Show**: `kubectl get pods -n demo`

```bash
kubectl get pods -n demo
# Point out single redpanda-connect pod
```

## Part 3: File Upload Demo (5 minutes)

**Show**: Upload UI at localhost:8085

**Script**:

"Here's our upload interface - clean, simple, drag-and-drop. Let me upload this sample CSV file containing order data."

**Action**: Drag and drop `sample-orders.csv`

**Script**:

"Watch the progress bar... and it's processed! Let's verify the data reached all three destinations."

### Destination 1: Redpanda Console

**Show**: localhost:8080

**Script**:

"First, Redpanda Console. Navigate to Topics → files.processed."

**Action**: Click through to show messages

**Script**:

"See how each row from the CSV became an individual message? This is streaming data - any consumer can process these events in real-time. Notice the metadata we added: processing timestamp, unique ID, calculated fields."

### Destination 2: MinIO Storage

**Show**: localhost:9000 (login: minioadmin/minioadmin)

**Script**:

"Second destination: MinIO S3-compatible storage. Log in with minioadmin/minioadmin."

**Action**: Browse to `uploads` bucket

**Script**:

"Here's our transformed JSON file. We took a CSV input and saved a structured JSON output. This is ready for data lake processing, analytics, or archival."

**Action**: Click to preview/download the file

### Destination 3: Webhook API

**Show**: localhost:9090

**Script**:

"Third destination: our webhook API received a notification. This could trigger downstream workflows, send alerts, or update dashboards."

**Action**: Show the notification details

**Script**:

"Notice we sent the same data to three different destinations with one pipeline. With Kafka Connect, this would require:
- 3 separate connector instances
- 3 separate configurations
- 6-12GB RAM total
- Complex coordination

With Redpanda Connect: 1 pod, 1 YAML file, 128MB RAM."

## Part 4: Redpanda vs Kafka Comparison (3 minutes)

**Script**:

"Let's talk about why Redpanda matters. Traditional Kafka deployments require:

**Kafka Stack (9-12 nodes)**:
- 3 Kafka brokers (4-8GB RAM each)
- 3 Zookeeper nodes (coordination)
- 2-3 Kafka Connect workers (2-4GB RAM each)
- 2 Schema Registry nodes

**Our Redpanda Stack (3 nodes)**:
- 3 Redpanda brokers (everything built-in)

That's 75% fewer servers. In the cloud, this translates to $35K+ annual savings for a medium-scale deployment."

**Show**: `kubectl get pods -n redpanda`

```bash
kubectl get pods -n redpanda
# Show 3 redpanda pods
```

**Script**:

"Three pods. No Zookeeper. No separate Schema Registry. No JVM heap tuning. It just works.

Performance-wise, Redpanda delivers 10x lower latency because it's written in C++ with a thread-per-core architecture, not Java. No garbage collection pauses."

## Part 5: GitOps Workflow Demo (7 minutes)

**Script**:

"Now let's demonstrate GitOps. Instead of running kubectl commands, we'll modify code in Git and watch Flux automatically deploy changes."

### Make a Change

**Action**: Edit `apps/redpanda-connect/pipeline.yaml`

**Script**:

"I'm going to add a new transformation to calculate order priority based on price."

**Edit**:
```yaml
# Add to the "add_calculated_fields" processor:
root.priority = if this.exists("price") {
  if this.price > 100 { "high" }
  else if this.price > 50 { "medium" }
  else { "low" }
} else { "unknown" }
```

### Commit and Push

```bash
git add apps/redpanda-connect/pipeline.yaml
git commit -m "Add order priority calculation

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
git push origin main
```

**Script**:

"Committed and pushed to GitHub. Now watch Flux detect and reconcile the change."

### Watch Reconciliation

```bash
# In terminal
flux get kustomizations --watch
```

**Script**:

"Flux polls our Git repository every 5 minutes, but we can force immediate reconciliation for the demo."

```bash
flux reconcile kustomization apps --with-source
```

**Script**:

"Watch the kustomization update... and now the deployment is rolling out."

```bash
kubectl rollout status deployment/redpanda-connect -n demo
```

**Script**:

"New pod is starting with our updated configuration. Once ready, let's test it."

### Verify New Behavior

**Action**: Upload the same CSV file again via UI

**Script**:

"Uploading the same file... now let's check the Redpanda Console."

**Show**: Message in Redpanda Console with new `priority` field

**Script**:

"There it is! The new `priority` field based on our calculation. We changed configuration in Git, Flux deployed it automatically, zero downtime.

This is GitOps:
- Git is the single source of truth
- Full audit trail (Git history)
- Rollback is just `git revert`
- No cluster credentials in CI/CD
- Declarative, not imperative"

## Part 6: Drift Detection Demo (4 minutes)

**Script**:

"One more powerful feature: drift detection. Watch what happens if someone makes a manual change."

### Create Drift

```bash
kubectl scale deployment/redpanda-connect -n demo --replicas=2
kubectl get deployment redpanda-connect -n demo
```

**Script**:

"I just manually scaled the deployment to 2 replicas. In a traditional setup, this change would stick until someone notices and fixes it - causing configuration drift.

With GitOps, Flux continuously monitors and auto-remediates."

### Watch Auto-Remediation

```bash
# Wait or force reconciliation
flux reconcile kustomization apps --with-source
kubectl get deployment redpanda-connect -n demo --watch
```

**Script**:

"Watch... Flux detected the drift and corrected it back to 1 replica as defined in Git. This happens automatically within 5 minutes.

This prevents:
- Configuration drift
- Snowflake servers
- 'But it works on my cluster' syndrome
- Undocumented changes"

## Part 7: Monitoring (3 minutes)

**Show**: Grafana at localhost:3000 (admin/admin)

**Script**:

"Finally, observability. Grafana is pre-configured with Redpanda dashboards."

**Action**: Navigate to Redpanda dashboards

**Script**:

"Out of the box, we get:
- Broker health and performance
- Topic throughput and latency
- Consumer lag monitoring
- Redpanda Connect processing metrics

With Kafka, you'd need to:
- Install JMX exporters
- Configure Prometheus scraping
- Build custom dashboards
- Debug JVM memory issues

With Redpanda, metrics are built-in and performant."

## Part 8: Summary (2 minutes)

**Script**:

"Let's recap what we've demonstrated:

**Redpanda vs Kafka**:
- 75% fewer servers (3 vs 9-12)
- 10x lower latency
- 3-6x cost savings
- No Zookeeper, no JVM tuning

**Redpanda Connect vs Kafka Connect**:
- 95% less memory (128MB vs 2-4GB)
- Single pod vs cluster
- 300+ connectors built-in
- Declarative YAML config

**GitOps vs Traditional CI/CD**:
- Continuous reconciliation vs one-time deployment
- Automatic drift detection
- Git as single source of truth
- Enhanced security (no cluster creds in CI)

This entire stack runs on a laptop but scales to production. The architecture we deployed with GitOps is production-ready and battle-tested."

**Script**:

"Questions?"

## Appendix: Backup Talking Points

### If Asked: "What about the Kafka ecosystem?"

"Redpanda is 100% Kafka API compatible. All Kafka clients, tools, and libraries work without changes:
- Kafka Streams
- ksqlDB
- Kafka clients in any language
- Schema Registry (built-in)
- Existing connectors

You get the entire ecosystem with better performance."

### If Asked: "What about enterprise support?"

"Redpanda offers enterprise support with SLAs. Many Fortune 500 companies use it in production, including major financial institutions and NYSE. The company is well-funded and growing rapidly."

### If Asked: "How hard is migration from Kafka?"

"Migration is straightforward because of API compatibility:
1. Deploy Redpanda alongside Kafka
2. Use MirrorMaker to replicate topics
3. Gradually move consumers to Redpanda
4. Move producers
5. Decommission Kafka

No code changes required. The biggest effort is operational (updating deployment scripts, monitoring, etc.)."

## Time Breakdown

- Part 1: Introduction (2 min)
- Part 2: Architecture (3 min)
- Part 3: File Upload Demo (5 min)
- Part 4: Comparison (3 min)
- Part 5: GitOps Workflow (7 min)
- Part 6: Drift Detection (4 min)
- Part 7: Monitoring (3 min)
- Part 8: Summary (2 min)

**Total: ~30 minutes** (with buffer for questions and transitions)
