OSM Tile Generation & Serving Docker Containers
===============================================

Overview
--------

 * Tiles are generated from OSM Planet PBF, using PostGIS, Imposm,
   Mapnik, and Tilelive.
 * Tiles are served with Apache, mod_wsgi, and Tilestache.
 * Tiles are written to a MBTiles file in the `/export/tile` volume of
   the generation docker container and served from the `/export/tile`
   volume of the server container(s).
 * Typically one would have a `/export/tile-a` and `/export/tile-b` on
   the host, and alternate mounting them to server or generation
   containers.
 * During generation a preview live tile server will run on port 8888
   of the generation container.
 * High level generation status is written out, and served at
   `/status.txt` if a server and the generating container share the
   `/export/tile` volume.
 * The included script [tile.sh](tile.sh) somewhat simplifies use, run
   without arguments for help.

Storage
-------

 * On the host, make volumes (preferably all on SSDs):

    mkdir -p /export/tile-a /export/tile-b   # to hold tiles
    mkdir -p /export/build                   # to hold PostGIS DB
    mkdir -p /export/scratch                 # cache, temp files etc

 * Backup `/export/tile-*/*.mbtiles` if you wish to backup the rendered
   tiles.  Backup `/export/build` only if needed for style development.

Create a Tile Server
--------------------

Make two persistent instances for "A" and "B", on port 8080 and 8081
respectively.

    sudo docker run --name tile-a -p 8080:80 -v /export/tile-a:/export/tile:ro --log-opt max-size=100m --log-opt max-file=10 --restart=unless-stopped -d tile/ts

    sudo docker run --name tile-b -p 8081:80 -v /export/tile-b:/export/tile:ro --log-opt max-size=100m --log-opt max-file=10 --restart=unless-stopped -d tile/ts

Generate Tiles
--------------

Run generation container on "A" or "B" (replace `XXX` below):

    sudo docker run --name gen-XXX -p 8888:8888 -v /export/tile-XXX:/export/tile -v /export/build:/export/build -d tile/tg

URLs
----

#### Tiles

 * A: http://localhost:8080/tiles/osm/{z}/{x}/{y}.png
 * B: http://localhost:8081/tiles/osm/{z}/{x}/{y}.png

#### Tile Generation Status

  * A: http://localhost:8080/status.txt
  * B: http://localhost:8081/status.txt

#### Tile Generation Live Preview

 * http://localhost:8888/tiles/osm/{z}/{x}/{y}.png


Other Commands
--------------

#### Show running tile tasks (containers)

    sudo docker ps

#### Show server or build logs

    sudo docker logs tile-a
    sudo docker logs gen-a

#### Stop/start tasks (containers)

    sudo docker start tile-a
    sudo docker stop tile-a

#### Cleanup tile generation container(s)

    sudo docker rm gen-a gen-b

Building Container Images
-------------------------

    sudo docker build -t tile/ts server
    sudo docker build -t tile/tg gen
