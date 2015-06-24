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
(Socrata) --> (nginx gzip) --> (AWS S3) --> (you)
```

## Take a look

An Opendatacache is available already at
[http://www.opendatacache.com](http://opendatacache.com).  Some example URLs:

* [New York City data summary](http://www.opendatacache.com/data.cityofnewyork.us/data.json)
* [DOB Permit Issuance](http://www.opendatacache.com/data.cityofnewyork.us/api/views/td5q-ry6d/rows.csv)

## Deploying

### Using docker

You should build the image locally, then you can run it:

    $ ./build.sh
    $ WARM=1 ./run.sh

#### A note on cache warming

If you don't specify `WARM=1` as above, the image will start & serve, but will
not cache any new datasets.  Its listings will be based on prior caching progress
in the `log/` folder.

## Thanks

Thank you to [OpenPrism](https://github.com/tlevine/openprism) for its list of
Socrata portals, which is
[here](https://github.com/tlevine/openprism/blob/gh-pages/src/index.js#L24).

## TODO

* Licensing
