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
    except IndexError:
        sys.stderr.write(
            '''ERROR you must specify PROXY to warm as first argument:

python util/warm.py 'http://www.opendatacache.com/'
''')
        sys.exit(1)
    sys.stdout.write(u'{}\t{}\t{}\n'.format('warm', PROXY, datetime.now()))
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

                start = time.time()

                try:
                    resp = urlopen(req)
                except HTTPError as err:
                    end = time.time()
                    sys.stdout.write(u'{}\t{}\t{}\t{}\t\n'.format(
                        'request', err, url, end - start))
                    sys.stderr.flush()
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
