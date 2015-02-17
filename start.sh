#!/bin/bash

source /etc/default/varnish && varnishd ${DAEMON_OPTS}
nginx

sleep 1
varnishlog -D

sleep 5

if [ ${WARM_URL} ]
then
  echo "warming ${WARM_URL}"
  mkdir -p /var/log/opendatacache && util/warm.sh site/portals.txt ${WARM_URL} \
     > >(tee /var/log/opendatacache/out.log) 2> >(tee /var/log/opendatacache/error.log >&2) &
fi

bash
