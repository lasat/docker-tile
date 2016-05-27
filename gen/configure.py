#!/usr/bin/env python

from os import path, getcwd
from collections import defaultdict
config = defaultdict(defaultdict)

config['importer'] = 'osm2pgsql'
config['name'] = 'osm-bright'
config['path'] = '/export/build/styles'
config['postgis']['host']     = ''
config['postgis']['port']     = ''
config['postgis']['dbname']   = 'osm'
config['postgis']['user']     = ''
config['postgis']['password'] = ''
config['postgis']['extent'] = '-20037508.34,-20037508.34,20037508.34,20037508.34'

#config['land-high'] = 'http://data.openstreetmapdata.com/simplified-land-polygons-complete-3857.zip'
config['land-high'] = '/export/build/data/simplified-land-polygons-complete-3857.zip'

#config['land-low'] = 'http://data.openstreetmapdata.com/land-polygons-split-3857.zip'
config['land-low'] = '/export/build/data/land-polygons-split-3857.zip'
