#
#    Dockerized http://mediagoblin.org/
#    Copyright (C) OzZ Yoshi ozzyoshi@txtsme.com
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU Affero General Public License as published
#    by the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU Affero General Public License for more details.
#
#    You should have received a copy of the GNU Affero General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
FROM debian:jessie
RUN apt-get update
RUN apt-get install -y sudo git-core
RUN apt-get install -y python python-dev python-lxml python-imaging python-virtualenv
RUN apt-get install -y npm nodejs-legacy automake
RUN apt-get install -y nginx

RUN useradd -c "GNU MediaGoblin system account" -d /var/lib/mediagoblin -m -r -g www-data mediagoblin
RUN groupadd mediagoblin && sudo usermod --append -G mediagoblin mediagoblin
RUN mkdir -p /var/log/mediagoblin && chown -hR mediagoblin:mediagoblin /var/log/mediagoblin
RUN mkdir -p /srv/mediagoblin.example.org && chown -hR mediagoblin:www-data /srv/mediagoblin.example.org

WORKDIR /srv/mediagoblin.example.org
RUN sudo -u mediagoblin git clone http://git.savannah.gnu.org/r/mediagoblin.git

WORKDIR /srv/mediagoblin.example.org/mediagoblin
RUN sudo -u mediagoblin git checkout stable
RUN sudo -u mediagoblin git submodule sync
RUN sudo -u mediagoblin git submodule update --force --init --recursive
RUN sudo -u mediagoblin ./bootstrap.sh
RUN sudo -u mediagoblin ./configure
RUN sudo -u mediagoblin make
RUN sudo -u mediagoblin bin/easy_install flup==1.0.3.dev-20110405
RUN sudo -u mediagoblin ln -s /var/lib/mediagoblin user_dev
RUN sudo -u mediagoblin bash -c 'cp -av mediagoblin.ini mediagoblin_local.ini && cp -av paste.ini paste_local.ini'
RUN sudo -u mediagoblin perl -pi -e 's|.*sql_engine = .*|sql_engine = sqlite:////var/lib/mediagoblin/mediagoblin.db|' mediagoblin_local.ini
#
# Video plugin
#
RUN apt-get install -y python-gi python3-gi \
    gstreamer1.0-tools \
    gir1.2-gstreamer-1.0 \
    gir1.2-gst-plugins-base-1.0 \
    gstreamer1.0-plugins-good \
    gstreamer1.0-plugins-ugly \
    gstreamer1.0-plugins-bad \
    gstreamer1.0-libav \
    python-gst-1.0
RUN echo '[[mediagoblin.media_types.video]]' | sudo -u mediagoblin tee -a mediagoblin_local.ini
#
# Audio plugin
#
RUN apt-get install -y python-gst-1.0 gstreamer1.0-plugins-base gstreamer1.0-plugins-bad gstreamer1.0-plugins-good gstreamer1.0-plugins-ugly gstreamer1.0-libav libsndfile1-dev libasound2-dev libgstreamer-plugins-base1.0-dev python-numpy python-scipy
RUN echo '[[mediagoblin.media_types.audio]]' | sudo -u mediagoblin tee -a mediagoblin_local.ini
RUN sudo -u mediagoblin bin/pip install scikits.audiolab
#
# PDF plugin
#
RUN apt-get install -y poppler-utils
RUN echo '[[mediagoblin.media_types.pdf]]' | sudo -u mediagoblin tee -a mediagoblin_local.ini
#
#
#
ADD docker-nginx.conf /etc/nginx/sites-enabled/nginx.conf
RUN rm /etc/nginx/sites-enabled/default
RUN echo 'ALL ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
EXPOSE 80
ADD docker-entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
