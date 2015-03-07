#!/bin/bash

proxy=$1
logroot=$2
portal=$3
id=$4
logs=$5
lockdir=$6

url=$proxy/$portal/api/views/$id/rows.csv
echo $url > $lockdir/url

if [ $id == "data.json" ]
then
  continue
fi

now=$(date +"%Y-%m-%dT%H:%M:%S%z")
printf "$portal\t$now\twarming\t$id\n" > $logs/status.log
#row="%{http_code}\t$id\t$now\t%{size_download}\t%{speed_download}\t%{time_connect}\t%{time_pretransfer}\t%{time_starttransfer}\t%{time_total}\t%{url_effective}\n"


mkdir -p $logs/api/views/$id
wgetlog=$logs/api/views/$id/wget.log
metadata_url=$proxy/$portal/api/views/${id}.json
#output=$(curl -k -s -S -w "$row" --compressed "$url")
#output=$(curl -k -s -S -w "$row" --compressed --retry 4 --connect-timeout 720 "$url" | tee >/dev/null >(tail -n 1) >(sed \$d | wc | sed -r 's/ +/	/g' | tr -d '\n' > $sizes))

sizes=$(wget --header='Accept-Encoding: gzip' --progress=dot --no-check-certificate -O - "$url" 2>${wgetlog} | gunzip | wc | sed -r 's/ +/	/g' | tr -d '\n')
url_effective=$(cat ${wgetlog} | head -n 1 | cut -d ' ' -f 4)
http_code=$(cat ${wgetlog} | grep -m 1 HTTP | grep -Po '\d{3}')
size_download=$(cat ${wgetlog} | tail -n 2 | cut -f 2 -d '[' | cut -f 1 -d ']' | cut -f 1 -d '/')
speed_download=$(cat ${wgetlog} | tail -n 2 | cut -f 2 -d '(' | cut -f 1 -d ')')
output="${http_code}	${id}	${now}	${size_download}	${speed_download}	${url_effective}"

metadata=$(curl -k -s -S --compressed "${metadata_url}" | tee $logs/api/views/$id/meta.json)
columns="name attribution averageRating category createdAt description displayType downloadType downloadCount newBackend numberOfComments oid rowsUpdatedAt rowsUpdatedBy tableId totalTimesRated viewCount viewLastModified viewType tags"
for key in $columns; do
  val=$(printf "$metadata" | grep "\"$key\" :" | head -n 1 | grep -Po ': .*' | tr -cd '[:print:]' | sed -r 's/^: "?//' | sed -r 's/"?,$//' | tr -s '[:space:]' ' ')
  output="$output	$val"
done
output="${output}${sizes}"

# Skip non-200 responses
#if [ ${http_code:0:1} != 2 ]; then
#  continue
#fi

echo "$output" | tee -a $logs/api/views/$id/index.log
tail -n 1 -q $logs/api/views/**/index.log > $logs/summary.log
cat $logroot/**/status.log > $logroot/status.log

rm -rf $lockdir
