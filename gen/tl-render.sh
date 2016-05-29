#!/bin/sh

SRC="${SRC:-mapnik:///export/build/styles/osmbright/project.xml}"
DST="${DST:-file:///export/tile/osm-bright}"

zoom=`echo $1 | cut -d: -f 1`
col0=`echo $1 | cut -d: -f 2`
col1=`echo $1 | cut -d: -f 3`

tl=/opt/osm/node_modules/tl/bin/tl.js

xtile2long()
{
  zoom=$1
  xtile=$2
  echo "${xtile} ${zoom}" | awk '{printf("%.9f", $1 / 2.0^$2 * 360.0 - 180)}'
} 

lat1=85.0511
lat0=-$lat1
lon0=`xtile2long $zoom $col0`
lon1=`xtile2long $zoom $col1`

ts=`date '+%s'`
$tl copy -q -z $zoom -Z $zoom -b "$lon0 $lat0 $lon1 $lat1" "${SRC}?metatile=8" "$DST" || exit 1
ts2=`date '+%s'`
rate=`perl -e "print((2**$zoom)*($col1-$col0)/($ts2-$ts))"`
echo "==> Completed $zoom:$col0:$col1 @ $rate tiles/sec" >&2
return 0
