# Runbook — checkout-api availability

**Alert:** `CheckoutAvailabilitySLOBurn` or `CheckoutHighErrorRate`  
**Severity:** page  
**Service:** checkout-api (`platform` namespace)

## 1. Confirm user impact

```bash
./scripts/cluster_health.sh platform-prod
kubectl -n platform get pods,hpa,ing
kubectl -n platform logs deploy/checkout-api --tail=200
```

In Grafana: dashboard **Checkout API — RED + SLO**. Check 5xx ratio and p99.

## 2. Immediate mitigations (pick one)

1. **Bad rollout** — roll back the Deployment:
   ```bash
   kubectl -n platform rollout undo deployment/checkout-api
   kubectl -n platform rollout status deployment/checkout-api
   ```
2. **Partial bad build** — shift ALB weights back to blue:
   ```bash
   ./scripts/blue_green_shift.sh 100 0
   ```
3. **Saturation** — confirm HPA and Cluster Autoscaler; raise `maxReplicas` in the prod overlay if at cap.
4. **AZ / node failure** — cordon bad nodes only after confirming replacements exist.

## 3. Communications

```bash
export JIRA_BASE_URL=https://your-domain.atlassian.net
export JIRA_USER=sre-bot@example.com
export JIRA_API_TOKEN=...
python scripts/jira_incident.py --summary "SEV-2 checkout-api availability" --severity page
```

## 4. Exit criteria

- Error rate < 1% for 15 minutes
- p99 < 500 ms
- No pending pods
- Post-mortem scheduled if SEV-2 or higher (`docs/postmortem-template.md`)
