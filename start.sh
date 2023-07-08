#!/bin/bash

shib-keygen -h ${DOMAIN_JAGGER}
openssl req -x509 -nodes -days 1095 -newkey rsa:2048 -out /opt/md-signer/metadata-signer.crt -keyout /opt/md-signer/metadata-signer.key -subj "/CN=${DOMAIN_JAGGER}"

sed -i "s|DOMAIN_JAGGER_ENV|${DOMAIN_JAGGER}|g; \
    s|DOMAIN_IDP_ENV|${DOMAIN_IDP}|g" /etc/shibboleth/shibboleth2.xml
sed -i "17s|''|'https://${DOMAIN_JAGGER}'|g; \
	205s|'Y-m-d H:i:s'|''|g" /opt/rr3/application/config/config.php
sed -i "7s|FALSE|TRUE|g; \
	77s|eppn|uid|g; \
	186s|rabbitmq|gearman|g; \
	192s|FALSE|TRUE|g" /opt/rr3/application/config/config_rr.php
echo '$config["signdigest"] = "SHA-256";' >> /opt/rr3/application/config/config_rr.php
sed -i "s|CHANGEME|rr3|g" /opt/rr3/application/config/database.php
sed -i "s|DOMAIN_JAGGER_ENV|${DOMAIN_JAGGER}|g" /etc/apache2/sites-available/default-ssl.conf

/etc/init.d/shibd start
/etc/init.d/apache2 start
/etc/init.d/mysql start
/etc/init.d/gearman-job-server start
/etc/init.d/gearman-workers start

mysql -u root -e "create database rr3 CHARACTER SET utf8 COLLATE utf8_general_ci"
mysql -u root -e "create user rr3@localhost identified by 'rr3'"
mysql -u root -e "grant all on rr3.* to rr3@localhost"
mysql -u root -e "flush privileges"
/opt/rr3/application/doctrine orm:schema-tool:create

touch /opt/rr3/application/logs/log-federasi.php

echo 'Ready to serve...'
tail -f /var/log/shibboleth/shibd.log -f /opt/rr3/application/logs/log-federasi.php