#!/bin/bash

source /etc/default/varnish && varnishd ${DAEMON_OPTS}
varnishlog -D
nginx

bash
