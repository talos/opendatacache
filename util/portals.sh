#!/bin/bash

# portals.sh : generate an nginx config that only allows proxying for specified
# portals
#
# ./portals.sh NGINX_CONFIG PORTAL_FILE
#
# For example,
#
# util/portals.sh conf/opendatacache site/portals.txt

export REGEX=$(head -c -1 $2 | tr '\n' '|') && sed s/__PROXY_REGEX__/$(echo ${REGEX})/g $1
