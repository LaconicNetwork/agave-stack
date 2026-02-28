#!/usr/bin/env bash
set -euo pipefail

# -----------------------------------------------------------------------
# Start doublezerod with Solana validator identity
#
# Required environment:
#   VALIDATOR_IDENTITY_PATH - path to validator identity keypair
#
# Optional environment:
#   DOUBLEZERO_RPC_ENDPOINT - Solana RPC endpoint (default: http://127.0.0.1:8899)
#   DOUBLEZERO_EXTRA_ARGS   - additional doublezerod arguments
# -----------------------------------------------------------------------

IDENTITY="${VALIDATOR_IDENTITY_PATH:-/data/config/validator-identity.json}"
RPC_ENDPOINT="${DOUBLEZERO_RPC_ENDPOINT:-http://127.0.0.1:8899}"

if [ ! -f "$IDENTITY" ]; then
  echo "ERROR: Validator identity not found at $IDENTITY"
  echo "Mount the validator identity keypair"
  exit 1
fi

# Generate DZ identity if not already present
DZ_CONFIG_DIR="${HOME}/.config/doublezero"
mkdir -p "$DZ_CONFIG_DIR"
if [ ! -f "$DZ_CONFIG_DIR/id.json" ]; then
  echo "Generating DoubleZero identity..."
  doublezero keygen
fi

echo "Starting doublezerod..."
echo "Validator identity: $IDENTITY"
echo "RPC endpoint: $RPC_ENDPOINT"
echo "DZ address: $(doublezero address)"

ARGS=()
[ -n "${DOUBLEZERO_EXTRA_ARGS:-}" ] && read -ra ARGS <<< "$DOUBLEZERO_EXTRA_ARGS"

exec doublezerod \
  -solana-identity "$IDENTITY" \
  -solana-rpc-endpoint "$RPC_ENDPOINT" \
  "${ARGS[@]}"
