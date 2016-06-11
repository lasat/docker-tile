#!/bin/sh

tg=tile/tg
ts=tile/ts

nproc=`nproc`
THREADS=`perl -e '$n=int($ARGV[0]*0.75); print $n > 0 ? $n : 1' $nproc`

status() {
  docker ps -a

  echo ""
  echo "==> A"
  cat /export/tile-a/status.txt
  echo ""
  echo "==> B"
  cat /export/tile-b/status.txt
}

build() {
  test -d /export/tile-"$1" || return 1
  docker rm gen-"$1"
  docker run -d \
    --name gen-"$1" \
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
      docker stop gen-a gen-b gen
      ;;
    *)
      docker stop tile-"$2"
      ;;
  esac
}

clean() {
  docker stop gen gen-a gen-b tile-a tile-b
  docker rm gen gen-a gen-b tile-a tile-b
  rm -rf /export/build/* /export/build/.??* /export/scratch/*
}

usage() {
  cat - <<EOF >&2
usage:
  # show quick status
  tile status

  # build new tiles for "a" or "b" data set
  tile build { a, b }

  # create & start server for "a" or "b" data set
  tile serve { a, b }

  # force shutdown of build process
  tile stop build

  # force shutdown of "a" or "b" server
  tile stop a b

  # clean up (remove) build and server containers
  tile clean
EOF
}

case "$1" in
  status|build|serve|stop|clean)
    "$@"
    ;;
  *)
    usage
    exit 1
    ;;
esac
