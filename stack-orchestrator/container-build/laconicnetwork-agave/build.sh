#!/usr/bin/env bash

# Build laconicnetwork/agave
# Set AGAVE_REPO and AGAVE_VERSION env vars to build Jito or a different version
source ${CERC_CONTAINER_BASE_DIR}/build-base.sh

AGAVE_REPO="${AGAVE_REPO:-https://github.com/anza-xyz/agave.git}"
AGAVE_VERSION="${AGAVE_VERSION:-v3.1.9}"

docker build -t laconicnetwork/agave:local \
  --build-arg AGAVE_REPO="$AGAVE_REPO" \
  --build-arg AGAVE_VERSION="$AGAVE_VERSION" \
  ${build_command_args} \
  -f ${CERC_CONTAINER_BASE_DIR}/laconicnetwork-agave/Dockerfile \
  ${CERC_CONTAINER_BASE_DIR}/laconicnetwork-agave
