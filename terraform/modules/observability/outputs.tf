output "amp_workspace_id" {
  value = aws_prometheus_workspace.this.id
}

output "amp_workspace_arn" {
  value = aws_prometheus_workspace.this.arn
}

output "amp_remote_write_url" {
  value = "${aws_prometheus_workspace.this.prometheus_endpoint}api/v1/remote_write"
}

output "amp_query_url" {
  value = "${aws_prometheus_workspace.this.prometheus_endpoint}api/v1/query"
}

output "grafana_workspace_id" {
  value = aws_grafana_workspace.this.id
}

output "grafana_endpoint" {
  value = aws_grafana_workspace.this.endpoint
}

output "amp_ingest_role_arn" {
  value = aws_iam_role.amp_ingest.arn
}

output "fluentbit_role_arn" {
  value = aws_iam_role.fluentbit.arn
}

output "application_log_group" {
  value = aws_cloudwatch_log_group.application.name
}
