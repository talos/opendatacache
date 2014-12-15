Socrata's open data portal doesn't support gzip compression of bulk file
downloads.  It also tends to be very slow in serving these large downloads, as
if a large, slow, `SELECT * FROM ...` was sitting between you and your
download...

## The solution

```
 ______  ______  ______  ______  ______  ______  __  __  ______
/\  ___\/\  __ \/\  ___\/\  == \/\  __ \/\  ___\/\ \_\ \/\  ___\
\ \___  \ \ \/\ \ \ \___\ \  __<\ \  __ \ \ \___\ \  __ \ \  __\
 \/\_____\ \_____\ \_____\ \_\ \_\ \_\ \_\ \_____\ \_\ \_\ \_____\
  \/_____/\/_____/\/_____/\/_/ /_/\/_/\/_/\/_____/\/_/\/_/\/_____/
```

Basically, we do the compression and caching Socrata's open data portals don't
do.

```
(Socrata) --> (nginx gzip) --> (varnish cache) --> (you)
```

## Take a look

A Socrache is available already at
[http://www.opendatacache.com](http://opendatacache.com).  Some example URLs:

* [New York City data summary](http://www.opendatacache.com/data.cityofnewyork.us/data.json)
* [DOB Permit Issuance](http://www.opendatacache.com/data.cityofnewyork.us/api/views/td5q-ry6d/rows.csv)

## Using docker

Pull down the docker image:

```
docker pull thegovlab/socrache
docker run -v $(pwd)/cache:/cache \
           -v $(pwd)/site:/socrache/site \
           -v $(pwd)/logs:/socrache/logs \
    -d -i -p 80:8081 --name=socrache thegovlab/socrache
```
## Warming

You can warm the server using `utils/warm.py`. You will need bash 4.x and curl.
To do so remotely against the demo installation (from the `socrache` directory):

```
mkdir -p logs/warming && \
./util/warm.sh site/portals.txt 'http://www.opendatacache.com' \
              >logs/warming/$(date +"%Y-%m-%dT%H:%M:%S%z").out.log \
             2>logs/warming/$(date +"%Y-%m-%dT%H:%M:%S%z").error.log &
```

This will save output of how long it takes to load datasets into
`logs/out.log`, which will be visible via nginx if run inside docker but
will not save any data locally.

Make sure to use the actual hostname, as opposed to `localhost`, even if you're
running locally.  Otherwise, the wrong `Host` header will be cached in Varnish.

## Manual install

Docker is the recommended/tested way to use Socrache.  A manual install is
purely at your own risk -- it assumes that your nginx settings are located in
`/etc/nginx`, which may not be the case.

Add the `conf/nginx.conf` settings to your `nginx.conf`.

Add `conf/socrache.conf` to your nginx `sites-enabled` directory.

Run `util/resolvers.sh`.  This will add a `resolvers.conf` to `/etc/nginx/`.

Add the output from `util/portals.sh conf/socrache.conf site/portals.txt` to
`/etc/nginx/sites-enabled/`.

Add the `conf/default.vcl` settings to `/etc/varnish/default.vcl`.

Add `conf/varnish` settings to `/etc/default/varnish`.

## Thanks

Thank you to [OpenPrism](https://github.com/tlevine/openprism) for its list of
Socrata portals, which is
[here](https://github.com/tlevine/openprism/blob/gh-pages/src/index.js#L24).

## TODO

* Licensing
