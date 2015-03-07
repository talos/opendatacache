#!/bin/bash

proxy=$1
logroot=$2
portal=$3

while :
do
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
  ids=$(curl -k -s -S $url | grep -Po '"identifier":(.*?[^\\])",' | grep -Po '[\d\w]{4}-[\d\w]{4}')
  printf "$ids\n" >> $logs/ids.log
  for id in $(cat $logs/ids.log)
  do
    /opendatacache/util/warm_dataset.sh "$proxy" "$logroot" "$portal" "$id" "$logs" &
    sleep 1
  done

  now=$(date +"%Y-%m-%dT%H:%M:%S%z")
  printf "$portal\t$now\tsleeping\t$sleeptime\n" > $logs/status.log
  sleep $sleeptime
done
