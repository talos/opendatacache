#!/bin/bash

# warm.sh : warm our proxy for a series of portals
#
# util/warm.sh PORTAL_FILE PROXY_URL
#
# PORTAL_FILE should be a newline-delimited list of open data portals, without
# the protocol.
#
# PROXY_URL should be a complete publicly accessible URL, including the
# protocol, to the proxy that should be warmed.  There should be no trailing
# slash.
#
# For example,
#
# util/warm.sh site/portals.txt 'http://www.opendatacache.com'
#
# All identifiers for each portal will be loaded in a parallel separate
# process, and then each identifier will be used to request all data sets in
# series.  You will probably want to run this in the background and direct the
# logs to a sensible location, for example:
#
# mkdir -p /var/log/opendatacache && util/warm.sh site/portals.txt 'http://www.opendatacache.com' >> /var/log/opendatacache/out.log 2>>/var/log/opendatacache/error.log &
#
# While all data will be downloaded, it will be dumped to /dev/null.

source util/constants.sh

# Start update script to update user-facing web interface
/opendatacache/util/update.sh &

# Warm all our portals, by running a subprocess to warm each individual portal
# in parallel.
for portal in $(cat $portals); do
  /opendatacache/util/warm_portal.sh $portal &
done
