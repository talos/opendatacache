#!/bin/bash -e

logroot=/var/log/opendatacache
portals=site/portals.txt
proxy=http://localhost:8080
pipe=/opendatacache/update.pipe
locks=$logroot/locks
S3_BUCKET=data.opendatacache.com

mkdir -p $logroot
mkdir -p $locks
