#!/usr/bin/env bash
set -euo pipefail

MODE="${AGAVE_MODE:-test}"

case "$MODE" in
  test)      exec start-test.sh "$@" ;;
  rpc)       exec start-rpc.sh "$@" ;;
  validator) exec start-validator.sh "$@" ;;
  *)
    echo "Unknown AGAVE_MODE: $MODE"
    echo "Valid modes: test, rpc, validator"
    exit 1
    ;;
esac
