Socrata's open data portal doesn't support gzip compression of bulk file
downloads.  It also tends to be very slow in serving these large downloads, as
if a large, slow, `SELECT * FROM ...` was sitting between you and your
download...

## The solution

```
   ___                   ____        _         ____           _
  / _ \ _ __   ___ _ __ |  _ \  __ _| |_ __ _ / ___|__ _  ___| |__   ___
 | | | | '_ \ / _ \ '_ \| | | |/ _` | __/ _` | |   / _` |/ __| '_ \ / _ \
 | |_| | |_) |  __/ | | | |_| | (_| | || (_| | |__| (_| | (__| | | |  __/
  \___/| .__/ \___|_| |_|____/ \__,_|\__\__,_|\____\__,_|\___|_| |_|\___|
       |_|
```

Basically, we do the compression and caching Socrata's open data portals don't
do.

```
(Socrata) --> (nginx gzip) --> (varnish cache) --> (you)
```

## Take a look

An Opendatacache is available already at
[http://www.opendatacache.com](http://opendatacache.com).  Some example URLs:

* [New York City data summary](http://www.opendatacache.com/data.cityofnewyork.us/data.json)
* [DOB Permit Issuance](http://www.opendatacache.com/data.cityofnewyork.us/api/views/td5q-ry6d/rows.csv)

## Deploying

### Using docker

To run locally, you can just use the `util/test.sh` script.

    $ util/test.sh

This is equivalent to:

    $ CACHE_SIZE=2G WARM_URL=http://localhost:8081 PORT=8080 util/run.sh

In other words, this will run a docker container with OpenDataCache running
inside.  The server will have a 2GB (small) cache, will automatically warm
itself, and will expose port 8080.

If you wanted to do this manually using docker commands, take a look at
`util/run.sh`.

#### A note on cache warming

If a `WARM_URL` is specified as above, as soon as the container starts a shell
script will begin crawling open data portals and caching their contents.

### In production

In a production environment, you can use:

    util/deploy.sh

This is equivalent to

    CACHE_SIZE=24G WARM_URL=http://localhost:8081 PORT=80 ./run.sh

In other words, it will use a 24GB cache and expose port 80.  You can adjust
the size of the cache

## Manual install

Docker is the recommended/tested way to use Opendatacache.  A manual install is
purely at your own risk -- it assumes that your nginx settings are located in
`/etc/nginx`, which may not be the case.

Add the `conf/nginx.conf` settings to your `nginx.conf`.

Add `conf/opendatacache.conf` to your nginx `sites-enabled` directory.

Run `util/resolvers.sh`.  This will add a `resolvers.conf` to `/etc/nginx/`.

Add the output from `util/portals.sh conf/opendatacache.conf site/portals.txt` to
`/etc/nginx/sites-enabled/`.

Add the `conf/default.vcl` settings to `/etc/varnish/default.vcl`.

Add `conf/varnish` settings to `/etc/default/varnish`.

## Thanks

Thank you to [OpenPrism](https://github.com/tlevine/openprism) for its list of
Socrata portals, which is
[here](https://github.com/tlevine/openprism/blob/gh-pages/src/index.js#L24).

## TODO

* Licensing
