#!/usr/bin/env python

from os import path, getcwd, getenv
from collections import defaultdict
config = defaultdict(defaultdict)

config['importer'] = getenv('IMPORTER', 'osm2pgsql')
config['name'] = 'osmbright'
config['path'] = getenv('STYLEDIR', '/export/build/styles')
config['postgis']['host']     = ''
config['postgis']['port']     = ''
config['postgis']['dbname']   = 'osm'
config['postgis']['user']     = ''
config['postgis']['password'] = ''
config['postgis']['extent'] = '-20037508.34,-20037508.34,20037508.34,20037508.34'

#config['land-high'] = 'http://data.openstreetmapdata.com/simplified-land-polygons-complete-3857.zip'
config['land-high'] = getenv('DATADIR', '/export/build/data') + '/simplified-land-polygons-complete-3857.zip'

#config['land-low'] = 'http://data.openstreetmapdata.com/land-polygons-split-3857.zip'
config['land-low'] = getenv('DATADIR', '/export/build/data') + '/land-polygons-split-3857.zip'
