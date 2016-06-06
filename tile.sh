#!/bin/sh

tg=tile/tg:latest
ts=tile/ts:latest

nproc=`nproc`
THREADS=`perl -e '$n=int($ARGV[0]*0.75); print $n > 0 ? $n : 1'`

build() {
  test -d /export/tile-"$1" || return 1
  docker run -d --rm \
    --name gen \
    -v /export/scratch:/export/scratch \
    -v /export/tile-"$1":/export/tile \
    -v /export/build:/export/build \
    -e THREADS=$THREADS \
    -e CACHEDIR=/export/scratch/cache \
    -e PLANETPBF=/export/scratch/planet-latest.osm.pbf \
    -p 8888:8888 \
    $tg
}

serve() {
  test -d /export/tile-"$1" || return 1
  docker run -d \
    --name tile-"$1" \
    --log-opt max-size=100m --log-opt max-file=10 \
    --restart=unless-stopped \
    -v /export/tile-"$1":/export/tile:ro \
    -p `perl -e "print 8080 + ord('$1') - ord('a')"`:80 \
    $ts
}

stop() {
  case "$1" in
    build)
      docker stop gen
      ;;
    *)
      docker stop tile-"$1"
      ;;
  esac
}

clean() {
  docker stop build tile-a tile-b
  docker rm build tile-a tile-b
  rm -rf /export/build/* /export/scratch/*
}

usage() {
  cat - <<EOF >&2
usage:
  sudo tile build { a, b }
  sudo serve { a, b }
  sudo stop { build, a, b }
  sudo clean
EOF

case "$1" in
  build|serve|stop|clean)
    "$1" "$@"
    ;;
  *)
    usage
    exit 1
    ;;
esac
