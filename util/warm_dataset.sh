#!/bin/bash

proxy=$1
logroot=$2
portal=$3
id=$4
logs=$5
lockdir=$6
now=$(date +"%Y-%m-%dT%H:%M:%S%z")

url=$proxy/$portal/api/views/$id/rows.csv

printf "$portal\t$now\twarming\t$id\t$url\n" | tee $lockdir/activity > $logs/status.log

mkdir -p $logs/api/views/$id
wgetlog=$logs/api/views/$id/wget.log
metadata_url=$proxy/$portal/api/views/${id}.json

sizes=$(wget --header='Accept-Encoding: gzip' --progress=dot --no-check-certificate -O - "$url" 2>${wgetlog} | gunzip | wc | xargs | tr ' ' '\t')
url_effective=$(cat ${wgetlog} | head -n 1 | cut -d ' ' -f 4)
http_code=$(cat ${wgetlog} | grep -m 1 HTTP | grep -Po '\d{3}')
size_download=$(cat ${wgetlog} | tail -n 2 | cut -f 2 -d '[' | cut -f 1 -d ']' | cut -f 1 -d '/')
speed_download=$(cat ${wgetlog} | tail -n 2 | cut -f 2 -d '(' | cut -f 1 -d ')')
output="${http_code}	${id}	${now}	${size_download}	${speed_download}	${url_effective}"

metadata=$(curl -k -s -S --compressed "${metadata_url}" | tee $logs/api/views/$id/meta.json)
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

echo "$output" | tee -a $logs/api/views/$id/index.log
echo $portal > /opendatacache/update.pipe

rm -rf $lockdir
