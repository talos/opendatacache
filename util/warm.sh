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

portals=$1
proxy=$2
logroot=/var/log/opendatacache

# Warm one single portal.  All curl requests for data are run in series, as not
# to spam the portal.
function warm_portal {
  while :
  do
    portal=$1
    url=https://$portal/data.json
    logs=$logroot/$portal
    sleeptime=21600
    mkdir -p $logs

    # Load the data.json file from the portal, and skim off the identifiers w/o
    # actually parsing the json.
    now=$(date +"%Y-%m-%dT%H:%M:%S%z")

    # Pre-populate the ids file in cases where there are IDs to prepopulate
    cat ids/$portal/ids.txt > $logs/ids.log 2>/dev/null || :

    # We could select only the `rows.csv` links, but actually these are still
    # provided for non-tabular datasets (they just 400).
    ids=$(curl -s -S $url | grep -Po '"identifier":(.*?[^\\])",' | grep -Po '[\d\w]{4}-[\d\w]{4}')
    printf "$ids\n" >> $logs/ids.log
    for id in $(cat $logs/ids.log)
    do
      if [ $id == "data.json" ]
      then
        continue
      fi
      now=$(date +"%Y-%m-%dT%H:%M:%S%z")
      printf "$portal\t$now\twarming\t$id\n" > $logs/status.log
      row="$id\t$now\t%{http_code}\t%{size_download}\t%{speed_download}\t%{time_connect}\t%{time_total}\t%{url_effective}\n"
      url=$proxy/$portal/api/views/$id/rows.csv
      output=$(curl -s -S -w "$row" --raw -o /dev/null -H 'Accept-Encoding: gzip, deflate' "$url")
      mkdir -p $logs/api/views/$id
      printf "$output\n" | tee -a $logs/api/views/$id/index.log
      tail -n 1 -q $logs/api/views/**/index.log > $logs/summary.log
      cat $logroot/**/status.log > $logroot/status.log

      sleep $(($RANDOM / 5000))
    done

    now=$(date +"%Y-%m-%dT%H:%M:%S%z")
    printf "$portal\t$now\tsleeping\t$sleeptime\n" > $logs/status.log
    sleep $sleeptime
  done
}

# Warm all our portals, by running a subprocess to warm each individual portal
# in parallel.
for portal in $(cat $1); do
  warm_portal $portal &
done
