#!/bin/bash -e

import json
import os
import logging
import csv
import sys
from datetime import datetime


HEADERS = ['date', 'id', 'child_of', 'view_url', 'view_name', 'author', 'text']


ID = [0]

def writecomment(portal, comment, writer, child_of=''):
    ID[0] += 1
    writer.writerow({
        'id': ID[0],
        'text': comment.get('body').encode('utf8').replace('\n', r'\n'),
        'author': comment.get('user', {}).get('displayName', '').encode('utf8'),
        'view_url': 'https://{}/_/_/{}'.format(portal, comment.get('view', {}).get('id')),
        'view_name': comment.get('view', {}).get('name').encode('utf8'),
        'date': datetime.fromtimestamp(comment.get('createdAt')).strftime('%Y/%m/%d %H:%M:%S'),
        'child_of': child_of
    })
    if 'children' in comment:
        parent_id = ID[0]
        children = comment['children']
        children.reverse()
        for child in children:
            writecomment(portal, child, writer, child_of=parent_id)
    

def run():
    '''
    
    '''
    comment_path = sys.argv[1]
    portal = comment_path.split('/')[-1] or comment_path.split('/')[-2]

    obj = []
    with open('{}.csv'.format(portal), 'w') as outfile:
        writer = csv.DictWriter(outfile, HEADERS)
        writer.writeheader()
        for dirpath, dirnames, filenames in os.walk(comment_path):
            for filename in filenames:
                try:
                    comments = json.load(open(os.path.join(dirpath, filename)))
                    comments.reverse()
                    for comment in comments:
                        writecomment(portal, comment, writer)
                except ValueError as e:
                    logging.error('Could not load comment from %s', os.path.join(dirpath, filename))


if __name__ == '__main__':
    run()
