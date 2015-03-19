#!/bin/bash

# update.sh : update user-facing summary log files for web display
#
# This is called by util/warm.sh . Previously every individual portal did its
# own updating, but this is expensive.
#

portals=$1
logroot=$2

pipe=/opendatacache/update.pipe

trap "rm -f $pipe" EXIT

if [[ ! -p $pipe ]]; then
  mkfifo $pipe
fi

while true
do
  if read portal <$pipe; then
    now=$(date +"%Y-%m-%dT%H:%M:%S%z")
    portallogs=$logroot/$portal

    # Keep track of last misses for speed information
    for log in $portallogs/api/views/*/index.log; do
      lastmiss=$(dirname $log)/lastmiss.log
      tac $log | grep -m 1 '^201' > $lastmiss
    done

    tail -n 1 -q $portallogs/api/views/**/index.log > $portallogs/summary.log

    cat $logroot/locks/**/activity > $logroot/activity.log
    grep "$portal" $logroot/activity.log > $portallogs/activity.log
    active=$(cat $portallogs/activity.log | wc -l)
    checked=$(cat $portallogs/summary.log | wc -l)
    total=$(cat $portallogs/ids.log | wc -l)
    printf "$portal\t$now\t$active\t$checked\t$total\n" > $portallogs/status.log
    cat $logroot/**/status.log > $logroot/status.log

    sleep 0.1
  fi
done
