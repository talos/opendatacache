#!/bin/bash

docker stop opendatacache
docker rm opendatacache

docker pull thegovlab/opendatacache:latest
export WARM_URL="http://localhost:8081"
docker run \
  -e "WARM_URL=$WARM_URL" \
  -d -i -p 80:8081 --name=opendatacache thegovlab/opendatacache:latest
