FROM debian:wheezy
MAINTAINER Benjamin Chodoroff <bc@thermitic.net>

RUN apt-get update
RUN apt-get -y install wget
RUN wget -O - "http://nginx.org/keys/nginx_signing.key" | apt-key add -
RUN wget -O - "http://www.dotdeb.org/dotdeb.gpg" | apt-key add -

# Ensure UTF-8
RUN apt-get -y install locales
RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
RUN locale-gen
ENV LANG en_US.UTF-8
ENV LC_ALL en_US.UTF-8

RUN echo "deb http://nginx.org/packages/debian/ wheezy nginx" >> /etc/apt/sources.list.d/nginx.list
RUN echo "deb http://packages.dotdeb.org wheezy all\ndeb-src http://packages.dotdeb.org wheezy all\ndeb http://packages.dotdeb.org wheezy-php55 all\ndeb-src http://packages.dotdeb.org wheezy-php55 all" >> /etc/apt/sources.list.d/dotdeb.list

RUN apt-get update
RUN apt-get -y install openssh-server supervisor nginx openssl ca-certificates php5-fpm php5-cli php5-curl php5-mcrypt php5-gd php5-common php5-mysql php5-xmlrpc php5-xsl php5-dev php-pear mysql-client curl git
RUN pear channel-discover pear.drush.org && pear install drush/drush

# openssh
RUN mkdir /var/run/sshd

# supervisor
RUN mkdir -p /var/log/supervisor
ADD thermitic/etc/supervisor/conf.d/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# nginx
RUN rm -rf /etc/nginx/conf.d/*
RUN rm -rf /srv/www/*
RUN mkdir -p /var/lib/nginx/speed
RUN mkdir -p /var/lib/nginx/body
RUN mkdir -p /etc/nginx/includes
RUN mkdir -p /etc/nginx/conf.d
ADD thermitic/etc/nginx/nginx.conf /etc/nginx/nginx.conf
ADD thermitic/etc/nginx/includes/fastcgi_params.conf /etc/nginx/includes/fastcgi_params.conf
ADD thermitic/etc/nginx/includes/fastcgi_ssl_params.conf /etc/nginx/includes/fastcgi_ssl_params.conf
ADD thermitic/etc/nginx/includes/drupal.conf /etc/nginx/includes/drupal.conf
ADD thermitic/etc/nginx/conf.d/site.conf /etc/nginx/conf.d/site.conf

# www
RUN mkdir -p /srv/www/nginx-default
ADD thermitic/srv/www/nginx-default/index.html /srv/www/nginx-default/index.html
VOLUME ["/srv/www"]

# identities
RUN mkdir /root/.ssh
ADD thermitic/root/.ssh/authorized_keys /root/.ssh/authorized_keys
RUN chown -R root:root /root/.ssh
RUN chmod 700 /root/.ssh
RUN chmod 600 /root/.ssh
RUN sed -e 's/^PermitRootLogin.*$/PermitRootLogin without-password/g' /etc/ssh/sshd_config > /tmp/sshd_config && mv /tmp/sshd_config /etc/ssh/sshd_config

# app
#RUN wget -qO- https://raw.github.com/detroitledger/gnl_profile/docker/install.sh | sh


EXPOSE 22
EXPOSE 80
EXPOSE 443

CMD ["/usr/bin/supervisord", "-n"]