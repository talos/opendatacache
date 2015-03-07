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
    .connect_timeout = 1200s;
    .first_byte_timeout = 1200s;
    .between_bytes_timeout = 1200s;
}

sub vcl_recv {
    # Upon initial request, keep track of the data URL and the URL where
    # last modified data can be obtained quickly.  Never cache this (pass).
    #
    # Upon second request, use the data URL, and hash it.
    unset req.http.Cookie;
    if (req.restarts == 0) {
        if (req.url ~ "\.csv") {
            set req.http.X-Data-URL = regsub(req.url, "^([^?]+)\?.*$", "\1");
            set req.http.X-Meta-URL = regsub(req.url, "^(.*)/rows.csv\??.*$", "\1.json");
            if (req.url ~ "(?i)test=true") {
                set req.http.X-Opendatacache-Test = "true";
            } else if (req.url ~ "(?i)ignore=true") {
                set req.http.X-Opendatacache-Ignore = "true";
            } else if (req.url ~ "(?i)lazy=true") {
                set req.http.X-Opendatacache-Lazy = "true";
                return (hash);
            } else {
                set req.http.X-Opendatacache-Strict = "true";
            }
            set req.url = req.http.X-Meta-URL;
        }
        return (pass);
    } else if (req.restarts > 1 && req.restarts < 3) {
        set req.url = req.http.X-Data-URL;

        if (req.method == "MISS") {
            set req.hash_always_miss = true;
            set req.http.X-Opendatacache-Force-Miss = "true";
        }

        return (hash);
    } else {
        return (synth(503, "Too many restarts"));
    }
}

sub vcl_hash {
    # Generate the hash based off the data URL and the last modified from the
    # metadata request.
    if (req.http.X-Data-URL) {
        hash_data(req.http.X-Data-URL);
        #if (req.restarts == 1) {
        #    hash_data(req.http.X-Meta-Last-Modified);
        #}
    } else {
        hash_data(req.url);
    }
    return (lookup);
}

sub vcl_hit {
    # Keep track of the age of the last modified
    set req.http.X-Opendatacache-Last-Modified = obj.http.Last-Modified;
    if (req.restarts == 1) {
        if (req.http.X-Opendatacache-Test) {
            if (obj.http.Last-Modified == req.http.X-Meta-Last-Modified) {
                return(synth(204, obj.http.Last-Modified + " :: object in cache"));
            } else {
                return(synth(404, "Cache last modified: " + obj.http.Last-Modified + "; Meta last modified" + req.http.X-Meta-Last-Modified));
            }
        }
        if (req.http.X-Opendatacache-Strict) {
            if (obj.http.Last-Modified != req.http.X-Meta-Last-Modified) {
                purge;
                return(restart);
            }
        }
    }
}

sub vcl_miss {
    if (req.restarts == 1) {
        if (req.http.X-Opendatacache-Test) {
            return(synth(404, "Object missing from cache"));
        }
    }
}

sub vcl_backend_response {
    # Never automatically evict this from cache.
    set beresp.ttl = 31536000s;
}

sub vcl_deliver {
    # Never return the meta response.
    # Store the Last-Modified header from the meta response in the request
    # HTTP headers as "X-Meta-Last-Modified" (this is used in hashing in
    # `vcl_hash`)
    #
    # If we've restarted, then this is from the cache hit or backend request
    # for the data itself.  Prevent the client from caching this (we're fine if
    # they keep hitting us) and append some debug headers.
    set resp.http.X-Opendatacache-Hits = obj.hits;
    if (!req.http.X-Data-URL) {
        return (deliver);
    }
    if (req.http.X-Opendatacache-Lazy) {
        return (deliver);
    }

    if (req.restarts == 0) {
        set req.http.X-Meta-Last-Modified = resp.http.Last-Modified;
        return (restart);
    } else if (req.restarts > 1 && req.restarts < 3) {
        set resp.http.X-Meta-Last-Modified = req.http.X-Meta-Last-Modified;
        set resp.http.X-Meta-URL = req.http.X-Meta-URL;
        set resp.http.X-Data-URL = req.http.X-Data-URL;
        set resp.http.X-Opendatacache-Last-Modified = req.http.X-Opendatacache-Last-Modified;
        set resp.http.X-Opendatacache-Force-Miss = req.http.X-Opendatacache-Force-Miss;
        if (req.http.X-Opendatacache-Last-Modified) {
          set resp.http.X-From-Opendatacache = 1;
        } else {
          set resp.status = 201;
          set resp.http.X-From-Opendatacache = 0;
        }
        set resp.http.cache-control = "private, max-age=0, no-cache";
    }
}
