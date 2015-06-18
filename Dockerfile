#
# Opendatacache Dockerfile
#
# https://github.com/talos/opendatacache
#

FROM debian:wheezy
MAINTAINER John Krauss <irving.krauss@gmail.com>

# installs
RUN apt-get update && apt-get -y dist-upgrade
RUN apt-get install -yqq curl openssl ca-certificates apt-transport-https wget nginx

# nginx keys
RUN echo "deb http://nginx.org/packages/debian/ wheezy nginx" >> /etc/apt/sources.list.d/nginx.list
RUN apt-key adv --fetch-keys "http://nginx.org/keys/nginx_signing.key"

# nginx configs
COPY conf/nginx.conf /etc/nginx/nginx.conf
RUN rm -rf /etc/nginx/sites-enabled/*
RUN rm -rf /etc/nginx/conf.d/*
RUN mkdir -p /etc/nginx/sites-enabled

# Resolver and regex for nginx
#COPY util /opendatacache/util
#COPY site /opendatacache/site
#COPY conf /opendatacache/conf
COPY ids  /opendatacache/ids

#RUN /opendatacache/util/portals.sh /opendatacache/conf/opendatacache.conf /opendatacache/site/portals.txt > /etc/nginx/sites-enabled/opendatacache.conf

# logs
RUN ln -sf /dev/stdout /var/log/nginx/access.log
RUN ln -sf /dev/stderr /var/log/nginx/error.log

EXPOSE 8080

# get everything running
ADD start.sh /opendatacache/start.sh

WORKDIR opendatacache

#CMD ["/opendatacache/start.sh"]
