#
# Opendatacache Dockerfile
#
# https://github.com/talos/opendatacache
#

FROM debian:wheezy
MAINTAINER John Krauss <irving.krauss@gmail.com>

# installs
RUN apt-get update && apt-get -y dist-upgrade
RUN apt-get install -yqq curl openssl ca-certificates apt-transport-https wget nginx unzip python

# nginx keys
RUN echo "deb http://nginx.org/packages/debian/ wheezy nginx" >> /etc/apt/sources.list.d/nginx.list
RUN apt-key adv --fetch-keys "http://nginx.org/keys/nginx_signing.key"

# nginx configs
COPY conf/nginx.conf /etc/nginx/nginx.conf
RUN rm -rf /etc/nginx/sites-enabled/*
RUN rm -rf /etc/nginx/conf.d/*
RUN mkdir -p /etc/nginx/sites-enabled

# awscli
RUN curl "https://s3.amazonaws.com/aws-cli/awscli-bundle.zip" -o "awscli-bundle.zip"
RUN unzip awscli-bundle.zip
RUN ./awscli-bundle/install -i /usr/local/aws -b /usr/local/bin/aws

COPY ids  /opendatacache/ids

# logs
RUN ln -sf /dev/stdout /var/log/nginx/access.log
RUN ln -sf /dev/stderr /var/log/nginx/error.log

EXPOSE 8080

WORKDIR opendatacache

#CMD ["/opendatacache/start.sh"]
