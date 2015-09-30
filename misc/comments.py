#!/bin/bash -e

import json
import os
import logging
import csv
from datetime import datetime


HEADERS = ['date', 'id', 'child_of', 'view_url', 'view_name', 'author', 'text']


ID = [0]

def writecomment(comment, writer, child_of=''):
    ID[0] += 1
    writer.writerow({
        'id': ID[0],
        'text': comment.get('body').encode('utf8').replace('\n', r'\n'),
        'author': comment.get('user', {}).get('displayName', '').encode('utf8'),
        'view_url': 'https://data.cityofnewyork.us/_/_/{}'.format(comment.get('view', {}).get('id')),
        'view_name': comment.get('view', {}).get('name').encode('utf8'),
        'date': datetime.fromtimestamp(comment.get('createdAt')).strftime('%Y/%m/%d %H:%M:%S'),
        'child_of': child_of
    })
    if 'children' in comment:
        parent_id = ID[0]
        children = comment['children']
        children.reverse()
        for child in children:
            writecomment(child, writer, child_of=parent_id)
    

def run():
    '''
    
    '''
    obj = []
    with open('comments.csv', 'w') as outfile:
        writer = csv.DictWriter(outfile, HEADERS)
        writer.writeheader()
        for dirpath, dirnames, filenames in os.walk('comments'):
            for filename in filenames:
                try:
                    comments = json.load(open(os.path.join(dirpath, filename)))
                    comments.reverse()
                    for comment in comments:
                        writecomment(comment, writer)
                except ValueError as e:
                    import pdb
                    pdb.set_trace()
                    logging.error('Could not load comment from %s/%s', dirpath, filename)


if __name__ == '__main__':
    run()
