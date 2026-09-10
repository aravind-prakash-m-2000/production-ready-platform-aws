output "cluster_name" {
  value = module.eks.cluster_name
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "amp_remote_write_url" {
  value = module.observability.amp_remote_write_url
}

output "grafana_endpoint" {
  value = module.observability.grafana_endpoint
}

output "aws_lb_controller_role_arn" {
  value = module.eks.aws_lb_controller_role_arn
}

output "cluster_autoscaler_role_arn" {
  value = module.eks.cluster_autoscaler_role_arn
}

output "amp_ingest_role_arn" {
  value = module.observability.amp_ingest_role_arn
}

output "fluentbit_role_arn" {
  value = module.observability.fluentbit_role_arn
}
