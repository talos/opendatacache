#
# Socrache Dockerfile
#
# https://github.com/talos/socrache
#

FROM debian:wheezy
MAINTAINER John Krauss <irving.krauss@gmail.com>

# utility installs
RUN apt-get update && apt-get -y dist-upgrade
RUN apt-get install -yqq curl openssl ca-certificates apt-transport-https

# nginx keys
RUN echo "deb http://nginx.org/packages/debian/ wheezy nginx" >> /etc/apt/sources.list.d/nginx.list
RUN apt-key adv --fetch-keys "http://nginx.org/keys/nginx_signing.key"

# varnish keys
RUN echo "deb https://repo.varnish-cache.org/debian/ wheezy varnish-4.0" >> /etc/apt/sources.list.d/varnish-cache.list
RUN curl https://repo.varnish-cache.org/debian/GPG-key.txt | apt-key add -

# installs
RUN apt-get -yqq install nginx varnish

# Resolver for nginx
ADD ./resolvers.sh /resolvers.sh
RUN /resolvers.sh

# nginx configs
ADD nginx.conf /etc/nginx/nginx.conf
RUN rm -rf /etc/nginx/sites-enabled/*
RUN rm -rf /etc/nginx/conf.d/*
ADD socrache.conf /etc/nginx/sites-enabled/socrache.conf

# varnish configs
ADD default.vcl /etc/varnish/default.vcl
ADD varnish /etc/default/varnish

# logs
RUN ln -sf /dev/stdout /var/log/nginx/access.log
RUN ln -sf /dev/stderr /var/log/nginx/error.log

EXPOSE 8081
EXPOSE 8080

# get everything running
ADD start.sh /start.sh
CMD ["/start.sh"]
