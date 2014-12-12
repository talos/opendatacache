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
# util/warm.sh site/portals.txt 'http://www.opendatacache.com' > logs/out.log 2> logs/error.log
#
# While all data will be downloaded, it will be dumped to /dev/null.

portals=$1
proxy=$2

# Arguments for analytics for each request by curl.  We print the header so
# that stdout can be read as a tab-delimited file.
header="time\thttp_code\tremote_ip\tsize_download\tspeed_download\ttime_connect\ttime_total\turl_effective\n"
printf $header

# Warm one single portal.  All curl requests for data are run in series, as not
# to spam the portal.
function warm_portal {
  portal=$1
  url="$proxy/$portal/data.json"

  # Load the data.json file from the portal, and skim off the identifiers w/o
  # actually parsing the json.
  now=$(date +"%Y-%m-%dT%H:%M:%S%z")
  ids=$(curl -s -S -w "$ow" $url | grep -Po '"identifier":(.*?[^\\])",' | cut -b 15-23)
  printf "$ids\n" > logs/$portal/ids-$now.log
  for id in $ids
  do
    printf "$id\t$now\n" > logs/$portal/current-id.log
    now=$(date +"%Y-%m-%dT%H:%M:%S%z")
    row="$now\t%{http_code}\t%{remote_ip}\t%{size_download}\t%{speed_download}\t%{time_connect}\t%{time_total}\t%{url_effective}\n"
    path=$portal/api/views/$id
    url=$proxy/$path/rows.csv
    output=$(curl -s -S -w "$row" --raw -o /dev/null -H 'Accept-Encoding: gzip, deflate' "$url")
    mkdir -p logs/$path
    printf "$output\n" | tee -a logs/$path/logs.log
  done
}

# Warm all our portals, by running a subprocess to warm each individual portal
# in parallel.
for portal in $(cat $1); do
  warm_portal $portal &
done

# Wait for all subprocesses to finish before exiting the master process.
wait
