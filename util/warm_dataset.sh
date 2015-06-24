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


if [ $lockno ]; then
  printf "$portal\t$now\twarming\t$id\n" > $lockdir/activity
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

view_type=$(echo -e "${output}" | cut -f 20)

if [ "$view_type" == blobby ]; then
  blob_mime_type=$(echo "$metadata" | grep "\"blobMimeType\" :" | head -n 1 | grep -Po ': .*' | tr -cd '[:print:]' | tr -d '\\' | sed -r 's/^: "?//' | sed -r 's/"?,$//' | tr -s '[:space:]' ' ' | cut -d ';' -f 1)
  key="$portal/download/$id/$blob_mime_type"
  url="$proxy/nocache/$key"
elif [ "$view_type" == tabular ]; then
  key="$portal/api/views/$id/rows.csv"
  url="$proxy/nocache/$key"
  gzip_on=true
elif [ "$view_type" == href ]; then
  if [ $lockno ]; then
    rm -rf $lockdir
  fi
  echoerr "Skipping $portal \"$id\", can't handle viewType \"$view_type\""
  exit 0
elif [ "$view_type" == geo ]; then
  key="$portal/api/geospatial/$id"
  url="$proxy/nocache/$key?method=export&format=Shapefile"
else
  if [ $lockno ]; then
    rm -rf $lockdir
  fi
  echoerr "Skipping $portal \"$id\", unknown viewType \"$view_type\""
  exit 0
fi

index_log=$portallogs/api/views/$id/index.log

# if metadata indicates change, update
if [ -e $index_log ]; then
  prior_status=$(tail -n 1 $index_log | cut -f 1)

  prior_rows_updated=$(tail -n 1 $index_log | cut -f 19)
  rows_updated=$(echo -e "${output}" | cut -f 14)

  prior_view_last_modified=$(tail -n 1 $index_log | cut -f 24)
  view_last_modified=$(echo -e "${output}" | cut -f 19)

  # use rowsUpdatedAt if possible, otherwise viewLastModified
  if [ "$rows_updated" -a "$prior_rows_updated" ]; then
    prior_update_time="$prior_rows_updated"
    update_time="$rows_updated"
  else
    prior_update_time="$prior_view_last_modified"
    update_time="$view_last_modified"
  fi

  if [ "$prior_status" != "200" ]; then
    echoerr "Redownloading $url, prior status was $prior_status"
  elif [ "$prior_update_time" == "$update_time" ]; then
    if [ $lockno ]; then
      rm -rf $lockdir
    fi
    echoerr "Skipping $url, last metadata and current metadata both have view_last_modified of $view_last_modified"
    exit 0
  fi
fi

# Download the data
tmpdir=/tmp/$portal/$id
data_file=$tmpdir/data
mkdir -p $tmpdir
wget -S --header='Accept-Encoding: gzip' --progress=dot --no-check-certificate -O $data_file \
  "$url" 2>${wgetlog}

# measure the data
if [ $gzip_on ]; then
  sizes=$(gunzip -c $data_file | wc | xargs | tr ' ' '\t')
  aws_encoding_option="--content-encoding gzip"
else
  sizes=$(cat $data_file | wc | xargs | tr ' ' '\t')
fi
output="${output}	${sizes}"

url_effective=$(cat ${wgetlog} | head -n 1 | cut -d ' ' -f 4)
http_code=$(tac ${wgetlog} | grep -m 1 'HTTP/' | grep -Po '\d{3}')
size_download=$(cat ${wgetlog} | tail -n 2 | cut -f 2 -d '[' | cut -f 1 -d ']' | cut -f 1 -d '/')
speed_download=$(cat ${wgetlog} | tail -n 2 | cut -f 2 -d '(' | cut -f 1 -d ')')
output="${http_code}	${id}	${now}	${size_download}	${speed_download}	${url_effective}${output}"

echo "$output" | tee -a $index_log

# Upload to aws
content_type=$(echo $(grep 'Content-Type' $wgetlog | cut -d ':' -f 2))
content_disposition=$(echo $(grep 'Content-disposition' $wgetlog | cut -d ':' -f 2))
aws s3api put-object \
  --bucket $S3_BUCKET \
  --key $key \
  --body $data_file \
  --content-disposition "${content_disposition}" \
  --content-type "${content_type}" \
  $aws_encoding_option > /dev/null

if [ -e $pipe ]; then
  echo $portal > $pipe
fi

rm -f $data_file

if [ $lockno ]; then
  rm -rf $lockdir
fi
