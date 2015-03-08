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
    logs=$logroot/$portal
    tail -n 1 -q $logs/api/views/**/index.log > $logs/summary.log
    cat $logroot/**/status.log > $logroot/status.log
    cat $logroot/locks/**/activity > $logroot/activity.log
    sleep 0.1

    #locks=$logroot/locks
  fi
done

#echo "Reader exiting"
#
#
#while : ; do
#  for portal in $(cat portals); do
#    sleep 0.3
#  done
#  sleep 5
#done
