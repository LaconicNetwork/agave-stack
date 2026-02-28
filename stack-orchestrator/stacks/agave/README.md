# agave stack

Unified Agave/Jito Solana stack supporting three modes:

| Mode | Compose file | Use case |
|------|-------------|----------|
| `test` | `docker-compose-agave-test.yml` | Local dev with instant finality |
| `rpc` | `docker-compose-agave-rpc.yml` | Non-voting mainnet/testnet RPC node |
| `validator` | `docker-compose-agave.yml` | Voting validator |

## Build

```bash
# Vanilla Agave v3.1.9
laconic-so --stack agave build-containers

# Jito v3.1.8
AGAVE_REPO=https://github.com/jito-foundation/jito-solana.git \
AGAVE_VERSION=v3.1.8-jito \
laconic-so --stack agave build-containers
```

Build compiles from source (~30-60 min on first build).

## Deploy

```bash
# Test validator (dev)
laconic-so --stack agave deploy init --output spec.yml
laconic-so --stack agave deploy create --spec-file spec.yml --deployment-dir my-test
laconic-so deployment --dir my-test start

# Mainnet RPC (e.g. biscayne)
# Edit spec.yml to set AGAVE_MODE=rpc, VALIDATOR_ENTRYPOINT, KNOWN_VALIDATOR, etc.
laconic-so --stack agave deploy init --output spec.yml
laconic-so --stack agave deploy create --spec-file spec.yml --deployment-dir my-rpc
laconic-so deployment --dir my-rpc start
```

## Configuration

Mode is selected via `AGAVE_MODE` environment variable (`test`, `rpc`, or `validator`).

### RPC mode required env
- `VALIDATOR_ENTRYPOINT` - cluster entrypoint (e.g. `entrypoint.mainnet-beta.solana.com:8001`)
- `KNOWN_VALIDATOR` - known validator pubkey

### Validator mode required env
- `VALIDATOR_ENTRYPOINT` - cluster entrypoint
- `KNOWN_VALIDATOR` - known validator pubkey
- Identity and vote account keypairs mounted at `/data/config/`

### Jito (optional, any mode except test)
Set `JITO_ENABLE=true` and provide:
- `JITO_BLOCK_ENGINE_URL`
- `JITO_SHRED_RECEIVER_ADDR`
- `JITO_TIP_PAYMENT_PROGRAM`
- `JITO_DISTRIBUTION_PROGRAM`
- `JITO_MERKLE_ROOT_AUTHORITY`
- `JITO_COMMISSION_BPS`

Image must be built from `jito-foundation/jito-solana` repo for Jito flags to work.

## Runtime requirements

The container needs `--security-opt seccomp=unconfined` for io_uring support (already set in compose files).
