#!/usr/bin/env bash
# Cluster health snapshot used by on-call and CI smoke jobs.
set -euo pipefail

CLUSTER="${1:-}"
REGION="${AWS_REGION:-us-east-1}"

if [[ -z "${CLUSTER}" ]]; then
  echo "usage: $0 <eks-cluster-name>" >&2
  exit 1
fi

echo "== aws identity =="
aws sts get-caller-identity

echo "== kubeconfig =="
aws eks update-kubeconfig --name "${CLUSTER}" --region "${REGION}" >/dev/null

echo "== nodes =="
kubectl get nodes -o wide

echo "== not-ready pods =="
kubectl get pods -A --field-selector=status.phase!=Running,status.phase!=Succeeded || true

echo "== PDBs =="
kubectl get pdb -A

echo "== recent events =="
kubectl get events -A --sort-by=.lastTimestamp | tail -n 30

echo "== checkout-api =="
kubectl get deploy,svc,ing,hpa -n platform || true
