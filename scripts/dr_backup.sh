#!/usr/bin/env bash
# Disaster recovery: snapshot Terraform state + export live cluster objects.
# This does not restore etcd. EKS control plane backups are AWS-managed;
# this script captures the GitOps-adjacent live state for rebuilds.
set -euo pipefail

ENV="${1:-prod}"
REGION="${AWS_REGION:-us-east-1}"
STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
OUT="${DR_BUCKET:-s3://CHANGE_ME-platform-dr}/${ENV}/${STAMP}"
WORKDIR="$(mktemp -d)"
trap 'rm -rf "${WORKDIR}"' EXIT

echo "Collecting DR artifacts into ${OUT}"

pushd "terraform/environments/${ENV}" >/dev/null
terraform init -input=false >/dev/null
terraform state pull > "${WORKDIR}/terraform.tfstate"
popd >/dev/null

kubectl get ns -o yaml > "${WORKDIR}/namespaces.yaml"
kubectl get deploy,sts,ds,svc,ing,cm,secret,hpa,pdb,networkpolicy -A -o yaml \
  > "${WORKDIR}/workloads.yaml" || true

kustomize build "kubernetes/overlays/${ENV}" > "${WORKDIR}/desired-gitops.yaml"

tar -C "${WORKDIR}" -czf "${WORKDIR}/dr-bundle.tgz" .
aws s3 cp "${WORKDIR}/dr-bundle.tgz" "${OUT}/dr-bundle.tgz" --region "${REGION}"
echo "Wrote ${OUT}/dr-bundle.tgz"
