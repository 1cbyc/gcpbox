# gcpbox

`gcpbox` is a Terraform foundation for one private Google Cloud Run service and its PostgreSQL data boundary. It gives a workload a digest-pinned deployment, dedicated identity, immutable image registry, private database connectivity, and guarded recovery settings without creating a network or deploying an application.

## Intended use

Use this module when a team already owns a VPC with private service access and needs a reviewable baseline for a regional HTTP workload. The caller supplies a container digest and network resource ID. Terraform creates Artifact Registry, a dedicated service account, Cloud Run v2, and a regional Cloud SQL PostgreSQL instance with IAM database authentication.

The application must listen on the configured port, expose the configured startup and liveness paths, and support the Cloud SQL connector's automatic IAM authentication. The startup path must prove the instance is ready to receive traffic. The module passes only database identity and socket metadata. It does not create or expose a password.

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
- Instance count, request concurrency, CPU, memory, timeout, and probe paths are explicit consumer inputs. The `capacity` output makes the effective connection and cost boundary reviewable.
- The consumer example attaches Secret Manager payload access to one existing secret. Application-specific permissions remain outside the module.

## Adoption and compatibility

Pin the module to a reviewed commit. Existing consumers retain the prior one CPU, 512 MiB, 80 request concurrency, 30 second timeout, and `/health/live` probe defaults. Set `startup_probe_path` to a dependency-aware readiness endpoint only after the application implements it. Size `max_instances * request_concurrency` together with the application pool and database connection budget; request concurrency is not the same as database concurrency.

The consumer example plans a two-to-twelve instance service, a 20 request concurrency limit, a dependency-aware startup path, and access to one existing secret. Its mocked plan proves the public interface without contacting Google Cloud. Before applying, replace every example value, inspect provider upgrade notes, and follow the runbook.

## Non-goals

This module does not create projects, APIs, VPCs, service networking, DNS, TLS, load balancers, secrets, database schemas, CI identity, monitoring policies, or budgets. It does not apply infrastructure. Those boundaries carry organization-specific access, cost, and lifecycle decisions.
