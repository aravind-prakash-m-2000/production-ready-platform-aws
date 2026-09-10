# Runbook — cluster nodes not ready

**Alert:** `NodeNotReady` or `ClusterAutoscalerUnneeded`  
**Severity:** page if multiple nodes or unschedulable production pods

## Checks

```bash
kubectl get nodes -o wide
kubectl describe node <node>
kubectl get events -A --field-selector type=Warning | tail
```

AWS:

```bash
aws eks describe-cluster --name platform-prod --query cluster.status
aws autoscaling describe-auto-scaling-groups --query "AutoScalingGroups[?contains(Tags[?Key=='eks:cluster-name'].Value, 'platform-prod')]"
```

## Common causes

| Symptom | Action |
| --- | --- |
| DiskPressure | Check Fluent Bit / image GC; scale nodes |
| Auth failure to ECR | Confirm S3/ECR VPC endpoints and node IAM |
| CNI not ready | Check `aws-node` DaemonSet; security groups |
| At max node group size | Raise `node_max_size` via Terraform |

Do not delete the node group to “fix” a single bad instance; terminate the instance and let the ASG replace it.
