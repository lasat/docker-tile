FROM ubuntu:16.04

RUN echo 'deb http://ppa.launchpad.net/ubuntugis/ppa/ubuntu trusty main' >> /etc/apt/sources.list.d/ubuntugis-ppa-trusty.list && \
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 314DF160 && \
    apt-get update && apt-get install -y tilestache

RUN mkdir -p /export/geo
COPY tilestache.json /etc/tilestache.cfg

RUN apt-get update && apt-get install -y apache2 libapache2-mod-wsgi && rm -f /var/www/html/index.html
COPY tiles.conf /etc/apache2/sites-available/tiles.conf
RUN \
	a2dismod -f autoindex && \
	a2dismod -f negotiation && \
	a2dissite 000-default && \
	a2ensite tiles

COPY tilestache.wsgi /var/www/
RUN apt-get update && apt-get install -y wget && \
	mkdir -p /var/www/html/javascript/modestmaps && \
	wget -P /var/www/html/javascript/modestmaps https://raw.github.com/modestmaps/modestmaps-js/master/modestmaps.min.js

VOLUME /export/tile

EXPOSE 80
CMD ["/usr/sbin/apache2ctl", "-D", "FOREGROUND"]
