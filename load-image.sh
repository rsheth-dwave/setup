#!/bin/bash

set -e

IMAGE="$1"

OUT="/home/user/image-checkpoints/$1.tar.gz"
zstd -T0 -d -q -c "$OUT" | docker load
