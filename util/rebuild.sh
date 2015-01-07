sudo docker build -t opendatacache:latest . && \
  sudo docker run \
  -v $(pwd)/site:/opendatacache/site \
  -v $(pwd)/logs:/var/log/opendatacache \
  -e "WARM_URL=http://localhost:8081" \
  -i --rm -p \
  80:8081 opendatacache:latest
