# kubernetes/

- `base/` — checkout-api Deployment, Service, Ingress (ALB), HPA, PDB, NetworkPolicy, ServiceMonitor.
- `base/system/` — AWS Load Balancer Controller and Cluster Autoscaler (patch IRSA ARNs after Terraform).
- `overlays/dev` — smaller HPA, debug logs, `checkout.dev.example.com`.
- `overlays/prod` — 4+ replicas, green Service for weighted blue/green.

```bash
kustomize build kubernetes/overlays/dev
kustomize build kubernetes/overlays/prod
```
