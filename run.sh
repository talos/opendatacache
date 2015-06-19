#!/bin/bash

docker rm -f opendatacache || :

#docker pull thegovlab/opendatacache:latest

docker run -v $(pwd)/site:/opendatacache/site \
           -v $(pwd)/util:/opendatacache/util \
           -v $(pwd)/conf:/opendatacache/conf \
           -v $(pwd)/.aws:/root/.aws \
           -d -i -p 80:8080 --name=opendatacache thegovlab/opendatacache /opendatacache/start.sh

#WARM_URL=http://localhost:8080 
           #-e "WARM_URL=$WARM_URL" \
