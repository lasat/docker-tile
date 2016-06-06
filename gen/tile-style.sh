# style name
STYLE_NAME="osmbright"

# style url
STYLE_URL="mapnik://${STYLEDIR}/${STYLE_NAME}/project.xml?metatile=8"

# options needed for osm2pgsql for this style
OSM2PGSQL_FLAGS="--multi-geometry"

# options needed for imposm for this style
IMPOSM_MAPPING="${STYLEDIR}/${STYLE_NAME}/imposm-mapping.py"

get_extra_data() {
  LOG "downloading land polygons"
  wget -N --no-verbose --progress=dot:mega --show-progress -P "${DATADIR}" \
    http://data.openstreetmapdata.com/simplified-land-polygons-complete-3857.zip
  wget -N --no-verbose --progress=dot:mega --show-progress -P "${DATADIR}" \
    http://data.openstreetmapdata.com/land-polygons-split-3857.zip
  (cd "${DATADIR}" && shapeindex *.shp) || return 1
}

setup_style() {
  local url="https://github.com/ndpgroup/osm-bright/archive/5337a8c5bf1764a4dfb7173e02ba147b19b531b4.tar.gz"
  local dir="${TMPDIR:-/tmp}/${STYLE_NAME}"

  mkdir -p "${STYLEDIR}/${STYLE_NAME}" "${dir}"

  LOG "downloading style from: ${url}"
  wget -O - "${url}" | tar -zxf - --strip=1 -C "${dir}" || return 1

  LOG "setting up map style"
  cp /opt/osm/configure.py "${dir}/"
  (cd "${dir}" && ./make.py) || return 1
  (cd "${STYLEDIR}/${STYLE_NAME}" && /opt/osm/node_modules/carto/bin/carto -l -n project.mml > project.xml) || return 1
  cp "${dir}/imposm-mapping.py" "${STYLEDIR}/${STYLE_NAME}/"

  mkdir -p "${DATADIR}"
  chmod 1777 "${DATADIR}"

  LOG "downloading & importing natural earth data"
  (cd "${dir}" && su - osm -c "env TMPDIR=${DATADIR} ./ne2pgsql")

  get_extra_data || return 1
}

export MAPNIK_FONT_PATH=`find /usr/share/fonts -type d | env LC_ALL=C sort | tr '\n' ':'`
