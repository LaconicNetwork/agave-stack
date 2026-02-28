#!/usr/bin/env bash
set -euo pipefail

# -----------------------------------------------------------------------
# Start agave-validator as a voting validator
#
# Required environment:
#   VALIDATOR_ENTRYPOINT   - cluster entrypoint (host:port)
#   KNOWN_VALIDATOR        - known validator pubkey
#
# Optional environment:
#   VOTE_ACCOUNT_KEYPAIR   - path to vote account keypair
#                            (default: /data/config/vote-account-keypair.json)
#   RPC_PORT               - RPC port (default: 8899)
#   RPC_BIND_ADDRESS       - RPC bind address (default: 127.0.0.1)
#   GOSSIP_PORT            - gossip port (default: 8001)
#   DYNAMIC_PORT_RANGE     - dynamic port range (default: 8000-10000)
#   EXPECTED_GENESIS_HASH  - genesis hash for cluster verification
#   EXPECTED_SHRED_VERSION - shred version for cluster verification
#   LIMIT_LEDGER_SIZE      - max ledger slots (default: 50000000)
#   SNAPSHOT_INTERVAL_SLOTS          - full snapshot interval (default: 1000)
#   MAXIMUM_SNAPSHOTS_TO_RETAIN      - max full snapshots (default: 5)
#   SOLANA_METRICS_CONFIG  - metrics reporting config
#
#   Jito (set JITO_ENABLE=true to activate):
#   JITO_BLOCK_ENGINE_URL, JITO_RELAYER_URL, JITO_SHRED_RECEIVER_ADDR,
#   JITO_TIP_PAYMENT_PROGRAM, JITO_DISTRIBUTION_PROGRAM,
#   JITO_MERKLE_ROOT_AUTHORITY, JITO_COMMISSION_BPS
#
#   Additional entrypoints/known-validators (space-separated):
#   EXTRA_ENTRYPOINTS, EXTRA_KNOWN_VALIDATORS
# -----------------------------------------------------------------------

CONFIG_DIR="/data/config"
LEDGER_DIR="/data/ledger"
ACCOUNTS_DIR="/data/accounts"
SNAPSHOTS_DIR="/data/snapshots"
IDENTITY_FILE="${CONFIG_DIR}/validator-identity.json"
VOTE_ACCOUNT_KEYPAIR="${VOTE_ACCOUNT_KEYPAIR:-${CONFIG_DIR}/vote-account-keypair.json}"

: "${VALIDATOR_ENTRYPOINT:?VALIDATOR_ENTRYPOINT is required}"
: "${KNOWN_VALIDATOR:?KNOWN_VALIDATOR is required}"

RPC_PORT="${RPC_PORT:-8899}"
RPC_BIND_ADDRESS="${RPC_BIND_ADDRESS:-127.0.0.1}"
GOSSIP_PORT="${GOSSIP_PORT:-8001}"
DYNAMIC_PORT_RANGE="${DYNAMIC_PORT_RANGE:-8000-10000}"
LIMIT_LEDGER_SIZE="${LIMIT_LEDGER_SIZE:-50000000}"
SNAPSHOT_INTERVAL_SLOTS="${SNAPSHOT_INTERVAL_SLOTS:-1000}"
MAXIMUM_SNAPSHOTS_TO_RETAIN="${MAXIMUM_SNAPSHOTS_TO_RETAIN:-5}"

echo "Starting Agave voting validator..."
echo "Entrypoint: ${VALIDATOR_ENTRYPOINT}"
echo "Known validator: ${KNOWN_VALIDATOR}"

# Create directories and fix ownership
for dir in "$CONFIG_DIR" "$LEDGER_DIR" "$ACCOUNTS_DIR" "$SNAPSHOTS_DIR"; do
  mkdir -p "$dir"
  sudo chown -R "$(id -u):$(id -g)" "$dir" 2>/dev/null || true
done

# Identity keypair must exist (should be mounted)
if [ ! -f "$IDENTITY_FILE" ]; then
  echo "ERROR: Validator identity keypair not found at $IDENTITY_FILE"
  echo "Mount your validator keypair to /data/config/validator-identity.json"
  exit 1
