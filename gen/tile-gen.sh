#!/bin/bash

# Copyright (c) 2016, NDP, LLC
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# * Redistributions of source code must retain the above copyright notice, this
#   list of conditions and the following disclaimer.
#
# * Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

set -x

umask 022

export BUILDROOT="${BUILDROOT:-/export/build}"
export TILEROOT="${TILEROOT:-/export/tile}"
export CACHEDIR="${CACHEDIR:-${BUILDROOT}/cache}"
export DATADIR="${STYLEDIR:-${BUILDROOT}/data}"
export DBDIR="${DBDIR:-${BUILDROOT}/pg}"
export STYLEDIR="${STYLEDIR:-${BUILDROOT}/styles}"
export TMPDIR="${TMPDIR:-${CACHEDIR}}"

export IMPORTER="${IMPORTER:-osm2pgsql}"
export THREADS="${THREADS:-8}"
export MAXZOOM="${MAXZOOM:-12}"

MIRROR="${MIRROR:-http://ftp.osuosl.org/pub/openstreetmap/pbf/planet-latest.osm.pbf}"
PLANETPBF="${PLANETPBF:-${BUILDROOT}/planet-latest.osm.pbf}"
PGBIN="${PGBIN:-/usr/lib/postgresql/9.5/bin}"

TMPFILE=""

# setup fd 3 for status log
: > "${TILEROOT}/status.txt"
chmod 644 "${TILEROOT}/status.txt"
exec 3> "${TILEROOT}/status.txt"

LOG() {
  local ts=`date '+[%Y-%m-%dT%H:%M:%S%z]'`
  echo "$ts [tile-gen]" "$@" >&3 || true
  echo "$ts [tile-gen]" "$@" >&2 || true
}

DEBUG() {
  echo `date '+[%Y-%m-%dT%H:%M:%S%z]'` '[tile-gen]' "$@" || true
}

FAIL() {
  LOG "FAILURE:" "$@" || true
  return 1
}

ABORT() {
  FAIL "$@" || true
  exit 1
}

mark() {
  echo "$1" `date '+%Y-%m-%dT%H:%M:%S%z'` > "${BUILDROOT}/.ts.$1"
}

newer() {
  if [ -e "${BUILDROOT}/.ts.$1" ] && [ -e "${BUILDROOT}/.ts.$2" ]; then
    test "${BUILDROOT}/.ts.$1" -nt "${BUILDROOT}/.ts.$2"
  else
    true
  fi
}

