# gcpbox

`gcpbox` is a Terraform foundation for one private Google Cloud Run service and its PostgreSQL data boundary. It gives a workload a digest-pinned deployment, dedicated identity, immutable image registry, private database connectivity, and guarded recovery settings without creating a network or deploying an application.

## Intended use

Use this module when a team already owns a VPC with private service access and needs a reviewable baseline for a regional HTTP workload. The caller supplies a container digest and network resource ID. Terraform creates Artifact Registry, a dedicated service account, Cloud Run v2, and a regional Cloud SQL PostgreSQL instance with IAM database authentication.

The application must listen on the configured port, expose `/health/live`, and support the Cloud SQL connector's automatic IAM authentication. The module passes only database identity and socket metadata. It does not create or expose a password.

See [`examples/consumer`](examples/consumer) for the complete interface and [`docs/runbook.md`](docs/runbook.md) before planning a real environment.

## Validation

```text
make ci
tflint --recursive
```

Tests use Terraform's mocked provider. They do not contact Google Cloud and never apply infrastructure.

## Design boundaries

- Cloud Run accepts internal and external Application Load Balancer traffic, but no unauthenticated invoker grant is created.
- Direct VPC egress sends only private ranges into the VPC. The existing network must provide private service access for Cloud SQL.
- Cloud SQL has regional availability, private IP only, point-in-time recovery, retained backups, bounded disk growth, and two independent deletion guards.
- The runtime identity receives only Cloud SQL client and instance-user roles. Add application-specific grants outside this module.
- The image must include a sha256 digest. Artifact Registry tags are immutable, but the supplied image may live in another repository when migration requires it.
- Cloud Run sends all traffic to the latest ready revision. A rollback changes traffic to a known prior revision as described in the runbook.

## Non-goals

This module does not create projects, APIs, VPCs, service networking, DNS, TLS, load balancers, secrets, database schemas, CI identity, monitoring policies, or budgets. It does not apply infrastructure. Those boundaries carry organization-specific access, cost, and lifecycle decisions.
