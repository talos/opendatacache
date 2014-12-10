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
# util/warm.sh site/portals.txt 'http://www.opendatacache.com' > site/warmlogs/out.txt 2> site/warmlogs/error.txt
#
# While all data will be downloaded, it will be dumped to /dev/null.

portals=$1
proxy=$2

# Arguments for analytics for each request by curl.  We print the header so
# that stdout can be read as a tab-delimited file.
row="%{http_code}\t%{remote_ip}\t%{size_download}\t%{speed_download}\t%{time_connect}\t%{time_total}\t%{url_effective}\n"
header="http_code	remote_ip	size_download	speed_download	time_connect	time_total	url_effective"
echo $header

# Warm one single portal.  All curl requests for data are run in series, as not
# to spam the portal.
function warm_portal {
  portal=$1
  url="$proxy/$portal/data.json"

  # Load the data.json file from the portal, and skim off the identifiers w/o
  # actually parsing the json.
  for id in $(curl $url | grep -Po '"identifier":(.*?[^\\])",' | cut -b 15-23)
  do
    url="$proxy/$portal/api/views/$id/rows.csv"
    curl -# -w "$row" -o /dev/null -H 'Accept-Encoding: gzip, deflate' "$url"
  done
}

# Warm all our portals, by running a subprocess to warm each individual portal
# in parallel.
for portal in $(cat $1); do
  warm_portal $portal &
done

# Wait for all subprocesses to finish before exiting the master process.
wait
