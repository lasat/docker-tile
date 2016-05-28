FROM ubuntu:16.04

RUN apt-get update && apt-get install -y apt-transport-https ca-certificates curl git lsb-release software-properties-common vim wget

RUN wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - && \
    echo 'deb http://apt.postgresql.org/pub/repos/apt/ xenial-pgdg main' >> /etc/apt/sources.list.d/postgresql.list && \
    apt-get update && \
    apt-get install -y \
    postgresql-9.5 \
    postgresql-contrib-9.5 \
    postgis-2.2 \
    postgresql-9.5-postgis-2.2
    
RUN echo 'deb http://ppa.launchpad.net/ubuntugis/ppa/ubuntu trusty main' >> /etc/apt/sources.list.d/ubuntugis-ppa-trusty.list && \
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 314DF160 && \
    apt-get update && \
    apt-get install -y \
    gdal-bin \
    imposm \
    libfreexl-dev \
    libfreexl1 \
    libgdal-dev \
    libgdal1-dev \
    libgdal1i \
    libgeos-3.5.0 \
    libgeos-dev \
    libmapnik-dev \
    libproj-dev \
    libproj9 \
    libspatialite-dev \
    libspatialite7 \
    libsqlite3-dev \
    mapnik-doc \
    mapnik-utils \
    osm2pgsql \
    osmctools \
    proj-bin \
    proj-data \
    python-gdal \
    python-imposm \
    spatialite-bin \
    sqlite3 \
    tilelite

RUN apt-get update && \
    apt-get install -y \
    fonts-dejavu \
    fonts-indic \
    fonts-khmeros \
    fonts-sil-padauk \
    fonts-sipa-arundina \
    fonts-taml \
    ttf-unifont

RUN wget --quiet -O - https://deb.nodesource.com/gpgkey/nodesource.gpg.key | apt-key add - && \
    echo 'deb https://deb.nodesource.com/node_4.x xenial main' >> /etc/apt/sources.list.d/node.list && \
    apt-get update && \
    apt-get install -y nodejs

RUN adduser --system --home /opt/osm --shell /bin/bash --group --gecos "GIS User" osm

RUN npm install -g npm@~3.3.12
COPY package.json /opt/osm/
RUN su - osm -c "npm install"

RUN mkdir -p /opt/osm/osm-bright
COPY configure.py /opt/osm/osm-bright/
RUN \
  mkdir -p /opt/osm/osm-bright && \
  wget -O - https://github.com/mapbox/osm-bright/archive/3757b1a399102ac60f03541156fd183d68df14d9.tar.gz | \
    tar -zxf - --strip=1 -C /opt/osm/osm-bright && \
  perl -pi -e 's/"DejaVu Sans (Bold )?Italic",//g;s/"unifont Medium"/"Unifont Medium"/g;' /opt/osm/osm-bright/osm-bright/palette.mss && \
  (cd /opt/osm/osm-bright && ./make.py build) && \
  chown -R osm /opt/osm/osm-bright

RUN mkdir -p /export/build /export/tile && chmod 1777 /export/build /export/tile

VOLUME /export/build
VOLUME /export/tile

COPY pg_hba.conf /opt/osm/
COPY postgres.conf /opt/osm/
COPY render-list.pl /opt/osm/
COPY tile-gen.sh /opt/osm/
COPY tl-render.sh /opt/osm/

CMD [ "/opt/osm/tile-gen.sh" ]
