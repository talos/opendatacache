#!/bin/bash

/opendatacache/util/portals.sh /opendatacache/conf/opendatacache.conf /opendatacache/site/portals.txt > /etc/nginx/sites-enabled/opendatacache.conf

/opendatacache/util/resolvers.sh

nginx

sleep 5

if [ $WARM ]; then
  util/warm.sh \
     > >(tee /var/log/opendatacache/out.log) \
     2> >(tee /var/log/opendatacache/error.log >&2) &
fi

bash
