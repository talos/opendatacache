"""
Warm the cache.
"""

import json
import time
import sys
from datetime import datetime
from urlparse import urljoin
from urllib2 import urlopen, Request, HTTPError

if __name__ == '__main__':
    try:
        PROXY = sys.argv[1]
        PORTAL = sys.argv[2]
    except IndexError:
        sys.stderr.write(
            '''You must specify both the proxy and the portal to request.

python util/warm.py ${proxy} ${supported_portal}

For example:

python util/warm.py 'http://www.opendatacache.com/' 'data.cityofnewyork.gov'
''')
        sys.exit(1)
    sys.stdout.write(u'{}\t{}\t{}\n'.format('warm', PROXY, datetime.now()))
    sys.stdout.flush()

    DATA_JSON_URL = urljoin(PROXY, PORTAL + '/data.json')
    for dataset in json.loads(urlopen(Request(DATA_JSON_URL)).read()):
        identifier = dataset['identifier']

        if identifier in ('data.json', ):
            continue

        url = urljoin(PROXY, u'{portal}/api/views/{id}/rows.csv'.format(
            portal=PORTAL, id=identifier))

        req = Request(url)
        req.add_header('Accept-Encoding', 'gzip, deflate')

        start = time.time()

        try:
            resp = urlopen(req)
        except HTTPError as err:
            end = time.time()
            sys.stdout.write(u'{}\t{}\t{}\t{}\t\n'.format(
                'request', err, url, end - start))
            sys.stdout.flush()
        else:
            end = time.time()
            sys.stdout.write(u'{}\t{}\t{}\t{}\t\n'.format(
                'request', 'success', url, end - start))
            sys.stdout.flush()

            start = time.time()
            try:
                respdata = resp.read()
            except HTTPError as err:
                end = time.time()
                sys.stdout.write(u'{}\t{}\t{}\t{}\t\n'.format(
                    'content', err, url, end - start))
            else:
                end = time.time()
                sys.stdout.write(u'{}\t{}\t{}\t{}\t{}\n'.format(
                    'content', 'success', url, end - start,
                    len(respdata)))
        sys.stdout.flush()
