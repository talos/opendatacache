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
