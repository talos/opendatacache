"""
Warm the cache.
"""

import json
import time
import sys
from urlparse import urljoin
from urllib2 import urlopen, Request

if __name__ == '__main__':
    try:
        PROXY = sys.argv[1]
    except IndexError:
        sys.stderr.write(
            '''ERROR you must specify PROXY to warm as first argument:

python util/warm.py 'http://www.opendatacache.com/'
''')
        sys.exit(1)
    sys.stdout.write(u'Warming {}\n'.format(PROXY))
    sys.stdout.flush()

    with open('supported_portals.txt') as f:
        for host in f:
            host = host.strip()
            idx_resp = urlopen(Request(urljoin(PROXY, host + '/data.json')))
            for dataset in json.loads(idx_resp.read()):
                identifier = dataset['identifier']

                if identifier in ('data.json', ):
                    continue

                url = urljoin(PROXY, host + '/data/' + identifier)

                req = Request(url)
                req.add_header('Accept-Encoding', 'gzip, deflate')

                sys.stdout.write(u'Requesting {}\n'.format(url))
                start = time.time()
                resp = urlopen(req)
                end = time.time()
                sys.stdout.write(u'time to request {}: {}\n'.format(
                    url, end - start))
                sys.stdout.flush()

                sys.stdout.write(u'Reading {}\n'.format(url))
                start = time.time()
                respdata = resp.read()
                end = time.time()
                sys.stdout.write(
                    u'time to download {} bytes from {}: {}\n'.format(
                        len(respdata), url, end - start))
                sys.stdout.flush()
