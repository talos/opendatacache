#!/bin/bash

proxy=$1
logroot=$2
portal=$3
id=$4
portallogs=$5
lockdir=$6
now=$(date +"%Y-%m-%dT%H:%M:%S%z")

url=$proxy/$portal/api/views/$id/rows.csv

printf "$portal\t$now\twarming\t$id\t$url\n" > $lockdir/activity

mkdir -p $portallogs/api/views/$id
wgetlog=$portallogs/api/views/$id/wget.log
metadata_url=$proxy/$portal/api/views/${id}.json

# Download the data
TMPDIR=/tmp/$portal/api/views/$id/views/${id}
mkdir -p $TMPDIR
wget --header='Accept-Encoding: gzip' --progress=dot --no-check-certificate -O $TMPDIR/data \
  "$url" 2>${wgetlog}

# measure the data
sizes=$(gunzip $TMPDIR/data | wc | xargs | tr ' ' '\t')

url_effective=$(cat ${wgetlog} | head -n 1 | cut -d ' ' -f 4)
http_code=$(cat ${wgetlog} | grep -m 1 HTTP | grep -Po '\d{3}')
size_download=$(cat ${wgetlog} | tail -n 2 | cut -f 2 -d '[' | cut -f 1 -d ']' | cut -f 1 -d '/')
speed_download=$(cat ${wgetlog} | tail -n 2 | cut -f 2 -d '(' | cut -f 1 -d ')')
output="${http_code}	${id}	${now}	${size_download}	${speed_download}	${url_effective}"

# construct metadata about download
metadata=$(curl -k -s -S --compressed "${metadata_url}" | tee $portallogs/api/views/$id/meta.json)
columns="name attribution averageRating category createdAt description displayType downloadType downloadCount newBackend numberOfComments oid rowsUpdatedAt rowsUpdatedBy tableId totalTimesRated viewCount viewLastModified viewType tags"
for key in $columns; do
  val=$(echo "$metadata" | grep "\"$key\" :" | head -n 1 | grep -Po ': .*' | tr -cd '[:print:]' | tr -d '\\' | sed -r 's/^: "?//' | sed -r 's/"?,$//' | tr -s '[:space:]' ' ')
  output="$output	$val"
done
output="${output}	${sizes}"

# Skip non-200 responses
#if [ ${http_code:0:1} != 2 ]; then
#  continue
#fi

echo "$output" | tee -a $portallogs/api/views/$id/index.log
echo $portal > /opendatacache/update.pipe

rm -rf $lockdir
