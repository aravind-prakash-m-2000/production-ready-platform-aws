#!/usr/bin/env bash
# Weighted ALB blue/green cutover helper.
# Requires AWS Load Balancer Controller annotations on the Ingress.
set -euo pipefail

NAMESPACE="${NAMESPACE:-platform}"
INGRESS="${INGRESS:-checkout-api}"
BLUE_WEIGHT="${1:-100}"
GREEN_WEIGHT="${2:-0}"

if (( BLUE_WEIGHT + GREEN_WEIGHT != 100 )); then
  echo "weights must sum to 100" >&2
  exit 1
fi

ACTION=$(cat <<EOF
{"type":"forward","forwardConfig":{"targetGroups":[{"serviceName":"checkout-api","servicePort":"80","weight":${BLUE_WEIGHT}},{"serviceName":"checkout-api-green","servicePort":"80","weight":${GREEN_WEIGHT}}]}}
EOF
)

kubectl annotate ingress "${INGRESS}" -n "${NAMESPACE}" \
  --overwrite \
  "alb.ingress.kubernetes.io/actions.blue-green=${ACTION}"

echo "Set traffic split blue=${BLUE_WEIGHT} green=${GREEN_WEIGHT}"
kubectl get ingress "${INGRESS}" -n "${NAMESPACE}" -o yaml | sed -n '/actions.blue-green/,+2p'
