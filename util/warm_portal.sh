#!/bin/bash

proxy=$1
logroot=$2
portal=$3

locks=$logroot/locks

mkdir -p $locks

while :
do
  url=https://$portal/data.json
  portallogs=$logroot/$portal
  sleeptime=21600
  mkdir -p $portallogs

  # Load the data.json file from the portal, and skim off the identifiers w/o
  # actually parsing the json.
  now=$(date +"%Y-%m-%dT%H:%M:%S%z")

  # Pre-populate the ids file in cases where there are IDs to prepopulate
  # This is done in cases (like ACRIS in NYC) where data.json does not contain
  # a complete list of dataset IDs, due to filtered views of private data.
  cat ids/$portal/ids.txt > $portallogs/ids.log 2>/dev/null || :

  # We could select only the `rows.csv` links, but actually these are still
  # provided for non-tabular datasets (they just 400).
  ids=$(curl -k -s -S $url | grep -Po '"identifier":(.*?[^\\])",' | grep -Po '[\d\w]{4}-[\d\w]{4}')
  printf "$ids\n" >> $portallogs/ids.log
  for id in $(cat $portallogs/ids.log)
  do
    if [ $id == "data.json" ]; then
      continue
    fi

    lockno=1
    maxjobs=20
    while : ; do
      if [ $lockno -lt $maxjobs ]; then
        lockdir=$locks/${lockno}.lock
        mkdir $lockdir 2>/dev/null && break
        sleep 0.1
        lockno=$((lockno+1))
      else
        lockno=1
        sleep 5
      fi
    done

    /opendatacache/util/warm_dataset.sh "$proxy" "$logroot" "$portal" "$id" "$portallogs" "$lockdir" &
  done

  now=$(date +"%Y-%m-%dT%H:%M:%S%z")
  printf "$portal\t$now\tsleeping\t$sleeptime\n" > $portallogs/activity.log
  sleep $sleeptime
done
