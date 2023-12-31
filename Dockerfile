FROM ubuntu:20.04
LABEL MAINTAINER="Pandu BA <pandu.asmoro@uii.ac.id>"

ARG DEBIAN_FRONTEND=noninteractive

RUN sed -i 's|archive.ubuntu.com|repo.ugm.ac.id|g' /etc/apt/sources.list \
    && apt update \
	&& apt upgrade -y \
	&& apt install -y nano apache2 libapache2-mod-php mysql-server php php-cli php-curl php-mysql php-memcached php-bcmath php-mbstring php-apcu php-gearman php-dev gearman unzip wget git curl composer tzdata apt-utils openssl ca-certificates gnupg gnupg2 lsb-release libmcrypt-dev openjdk-8-jdk python2 libapache2-mod-shib shibboleth-sp-common shibboleth-sp-utils \
	&& curl https://bootstrap.pypa.io/pip/2.7/get-pip.py --output get-pip.py \
	&& python2 get-pip.py \
    && echo Asia/Jakarta > /etc/timezone \
    && ln -sf /usr/share/zoneinfo/Asia/Jakarta /etc/localtime \
	&& openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/apache2/apache2-selfsigned.key -out /etc/apache2/apache2-selfsigned.crt -subj "/C=ID/O=Federasi ID/CN=federasi.id" \
	&& yes "" | pecl install mcrypt \
	&& echo "extension=mcrypt.so" > /etc/php/7.4/mods-available/mcrypt.ini \
	&& phpenmod mcrypt \
	&& a2enmod rewrite unique_id ssl remoteip \
	&& wget -P /opt https://github.com/bcit-ci/CodeIgniter/archive/3.1.5.zip \
	&& unzip /opt/3.1.5.zip \
	&& mv /CodeIgniter-3.1.5/ /opt/codeigniter \
	&& git clone https://github.com/Edugate/Jagger /opt/rr3 \
	&& cp /opt/codeigniter/index.php /opt/rr3/ \
	&& cd /opt/rr3/application/ \
	&& composer install \
	&& pip install gearman \
    && cd /opt \
	&& mkdir /opt/md-signer \
	&& mkdir /opt/rr3/signedmetadata \
	&& git clone https://github.com/janul/rr3-addons.git /opt/rr3-addons/ \
	&& wget http://shibboleth.net/downloads/tools/xmlsectool/2.0.0/xmlsectool-2.0.0-bin.zip \
	&& unzip xmlsectool-2.0.0-bin.zip \
	&& rm -f xmlsectool-2.0.0-bin.zip \
	&& cd /etc/init.d/ \
	&& ln -s /opt/rr3-addons/gearman-workers/gearman-workers

COPY start.sh /root/
COPY default-ssl.conf /etc/apache2/sites-available/
COPY shibboleth2.xml /etc/shibboleth/
COPY gearman-workers /opt/rr3-addons/gearman-workers/gearman-workers
COPY gearman-worker-metasigner.py /opt/rr3-addons/gearman-workers/gearman-worker-metasigner.py
COPY gearman-job-server /etc/default/gearman-job-server
COPY index.php /opt/rr3/

RUN a2ensite default-ssl.conf \
	&& /opt/rr3/install.sh \
	&& mv /opt/rr3/application/config/config-default.php /opt/rr3/application/config/config.php \
	&& mv /opt/rr3/application/config/config_rr-default.php /opt/rr3/application/config/config_rr.php \
	&& mv /opt/rr3/application/config/database-default.php /opt/rr3/application/config/database.php \
	&& mv /opt/rr3/application/config/email-default.php /opt/rr3/application/config/email.php \
	&& chown -R www-data:www-data /opt/rr3 \
	&& chmod u+x /opt/rr3-addons/gearman-workers/gearman-workers \
	&& chmod a+x /root/start.sh

WORKDIR /opt/rr3
EXPOSE 443
ENTRYPOINT ["sh", "/root/start.sh"]