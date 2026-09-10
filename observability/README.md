# Observability

| Path | Contents |
| --- | --- |
| `prometheus/rules` | SLO burn + Kubernetes USE alerts |
| `prometheus/alertmanager` | Route `page` to Slack, `ticket` to Jira webhook |
| `prometheus/values-amp.yaml` | Helm values: remote_write to AMP with SigV4 |
| `grafana/dashboards` | RED/SLO and cluster USE JSON |
| `logging` | Fluent Bit DaemonSet → CloudWatch |

Replace `111111111111` account IDs and AMP URLs after Terraform apply.
