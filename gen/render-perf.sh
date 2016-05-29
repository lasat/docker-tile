#!/bin/bash

export BUILDROOT="${BUILDROOT:-/export/build}"
export TILEROOT="${TILEROOT:-/export/tile}"
export CACHEDIR="${CACHEDIR:-${BUILDROOT}/cache}"
export DATADIR="${STYLEDIR:-${BUILDROOT}/data}"
export DBDIR="${DBDIR:-${BUILDROOT}/pg}"
export STYLEDIR="${STYLEDIR:-${BUILDROOT}/styles}"
export TMPDIR="${TMPDIR:-${CACHEDIR}}"

sseq() {
  local a
  local max
  local seq
  local i
  local j
  ((a=$1))
  ((max=$2))
  ((i=a-1))
  ((j=a+1))
  seq="$a"
  while ((i > 0)) && ((j <= max)); do
    if ((i > 0)); then
      seq="$seq $i"
      ((--i))
    fi
    if ((j <= max)); then
      seq="$seq $j"
      ((++j))
    fi
  done
  echo -n $seq
}

((np=`nproc`))
((np2=np*2))
((mp=`echo $np | awk '{print int($1 * 1.5 + 0.5)}'`))

cd "${STYLEDIR}/osmbright"
for pp in `sseq $np $mp`; do
  for tt in $np $np2 8 16 32 64; do
    t="u$tt-t$pp"
    if [ ! -e "${BUILDROOT}/perf-tlcopy-$t.log" ]; then
      rm ${TILEROOT}/test.mbtiles 
      su - osm -c "env UV_THREADPOOL_SIZE=$tt /opt/osm/node_modules/tilelive/bin/tilelive-copy --concurrency=$pp --minzoom=7 --maxzoom=7 --scheme=pyramid --retry=1000 'mapnik://${STYLEDIR}/osmbright/project.xml?metatile=8' ${TILEROOT}/test.mbtiles" > "${BUILDROOT}/perf-tlcopy-$t.log"
    fi
    for i in ${BUILDROOT}/perf-tlcopy-*.log; do echo "$i `perl -pe 's/\r/\n/g' $i | grep -a 100.0000%`" ; done | grep -a -v ' 1../s'
  done
done
for tt in $np $np2 8 16 32 64; do
  t="u$tt"
  if [ ! -e "${BUILDROOT}/perf-tl-copy-$t.log" ]; then
    rm ${TILEROOT}/test.mbtiles 
    su - osm -c "env UV_THREADPOOL_SIZE=$tt /opt/osm/node_modules/tl/bin/tl.js copy -z 7 -Z 7 -s pyramid 'mapnik://${STYLEDIR}/osmbright/project.xml?metatile=8' mbtiles://${TILEROOT}/test.mbtiles" > "${BUILDROOT}/perf-tl-copy-$t.log"
  fi
  for i in ${BUILDROOT}/perf-tl-copy-*.log; do echo "$i `tail -1 $i`" ; done
done
