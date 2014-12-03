import json
import time

from urllib2 import urlopen, Request

if __name__ == '__main__':
  with open('supported_portals.txt') as f:
    for host in f:
      host = host.strip()
      idx_resp = urlopen(Request('http://localhost:5003/' + host + '/data.json'))
      for dataset in json.loads(idx_resp.read()):
        identifier = dataset['identifier']

        if identifier in ('data.json'):
          continue

        url = 'http://localhost:5003/' + host + '/data/' + identifier

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
