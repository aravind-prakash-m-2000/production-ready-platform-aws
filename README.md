# Production-ready AWS platform

An enterprise-style **Kubernetes platform on AWS**: Terraform modules, GitOps (Kustomize), CI security gates, and a full observability path (Prometheus rules, Grafana dashboards, Fluent Bit → CloudWatch, Amazon Managed Prometheus / Grafana).

Built as a **Senior DevOps / SRE / Platform Engineering** portfolio. It favors production controls (IRSA, KMS, PDBs, SLO alerts, DR scripts) over toy snippets.

> Substitute `CHANGE_ME` placeholders (state bucket, IAM account IDs, CIDRs, AMP workspace URL) before `terraform apply`. Applying this stack **creates billable AWS resources**.

## Architecture at a glance

```
Internet → ALB (AWS Load Balancer Controller)
         → checkout-api on EKS (private subnets, HPA, PDB, NetworkPolicy)
         → Prometheus remote_write → Amazon Managed Prometheus → Amazon Managed Grafana
         → Fluent Bit → CloudWatch Logs
```

Read **[ARCHITECTURE.md](ARCHITECTURE.md)** for SLA/SLO tables, DR RPO/RTO, and design rationale.

## Repository map

```
.github/workflows/     IaC lint, kubeconform, Trivy, OIDC deploy
terraform/modules/     vpc, eks (incl. IRSA), observability (AMP/AMG)
terraform/environments dev (cost-optimized NAT) and prod (HA NAT, larger nodes)
terraform/bootstrap    S3 + DynamoDB for remote state
kubernetes/base        Sample app + system controllers
kubernetes/overlays    Dev vs prod (blue/green service in prod)
observability/         Rules, Alertmanager, dashboards, Fluent Bit
apps/checkout-api      Instrumented Flask API used by the manifests
scripts/               Health, DR snapshot, blue/green, Jira incidents
docs/                  Runbooks, post-mortem template, diagrams
```

## What “production-ready” means here

- **Multi-AZ VPC** with flow logs and ECR/S3 endpoints  
- **EKS 1.31** with control-plane logs, secrets encryption, managed node groups tagged for Cluster Autoscaler  
- **IRSA** for ALB controller, autoscaler, AMP ingest, Fluent Bit  
- **GitOps overlays** with rolling updates (`maxUnavailable: 0`) and weighted ALB blue/green  
- **SLO-as-code** PrometheusRules + Alertmanager → Slack / Jira webhook  
- **PR gates**: `terraform fmt/validate`, tflint, Checkov, kubeconform, unit tests, Trivy, Gitleaks  

## Prerequisites

- Terraform `>= 1.6`
- AWS CLI v2, kubectl `1.31`, kustomize `5.x`
- An AWS account with permissions to create VPC, EKS, IAM, AMP, AMG
- GitHub OIDC provider in IAM (for the Deploy workflow)

## Bring-up

1. **Remote state**

   ```bash
   cd terraform/bootstrap
   terraform init
   terraform apply -var="state_bucket_name=<globally-unique-bucket>"
   ```

   Put the bucket name in the `backend "s3"` blocks under `terraform/environments/*/main.tf`.

2. **Dev cluster**

   ```bash
   cd terraform/environments/dev
   cp terraform.tfvars.example terraform.tfvars
   terraform init
   terraform apply
   aws eks update-kubeconfig --name platform-dev --region us-east-1
   ```

3. **Patch IRSA ARNs** in:

   - `kubernetes/base/system/*.yaml`
   - `observability/logging/*.yaml`

   Use `terraform output` (`aws_lb_controller_role_arn`, `amp_ingest_role_arn`, `fluentbit_role_arn`, …).

4. **GitOps apply**

   ```bash
   kubectl apply -f observability/logging/namespace.yaml
   kustomize build kubernetes/base/system | kubectl apply -f -
   kustomize build kubernetes/overlays/dev | kubectl apply -f -
   kubectl apply -f observability/logging/fluent-bit.yaml
   kubectl apply -f observability/prometheus/rules
   ```

5. **Metrics path**  
   Install kube-prometheus-stack with `observability/prometheus/values-amp.yaml` after replacing the AMP remote-write URL from `terraform output amp_remote_write_url`. Import Grafana JSON from `observability/grafana/dashboards/`.

6. **Prod**  
   Same flow with `environments/prod`. Set `public_access_cidrs` to VPN/bastion only. Use GitHub Environment protection on `prod`.

## Sample application

`apps/checkout-api` exposes `/healthz`, `/readyz`, `/api/v1/checkout`, and `/metrics` (RED metrics). Build and push to your registry, then set the image in the Kustomize overlay.

```bash
python -m unittest discover -s apps/checkout-api -p 'test_*.py'
docker build -t <acct>.dkr.ecr.us-east-1.amazonaws.com/checkout-api:1.0.0 apps/checkout-api
```

## Operations scripts

| Script | Purpose |
| --- | --- |
| `scripts/cluster_health.sh` | Node/pod/event snapshot |
| `scripts/blue_green_shift.sh 90 10` | ALB weight cutover |
| `scripts/dr_backup.sh prod` | State + live-object tarball to S3 |
| `scripts/jira_incident.py` | Alertmanager webhook or CLI Jira incident |

## CI/CD

| Workflow | Trigger | What it proves |
| --- | --- | --- |
| `terraform.yml` | TF changes | fmt, validate (dev+prod), tflint, Checkov SARIF |
| `kubernetes.yml` | Manifests / app | kustomize build, kubeconform, API tests, hadolint |
| `security.yml` | PR + weekly | Trivy filesystem, Gitleaks |
| `deploy.yml` | Manual | OIDC to AWS, optional `terraform apply`, `kubectl apply` overlay |

Configure repository secrets: `AWS_DEPLOY_ROLE_ARN`. For Gitleaks org billing, see [gitleaks-action](https://github.com/gitleaks/gitleaks-action).

## Interview talking points

- Why single NAT in dev vs per-AZ NAT in prod  
- Why AMP instead of only in-cluster TSDB  
- Why IRSA instead of instance-role credentials for controllers  
- How error budgets drive `CheckoutAvailabilitySLOBurn`  
- How blue/green weights are a traffic action, not a second cluster  

## License

MIT — see [LICENSE](LICENSE).
