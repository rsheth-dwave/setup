#!/bin/bash

set -e

IMAGE="$1"

mkdir -p /home/user/image-checkpoints
OUT="/home/user/image-checkpoints/$1.tar.gz"
docker save "$IMAGE" | zstd -T0 --fast=10 -q -o "$OUT"