pre_clean() {
  rm -rf "${CACHEDIR}"/* >/dev/null 2>&1 || true
  rm -rf "${TMPDIR}"/* >/dev/null 2>&1 || true
}

get_planet() {
  if [ -n "$SKIP_PLANET" ]; then
    return 0
  fi
  TMPFILE=`mktemp "${PLANETPBF}.XXXXXX"`
  LOG "downloading planet: $MIRROR -> $TMPFILE"
  if wget --no-verbose --progress=dot:mega --show-progress -O "$TMPFILE" "$MIRROR"; then
    mv "$TMPFILE" "${PLANETPBF}.new" || return 1
    TMPFILE=""
    if [ -e "${PLANETPBF}" ]; then
      rm -f "${PLANETPBF}.old" 2>/dev/null
      mv "${PLANETPBF}" "${PLANETPBF}.old"
    fi
    mv "${PLANETPBF}.new" "${PLANETPBF}" || return 1
    chmod 644 "${PLANETPBF}"
    mark planet
  else
    FAIL "unable to download planet"
  fi
}

get_landpoly() {
  LOG "downloading land polygons"
  mkdir -p "${DATADIR}"
  wget -N --no-verbose --progress=dot:mega --show-progress -P "${DATADIR}" \
    http://data.openstreetmapdata.com/simplified-land-polygons-complete-3857.zip
  wget -N --no-verbose --progress=dot:mega --show-progress -P "${DATADIR}" \
    http://data.openstreetmapdata.com/land-polygons-split-3857.zip
}

start_database() {
  su - postgres -c "${PGBIN}/pg_ctl -D '${DBDIR}' -w start $*"
}

stop_database() {
  su - postgres -c "${PGBIN}/pg_ctl -D '${DBDIR}' -w stop -m fast"
}

init_database() {
  mkdir -p "${DBDIR}"
  chmod 700 "${DBDIR}"
  chown -R postgres "${DBDIR}"

  if [ ! -e "${DBDIR}/PG_VERSION" ]; then
    LOG "initializing postgres database"
	  su - postgres -c "${PGBIN}/initdb -E UTF8 -D '${DBDIR}'"

    start_database
    su - postgres -c "${PGBIN}/createuser --no-superuser --no-createrole --createdb osm"
    su - postgres -c "${PGBIN}/createdb -E UTF8 -O osm osm"
    su - postgres -c "${PGBIN}/createlang plpgsql osm"
    su - postgres -c "${PGBIN}/psql -q -b -d osm -c 'CREATE EXTENSION hstore;'"
    su - postgres -c "${PGBIN}/psql -q -b -d osm -f /usr/share/postgresql/9.5/contrib/postgis-2.2/postgis.sql"
    su - postgres -c "${PGBIN}/psql -q -b -d osm -f /usr/share/postgresql/9.5/contrib/postgis-2.2/spatial_ref_sys.sql"
    su - postgres -c "${PGBIN}/psql -q -b -d osm -f /usr/lib/python2.7/dist-packages/imposm/900913.sql"
    stop_database
  fi

  cp /opt/osm/pg_hba.conf "${DBDIR}/"
  cp /opt/osm/postgres.conf "${DBDIR}/"
  chown postgres "${DBDIR}"/*.conf
}

import_planet() {
  if newer planet import; then
    LOG "importing planet into postgresql with ${IMPORTER}"
    case "${IMPORTER}" in
      osm2pgsql)
        import_planet_osm2pgsql || return 1
        ;;
      imposm)
        import_planet_imposm || return 1
        ;;
      *)
        FAIL "invalid importer: $IMPORTER"
        return 1
        ;;
    esac
    mark import
  fi
}

import_planet_osm2pgsql() {
  su - osm -c "time osm2pgsql \
    --create \
    --slim \
    --cache=8000 \
    --database=osm \
    --multi-geometry \
    --number-processes=${THREADS} \
    --unlogged \
    --cache-strategy=dense \
    --flat-nodes='${CACHEDIR}/nodes.cache' \
    '${PLANETPBF}'"
}

import_planet_imposm() {
  su - osm -c "time imposm \
    --connection=postgis:///osm \
    -m /opt/osm/osm-bright/imposm-mapping.py \
    --overwrite-cache \
    --cache-dir=${CACHEDIR} \
    --concurrency=${THREADS} \
    --read \
    --write \
    --optimize \
    --deploy-production-tables \
    '${PLANETPBF}'"
}

setup_style() {
  LOG "setting up map style"
  mkdir -p "${STYLEDIR}"
  (cd /opt/osm/osm-bright && ./make.py)
  (cd "${STYLEDIR}/osmbright" && /opt/osm/node_modules/carto/bin/carto -l -n project.mml > project.xml)
  (cd "${DATADIR}" && shapeindex *.shp)
}

start_renderer() {
  true
}

render_tiles() {
  if newer import tiles; then
    export MAPNIK_FONT_PATH=`find /usr/share/fonts -type d | env LC_ALL=C sort | tr '\n' ':'`
    LOG "rendering tiles to: ${TILEROOT}/osm-bright"
    /opt/osm/render-list.pl "${MAXZOOM}" > "${TMPDIR}/render-list.txt"
    echo "{\"minzoom\":0,\"maxzoom\":$MAXZOOM,\"bounds\":[-180,-85.0511,180,85.0511]}" > "${TILEROOT}/osm-bright/metadata.json"
    (cd "${STYLEDIR}/osmbright" && su - osm -c "env 'MAPNIK_FONT_PATH=$MAPNIK_FONT_PATH' 'SRC=mapnik://${STYLEDIR}/osmbright/project.xml' 'DST=file://${TILEROOT}/osm-bright' xargs -a '${TMPDIR}/render-list.txt' -n 1 -P ${THREADS} /opt/osm/tl-render.sh") || return 1
    mark tiles
  fi
}

package_tiles() {
  if newer tiles mbtiles; then
    LOG "packaging tiles to: ${TILEROOT}/osm-bright.mbtiles"
    /opt/osm/node_modules/tl/bin/tl.js copy -q -z 0 -Z "${MAXZOOM}" "file://${TILEROOT}/osm-bright" "mbtiles://${TILEROOT}/osm-bright.mbtiles"
    mark mbtiles
  fi
}

cleanup() {
  LOG "cleaning up"
  if [ -n "$TMPFILE" ]; then
    rm -f "$TMPFILE" 2>/dev/null
    TMPFILE=""
  fi
  stop_database
}

trap cleanup 0

mkdir -p "${BUILDROOT}" "${TILEROOT}" "${CACHEDIR}" "${DATADIR}" "${STYLEDIR}" "${TMPDIR}"

pre_clean
get_planet     || ABORT "OSM planet download failed (aborting)"
get_landpoly   || ABORT "land/admin data download failed (aborting)"
setup_style    || ABORT "style pre-processing failed (aborting)"
init_database  || ABORT "database initialization failed (aborting)"
start_database || ABORT "database startup failed (aborting)"
import_planet  || ABORT "OSM planet import failed (aborting)"
start_renderer || ABORT "render daemon startup failed (aborting)"
if ! render_tiles; then
  STATUS=1
  FAIL "tile rendering failed/incomplete (continuing)"
else
  STATUS=1
fi
package_tiles  || ABORT "tile packaging failed (aborting)"
if [ $STATUS = 0 ]; then
  LOG "tile generation completed successfully"
else
  LOG "tile generation completed with errors"
fi
exit $STATUS
