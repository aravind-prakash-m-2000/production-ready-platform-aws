# EKS module

Provision an EKS cluster with:

- Private+public API access, KMS secret encryption, control-plane logs
- Managed node group (AL2023) tagged for Cluster Autoscaler
- OIDC provider and IRSA roles: EBS CSI, AWS Load Balancer Controller, Cluster Autoscaler
