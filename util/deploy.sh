docker pull thegovlab/opendatacache:latest
export WARM_URL="http://www.opendatacache.com"
docker run -v $(pwd)/cache:/cache \
  -v $(pwd)/site:/opendatacache/site \
  -v $(pwd)/logs:/var/log/opendatacache \
  -e "WARM_URL=$WARM_URL" \
  -d -i -p 80:8081 --name=opendatacache thegovlab/opendatacache:latest
