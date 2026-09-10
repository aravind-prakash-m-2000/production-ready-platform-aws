# Grafana dashboards

Import these JSON files into Amazon Managed Grafana (AMG) or a self-hosted Grafana:

1. Add Amazon Managed Prometheus as a Prometheus data source (SigV4).
2. Import `checkout-red-slo.json` and `kubernetes-use.json`.
3. Map the `DS_PROMETHEUS` template variable to that data source.

Dashboards follow Google SRE RED (Rate, Errors, Duration) for the sample API and Brendan Gregg's USE method (Utilization, Saturation, Errors) for cluster nodes.
