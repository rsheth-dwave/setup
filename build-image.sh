#!/bin/bash

set -euo pipefail

IMAGE_TAG=$1
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

docker build \
    --build-arg UID=$(id -u) \
    --build-arg GID=$(id -g) \
    -t "$IMAGE_TAG" \
    --build-context setup=$SCRIPT_DIR \
    -f $SCRIPT_DIR/Dockerfile.generic .
