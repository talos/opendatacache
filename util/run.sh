#!/bin/bash

docker rm -f opendatacache || :

docker pull thegovlab/opendatacache:latest

docker run -v $(pwd)/site:/opendatacache/site \
           -v $(pwd)/util:/opendatacache/util \
           -e "WARM_URL=$WARM_URL" \
           -e CACHE_SIZE=$CACHE_SIZE -d -i -p $PORT:8081 --name=opendatacache thegovlab/opendatacache
