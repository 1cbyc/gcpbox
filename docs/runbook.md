# Operations runbook

## Adoption

1. Confirm billing, required APIs, quotas, regional availability, and private service access in the target project.
2. Estimate Cloud Run, Cloud SQL regional HA, SSD, backup, logging, network, and Artifact Registry costs with current Google Cloud pricing.
3. Build the application, scan it, push it, and record its registry digest. Supply the digest form, never a mutable tag.
4. Run `terraform init`, `terraform validate`, and `terraform plan -out=plan.tfplan`. Review IAM, deletion, replacement, networking, database version, and monthly cost changes before apply.
5. Apply through the environment's approved identity. This repository does not define deployment credentials.
6. Grant `roles/run.invoker` only to the intended load balancer or callers. Verify unauthorized requests fail and authorized requests reach readiness-dependent application endpoints.

## Deployment verification

- Confirm the ready Cloud Run revision uses the expected image digest and dedicated service account.
- Confirm ingress is internal plus load balancer and no `allUsers` invoker binding exists.
- Confirm the database has no public IPv4 address, backups and point-in-time recovery are enabled, and a fresh backup exists.
- Exercise an application request and a database operation. Review Cloud Run error rate, latency, instance count, and Cloud SQL connections.

## Rollback

Cloud Run retains revisions. Move traffic to the last known-good revision using an explicitly reviewed Terraform traffic change or the approved deployment procedure. Verify the image digest, health, errors, and database compatibility. Do not roll application code back across an irreversible schema migration.

## Database restore

Restore into a new Cloud SQL instance first. Validate recovery time, data integrity, IAM access, and application compatibility before changing production connectivity. Point-in-time recovery is not a substitute for rehearsed restores. Record the recovery point and retain the old instance until verification is complete.

## Safe teardown

Teardown is intentionally multi-step. Preserve required images and database backups. Remove the `prevent_destroy` lifecycle rule in a reviewed change, set `deletion_protection = false`, apply that change, and only then plan destruction. Inspect the plan for every retained or deleted resource. Repository deletion and project teardown remain outside this module.

## Compatibility

Pin consumers to a reviewed commit or tag. Review provider and PostgreSQL major upgrades separately. A database major-version change may require a migration strategy rather than in-place replacement. For module rollback, restore the prior source revision and plan before applying; never assume state schema changes are reversible.
