#!/bin/bash

# Warm a single dataset
#
#     ./util/warm_dataset.sh <portal> <id> [lock number]
#
# For example
#
#     ./util/warm_dataset.sh data.cityofnewyork.us 23rb-xz43 0
#

source util/constants.sh

portal=$1
id=$2
lockno=$3
portallogs=$logroot/$portal

if [ $lockno ]; then
  lockdir=$locks/${lockno}.lock
fi

now=$(date +"%Y-%m-%dT%H:%M:%S%z")

url=$proxy/$portal/api/views/$id/rows.csv

if [ $lockno ]; then
  printf "$portal\t$now\twarming\t$id\t$url\n" > $lockdir/activity
fi

mkdir -p $portallogs/api/views/$id
wgetlog=$portallogs/api/views/$id/wget.log
metadata_url=$proxy/$portal/api/views/${id}.json

# obtain metadata about download
metadata=$(curl -k -s -S --compressed "${metadata_url}" | tee $portallogs/api/views/$id/meta.json)
columns="name attribution averageRating category createdAt description displayType downloadType downloadCount newBackend numberOfComments oid rowsUpdatedAt rowsUpdatedBy tableId totalTimesRated viewCount viewLastModified viewType tags"
for key in $columns; do
  val=$(echo "$metadata" | grep "\"$key\" :" | head -n 1 | grep -Po ': .*' | tr -cd '[:print:]' | tr -d '\\' | sed -r 's/^: "?//' | sed -r 's/"?,$//' | tr -s '[:space:]' ' ')
  output="$output	$val"
done

INDEX_LOG=$portallogs/api/views/$id/index.log

# if metadata indicates change, update
if [ -e $INDEX_LOG ]; then
  LAST_ROWS_UPDATED_AT=$(tail -n 1 $INDEX_LOG | cut -f 19)
  ROWS_UPDATED_AT=$(echo -e "${output}" | cut -f 14)

  if [ "$LAST_ROWS_UPDATED_AT" == "$ROWS_UPDATED_AT" ]; then
    if [ $lockno ]; then
      rm -rf $lockdir
    fi
    exit 0
  fi
fi

# Download the data
TMPDIR=/tmp/$portal/api/views/$id
DATAFILE=$TMPDIR/rows.csv
mkdir -p $TMPDIR
wget -S --header='Accept-Encoding: gzip' --progress=dot --no-check-certificate -O $DATAFILE \
  "$url" 2>${wgetlog}

# measure the data
sizes=$(gunzip -c $DATAFILE | wc | xargs | tr ' ' '\t')
output="${output}	${sizes}"

url_effective=$(cat ${wgetlog} | head -n 1 | cut -d ' ' -f 4)
http_code=$(cat ${wgetlog} | grep -m 1 'HTTP/' | grep -Po '\d{3}')
size_download=$(cat ${wgetlog} | tail -n 2 | cut -f 2 -d '[' | cut -f 1 -d ']' | cut -f 1 -d '/')
speed_download=$(cat ${wgetlog} | tail -n 2 | cut -f 2 -d '(' | cut -f 1 -d ')')
output="${http_code}	${id}	${now}	${size_download}	${speed_download}	${url_effective}${output}"

echo "$output" | tee -a $INDEX_LOG

# Skip non-200 responses
#if [ ${http_code:0:1} != 2 ]; then
#  continue
#fi


# Upload to aws
CONTENT_TYPE=$(echo $(grep 'Content-Type' $wgetlog | cut -d ':' -f 2))
CONTENT_DISPOSITION=$(echo $(grep 'Content-disposition' $wgetlog | cut -d ':' -f 2))
aws s3api put-object \
  --bucket $S3_BUCKET \
  --key $portal/api/views/$id/rows.csv \
  --body $DATAFILE \
  --content-disposition "${CONTENT_DISPOSITION}" \
  --content-type "${CONTENT_TYPE}" \
  --content-encoding gzip > /dev/null

if [ -e $pipe ]; then
  echo $portal > $pipe
fi

rm -f $DATAFILE

if [ $lockno ]; then
  rm -rf $lockdir
fi
