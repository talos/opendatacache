Socrata's open data portal doesn't support gzip compression of bulk file
downloads.  It also tends to be very slow in serving these large downloads, as
if a large, slow, `SELECT * FROM ...` was sitting between you and your
download...

## The solution

```
  _____  _____  ______  ____   _  _____   ____     __    ____    ______  ____    ______  __   _  ______
 /     \|     ||   ___||    \ | ||     \ |    \  _|  |_ |    \  |   ___||    \  |   ___||  |_| ||   ___|
 |     ||    _||   ___||     \| ||      \|     \|_    _||     \ |   |__ |     \ |   |__ |   _  ||   ___|
 \_____/|___|  |______||__/\____||______/|__|\__\ |__|  |__|\__\|______||__|\__\|______||__| |_||______|
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

## Using docker

Pull down the docker image:

```
docker pull thegovlab/opendatacache
docker run -v $(pwd)/site:/opendatacache/site \
    -d -i -p 80:8081 --name=opendatacache thegovlab/opendatacache
```
## Warming

If you want the container to warm, you must feed it the name of the server it
is publicly accessible as as the `WARM_URL`. For example:

```
export WARM_URL="http://your.url.here" && \
docker run -v $(pwd)/site:/opendatacache/site \
           -e "WARM_URL=$WARM_URL" \
    -d -i -p 80:8081 --name=opendatacache thegovlab/opendatacache
```

Make sure to use the actual hostname, as opposed to `localhost`, even if you're
running locally.  Otherwise, the wrong `Host` header will be cached in Varnish.

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
