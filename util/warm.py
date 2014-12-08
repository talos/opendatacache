import json
import time
import sys

from urllib2 import urlopen, Request

if __name__ == '__main__':
  try:
    proxy = sys.argv[1]
  except:
    print '''ERROR you must specify proxy to warm as first argument:

python util/warm.py 'http://www.opendatacache.com'
'''
    sys.exit(1)
  print u'Warming {}'.format(proxy)

  with open('supported_portals.txt') as f:
    for host in f:
      host = host.strip()
      idx_resp = urlopen(Request(proxy + host + '/data.json'))
      for dataset in json.loads(idx_resp.read()):
        identifier = dataset['identifier']

        if identifier in ('data.json'):
          continue

        url = proxy + host + '/data/' + identifier

        req = Request(url)
        req.add_header('Accept-Encoding', 'gzip, deflate')

        print u'Requesting {}'.format(url)
        start = time.time()
        resp = urlopen(req)
        end = time.time()
        print 'time to request {}: {}'.format(url, end - start)

        print u'Reading {}'.format(url)
        start = time.time()
        respdata = resp.read()
        end = time.time()
        print 'time to download {} bytes from {}: {}'.format(len(respdata), url, end - start)
