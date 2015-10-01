#!/bin/bash -e


for idfile in $(find $1 -name ids.log); do
  portal=$(echo $idfile | cut -d '/' -f 3)
  echo $idfile: $portal
  mkdir -p comments/$portal
  for id in $(cat $idfile); do
    wget "https://$portal/api/views/$id/comments.json" -O comments/$portal/$id.json 
  done
done
