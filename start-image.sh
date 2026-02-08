#!/bin/bash

IMAGE=$1
JTOKEN=dev

docker run --rm -it --runtime=nvidia \
  --user "$(id -u)":"$(id -g)" \
  -e NVIDIA_VISIBLE_DEVICES=all \
  -e NVIDIA_DRIVER_CAPABILITIES=compute,utility \
  --shm-size=16g \
  -p 127.0.0.1:8888:8888 \
  -e PIP_CACHE_DIR=/pipcache \
  -e JUPYTER_TOKEN=$JTOKEN \
  -v "$HOME/.cache/pip:/pipcache" \
  -v "$PWD:/work" \
  -w /work \
  $IMAGE
