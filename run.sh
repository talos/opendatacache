#!/bin/bash

docker rm -f opendatacache || :

#docker pull thegovlab/opendatacache:latest
source .env || :
#export APP_TOKEN=$APP_TOKEN
echo $APP_TOKEN

docker run -v $(pwd)/site:/opendatacache/site \
           -v $(pwd)/util:/opendatacache/util \
           -v $(pwd)/conf:/opendatacache/conf \
           -v $(pwd)/log:/var/log/opendatacache \
           -v $(pwd)/.aws:/root/.aws \
           -e "WARM=$WARM" \
           -e "APP_TOKEN=$APP_TOKEN" \
           -d -i -p 80:8080  --name=opendatacache thegovlab/opendatacache /opendatacache/util/start.sh

#WARM_URL=http://localhost:8080 
           #-e "WARM_URL=$WARM_URL" \
