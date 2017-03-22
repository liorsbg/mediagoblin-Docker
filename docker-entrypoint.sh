#!/bin/bash

nginx
chown -hR mediagoblin:www-data /var/lib/mediagoblin
cd /srv/mediagoblin.example.org/mediagoblin/
bin/gmg dbupdate
bin/gmg adduser --username admin --password CoNi4NGERsUbUMmUGHt
bin/gmg makeadmin admin

# ./lazyserver.sh --server-name=fcgi fcgi_host=127.0.0.1 fcgi_port=26543

CELERY_ALWAYS_EAGER=false \
 /srv/mediagoblin.example.org/mediagoblin/bin/paster serve \
 /srv/mediagoblin.example.org/mediagoblin/paste.ini \
 --pid-file=/var/run/mediagoblin.pid \
 --server-name=fcgi fcgi_host=127.0.0.1 fcgi_port=26543