fi
echo "Validator identity: $(solana-keygen pubkey "$IDENTITY_FILE")"

# Vote account keypair must exist for voting
if [ ! -f "$VOTE_ACCOUNT_KEYPAIR" ]; then
  echo "ERROR: Vote account keypair not found at $VOTE_ACCOUNT_KEYPAIR"
  echo "Mount your vote account keypair or set VOTE_ACCOUNT_KEYPAIR"
  exit 1
fi
echo "Vote account: $(solana-keygen pubkey "$VOTE_ACCOUNT_KEYPAIR")"

# Build argument list
ARGS=(
  --identity "$IDENTITY_FILE"
  --vote-account "$VOTE_ACCOUNT_KEYPAIR"
  --entrypoint "$VALIDATOR_ENTRYPOINT"
  --known-validator "$KNOWN_VALIDATOR"
  --ledger "$LEDGER_DIR"
  --accounts "$ACCOUNTS_DIR"
  --snapshots "$SNAPSHOTS_DIR"
  --log -
  --rpc-port "$RPC_PORT"
  --rpc-bind-address "$RPC_BIND_ADDRESS"
  --gossip-port "$GOSSIP_PORT"
  --dynamic-port-range "$DYNAMIC_PORT_RANGE"
  --no-os-network-limits-test
  --wal-recovery-mode skip_any_corrupted_record
  --limit-ledger-size "$LIMIT_LEDGER_SIZE"
  --full-snapshot-interval-slots "$SNAPSHOT_INTERVAL_SLOTS"
  --maximum-full-snapshots-to-retain "$MAXIMUM_SNAPSHOTS_TO_RETAIN"
  --maximum-incremental-snapshots-to-retain 2
)

# Additional entrypoints
for ep in ${EXTRA_ENTRYPOINTS:-}; do
  ARGS+=(--entrypoint "$ep")
done

# Additional known validators
for kv in ${EXTRA_KNOWN_VALIDATORS:-}; do
  ARGS+=(--known-validator "$kv")
done

# Cluster verification
[ -n "${EXPECTED_GENESIS_HASH:-}" ] && ARGS+=(--expected-genesis-hash "$EXPECTED_GENESIS_HASH")
[ -n "${EXPECTED_SHRED_VERSION:-}" ] && ARGS+=(--expected-shred-version "$EXPECTED_SHRED_VERSION")

# Metrics
[ -n "${SOLANA_METRICS_CONFIG:-}" ] && export SOLANA_METRICS_CONFIG

# Jito flags
if [ "${JITO_ENABLE:-false}" = "true" ]; then
  echo "Jito MEV enabled"
  [ -n "${JITO_TIP_PAYMENT_PROGRAM:-}" ] && ARGS+=(--tip-payment-program-pubkey "$JITO_TIP_PAYMENT_PROGRAM")
  [ -n "${JITO_DISTRIBUTION_PROGRAM:-}" ] && ARGS+=(--tip-distribution-program-pubkey "$JITO_DISTRIBUTION_PROGRAM")
  [ -n "${JITO_MERKLE_ROOT_AUTHORITY:-}" ] && ARGS+=(--merkle-root-upload-authority "$JITO_MERKLE_ROOT_AUTHORITY")
  [ -n "${JITO_COMMISSION_BPS:-}" ] && ARGS+=(--commission-bps "$JITO_COMMISSION_BPS")
  [ -n "${JITO_BLOCK_ENGINE_URL:-}" ] && ARGS+=(--block-engine-url "$JITO_BLOCK_ENGINE_URL")
  [ -n "${JITO_RELAYER_URL:-}" ] && ARGS+=(--relayer-url "$JITO_RELAYER_URL")
  [ -n "${JITO_SHRED_RECEIVER_ADDR:-}" ] && ARGS+=(--shred-receiver-address "$JITO_SHRED_RECEIVER_ADDR")
fi

echo "Starting agave-validator with ${#ARGS[@]} arguments"
exec agave-validator "${ARGS[@]}"
