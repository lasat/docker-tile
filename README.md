Create a Tile Server
--------------------

    sudo docker run --name tile-a -p 8080:80 -v /export/tile-a:/export/tile:ro --log-opt max-size=100m --log-opt max-file=10 --restart=unless-stopped -d tile/ts:2.2

    sudo docker run --name tile-b -p 8081:80 -v /export/tile-b:/export/tile:ro --log-opt max-size=100m --log-opt max-file=10 --restart=unless-stopped -d tile/ts:2.2

Generate Tiles
--------------

    sudo docker run --name gen -p 8888:8888 -v /export/tile-XXX:/export/tile -v /export/build:/export/build -d tile/tg:2.2


Other Commands
--------------

#### Show running tile tasks (containers)

    sudo docker ps

#### Stop/start tasks (containers)

    sudo docker start tile-a
    sudo docker stop tile-a

#### Cleanup tile generation container

    sudo docker rm gen

Building Container Images
-------------------------

    sudo docker build -t tile/ts:2.x server
    sudo docker build -t tile/tg:2.x gen
