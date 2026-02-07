#!/bin/bash

IMAGE=$1

docker run --rm -it --runtime=nvidia \
  --user "$(id -u)":"$(id -g)" \
  -e HOME=/tmp \
  -e NVIDIA_VISIBLE_DEVICES=all \
  -e NVIDIA_DRIVER_CAPABILITIES=compute,utility \
  --shm-size=16g \
  -e PIP_CACHE_DIR=/pipcache \
  -v "$HOME/.cache/pip:/pipcache" \
  -v "$PWD:/work" \
  -w /work \
  $IMAGE bash
