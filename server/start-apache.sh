#!/bin/sh
rm -f /var/run/apache2/apache2.pid 2>/dev/null
exec /usr/sbin/apache2ctl -D FOREGROUND "$@"
