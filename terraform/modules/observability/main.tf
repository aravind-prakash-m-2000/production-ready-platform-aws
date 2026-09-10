locals {
  cluster_name = "${var.name}-${var.environment}"
  oidc_host    = replace(var.oidc_provider_url, "https://", "")
  common_tags = merge(var.tags, {
    Environment = var.environment
    ManagedBy   = "terraform"
    Module      = "observability"
  })
}

resource "aws_prometheus_workspace" "this" {
  alias = "${local.cluster_name}-amp"

  logging_configuration {
    log_group_arn = "${aws_cloudwatch_log_group.amp.arn}:*"
  }

  tags = local.common_tags

  depends_on = [aws_cloudwatch_log_resource_policy.amp]
}

resource "aws_cloudwatch_log_group" "amp" {
  name              = "/aws/prometheus/${local.cluster_name}"
  retention_in_days = var.log_retention_days
  tags              = local.common_tags
}

resource "aws_cloudwatch_log_resource_policy" "amp" {
  policy_name = "${local.cluster_name}-amp-logs"
  policy_document = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "AMP"
      Effect = "Allow"
      Principal = {
        Service = "aps.amazonaws.com"
      }
      Action = [
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogStreams",
        "logs:CreateLogGroup"
      ]
      Resource = "${aws_cloudwatch_log_group.amp.arn}:*"
    }]
  })
}

resource "aws_cloudwatch_log_group" "application" {
  name              = "/aws/eks/${local.cluster_name}/application"
  retention_in_days = var.log_retention_days
  tags              = local.common_tags
}

resource "aws_cloudwatch_log_group" "fluentbit" {
  name              = "/aws/eks/${local.cluster_name}/fluentbit"
  retention_in_days = var.log_retention_days
  tags              = local.common_tags
}

resource "aws_grafana_workspace" "this" {
  account_access_type      = "CURRENT_ACCOUNT"
  authentication_providers = var.grafana_authentication_providers
  permission_type          = "SERVICE_MANAGED"
  role_arn                 = aws_iam_role.grafana.arn
  name                     = "${local.cluster_name}-amg"
  data_sources             = ["PROMETHEUS", "CLOUDWATCH"]

  tags = local.common_tags
}

resource "aws_iam_role" "grafana" {
  name = "${local.cluster_name}-amg"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "grafana.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy" "grafana" {
  name = "${local.cluster_name}-amg"
  role = aws_iam_role.grafana.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "aps:ListWorkspaces",
          "aps:DescribeWorkspace",
          "aps:QueryMetrics",
          "aps:GetLabels",
          "aps:GetSeries",
          "aps:GetMetricMetadata"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:DescribeAlarmsForMetric",
          "cloudwatch:DescribeAlarmHistory",
          "cloudwatch:DescribeAlarms",
          "cloudwatch:ListMetrics",
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:GetMetricData",
          "logs:DescribeLogGroups",
          "logs:GetLogGroupFields",
          "logs:StartQuery",
          "logs:StopQuery",
          "logs:GetQueryResults",
          "logs:GetLogEvents",
          "ec2:DescribeTags",
          "ec2:DescribeInstances",
          "ec2:DescribeRegions",
          "tag:GetResources"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role" "amp_ingest" {
  name = "${local.cluster_name}-amp-ingest"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = var.oidc_provider_arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${local.oidc_host}:sub" = "system:serviceaccount:observability:amp-ingest"
          "${local.oidc_host}:aud" = "sts.amazonaws.com"
        }
      }
    }]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy" "amp_ingest" {
  name = "${local.cluster_name}-amp-ingest"
  role = aws_iam_role.amp_ingest.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "aps:RemoteWrite",
        "aps:GetSeries",
        "aps:GetLabels",
        "aps:GetMetricMetadata"
      ]
      Resource = aws_prometheus_workspace.this.arn
    }]
  })
}

resource "aws_iam_role" "fluentbit" {
  name = "${local.cluster_name}-fluentbit"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = var.oidc_provider_arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${local.oidc_host}:sub" = "system:serviceaccount:observability:fluent-bit"
          "${local.oidc_host}:aud" = "sts.amazonaws.com"
        }
      }
    }]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy" "fluentbit" {
  name = "${local.cluster_name}-fluentbit"
  role = aws_iam_role.fluentbit.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "logs:CreateLogStream",
        "logs:CreateLogGroup",
        "logs:DescribeLogStreams",
        "logs:PutLogEvents",
        "logs:PutRetentionPolicy"
      ]
      Resource = [
        aws_cloudwatch_log_group.application.arn,
        "${aws_cloudwatch_log_group.application.arn}:*",
        aws_cloudwatch_log_group.fluentbit.arn,
        "${aws_cloudwatch_log_group.fluentbit.arn}:*"
      ]
    }]
  })
}

resource "aws_cloudwatch_metric_alarm" "amp_ingest" {
  alarm_name          = "${local.cluster_name}-amp-ingest-failures"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "RemoteWriteRequests"
  namespace           = "AWS/Prometheus"
  period              = 300
  statistic           = "Sum"
  threshold           = 0
  treat_missing_data  = "notBreaching"
  alarm_description   = "Placeholder alarm — attach SNS in the environment layer for paging."

  dimensions = {
    WorkspaceId = aws_prometheus_workspace.this.id
  }

  tags = local.common_tags
}
