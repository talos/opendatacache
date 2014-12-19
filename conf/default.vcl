#
# This is an example VCL file for Varnish.
#
# It does not do anything by default, delegating control to the
# builtin VCL. The builtin VCL is called when there is no explicit
# return statement.
#
# See the VCL chapters in the Users Guide at https://www.varnish-cache.org/docs/
# and http://varnish-cache.org/trac/wiki/VCLExamples for more examples.

# Marker to tell the VCL compiler that this VCL has been adapted to the
# new 4.0 format.
vcl 4.0;

# Default backend definition. Set this to point to your content server.
# OPENDATACACHE: point the port to the port you're serving it on
backend default {
    .host = "127.0.0.1";
    .port = "8080";
    .connect_timeout = 60s;
    .first_byte_timeout = 240s;
    .between_bytes_timeout = 60s;
}

sub vcl_recv {

    unset req.http.Cookie;

    # Always lookup hash.
    return (hash);
}

sub vcl_hit {
    # Always make the request to the backend to see if Last-Modified has
    # changed.

    set req.http.X-Cached-Last-Modified = obj.http.Last-Modified;

    return (pass);
}

sub vcl_backend_fetch {
    # Rewrite any requests for "rows.csv" to the metadata route:
    #
    # /data.cityofnewyork.us/api/views/bnx9-e6tj/rows.csv ->
    # /data.cityofnewyork.us/api/views/bnx9-e6tj
    #
    # This should give us quick access to the relevant Last-Modified header,
    # allowing us to see whether our cache is out of date.
    if (bereq.retries == 0) {
        set bereq.http.X-Original-URL = bereq.url;
        set bereq.url = regsub(bereq.url, "^(.*)/rows.csv$", "\1.json");
        return (fetch);
    } else if (bereq.retries == 1) {
        set bereq.url = bereq.http.X-Original-URL;
        return (fetch);
    } else {
        return (abandon);
    }
}

sub vcl_backend_response {
    # Never automatically evict this from cache.
    set beresp.ttl = 31536000s;

    if (bereq.retries == 0) {
        # Check the Last-Modified header in the new response.  If it matches
        # the one in cache, use the cache; otherwise, change the URL back to
        # rows.csv and restart.

        if (beresp.http.Last-Modified == bereq.http.X-Cached-Last-Modified) {
            return (deliver);
        } else {
            return (retry);
        }
    }
}

sub vcl_deliver {
    set resp.http.X-Cached-Last-Modified = req.http.X-Cached-Last-Modified;
}
