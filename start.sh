#!/bin/bash

/opendatacache/util/portals.sh /opendatacache/conf/opendatacache.conf /opendatacache/site/portals.txt > /etc/nginx/sites-enabled/opendatacache.conf

/opendatacache/util/resolvers.sh

nginx

sleep 5

if [ ${WARM_URL} ]
then
  echo "warming ${WARM_URL}"
  mkdir -p /var/log/opendatacache && util/warm.sh site/portals.txt ${WARM_URL} \
     > >(tee /var/log/opendatacache/out.log) 2> >(tee /var/log/opendatacache/error.log >&2) &
fi

bash
