#!/bin/bash
# Write validator_name measurement for Grafana node selector.
#
# The dashboards use template variables that look up host_id via
# validator_name. This script queries the local RPC for the node
# identity and writes the mapping.

set -euo pipefail

RPC_URL="${NODE_RPC_URL:-http://localhost:8899}"
NODE_NAME="${NODE_NAME:-$(hostname)}"

identity=$(curl -sk --max-time 5 -X POST \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":1,"method":"getIdentity"}' \
  "$RPC_URL" 2>/dev/null \
  | grep -o '"identity":"[^"]*"' \
  | cut -d'"' -f4 || echo "")

if [ -z "$identity" ]; then
  exit 0
fi

echo "validator_name,host_id=${identity},name=${NODE_NAME} value=1i"
