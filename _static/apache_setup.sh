#!/bin/sh

set -e
set -x

mkdir -p /var/www/static

if [ "x$UPSTREAM_PROXY" != "x" ]
then
  proxy="ProxyRemote * $UPSTREAM_PROXY"
fi

cat > /etc/apache2/sites-available/proxy.conf << PROXY_EOF
Listen 3128
<VirtualHost *:3128>
  ServerName proxy
  ServerAlias proxy.site1.test

  DocumentRoot /var/www/static

  ErrorLog ${APACHE_LOG_DIR}/proxy_error.log
  CustomLog ${APACHE_LOG_DIR}/proxy_access.log combined

  ProxyRequests On
  ProxyVia Full

  CacheEnable disk http://
  CacheEnable disk https://

  NoProxy static static.site1.test
  NoProxy contractor contractor.site1.test

  $proxy
</VirtualHost>
PROXY_EOF

cat > /etc/apache2/sites-available/static.conf << STATIC_EOF
<VirtualHost *:80>
  ServerName static
  ServerAlias static.site1.test

  DocumentRoot /var/www/static

  LogFormat "%a %t %D \"%r\" %>s %I %O \"%{Referer}i\" \"%{User-Agent}i\" %X" static_log
  ErrorLog ${APACHE_LOG_DIR}/static_error.log
  CustomLog ${APACHE_LOG_DIR}/static_access.log static_log
</VirtualHost>
STATIC_EOF

sed 's/#  ServerAlias contractor.<domain>/  ServerAlias contractor.site1.test/' -i /etc/apache2/sites-available/contractor.conf

a2ensite proxy
a2ensite static
a2dissite 000-default
a2enmod proxy proxy_connect proxy_ftp proxy_http cache_disk cache
systemctl restart apache2
systemctl start apache-htcacheclean
