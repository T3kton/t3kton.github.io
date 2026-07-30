#!/bin/sh

set -e
set -x

mkdir -p /var/www/static

if [ "x$UPSTREAM_PROXY" != "x" ]
then
  proxy="  NoProxy static static.site1.test
  NoProxy contractor contractor.site1.test

  ProxyRemote * $UPSTREAM_PROXY"
fi

cat > /etc/apache2/sites-available/proxy.conf << PROXY_EOF
Listen 3128
<VirtualHost *:3128>
  ServerName proxy
  ServerAlias proxy.*

  DocumentRoot /var/www/static

  LogFormat "%h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-agent}i\" \"%{cache-status}e\"" proxy_log
  ErrorLog \${APACHE_LOG_DIR}/proxy_error.log
  CustomLog \${APACHE_LOG_DIR}/proxy_access.log proxy_log

  ProxyRequests On
  ProxyVia Full

  SetEnvIf Remote_Addr "(.*)" client_ip=$1
  RequestHeader add X-Forwarded-For "%{client_ip}e"

  CacheEnable disk http://
  CacheEnable disk https://

  CacheMaxFileSize 1000000000
  CachReadSize 102400

  CacheDisable http://static
  CacheDisable http://static.site1.test
  CacheDisable http://contractor
  CacheDisable http://contractor.site1.test

$proxy
</VirtualHost>
PROXY_EOF

cat >> /etc/apache2/mods-enabled/cache_disk.conf << CACHE_DISK_EOF

CacheMaxFileSize 5000000000
CacheDefaultExpire 1000000

CACHE_DISK_EOF


cat > /etc/apache2/sites-available/static.conf << STATIC_EOF
<VirtualHost *:80>
  ServerName static
  ServerAlias static.*

  DocumentRoot /var/www/static

  LogFormat "%a %t %D \"%r\" %>s %I %O \"%{Referer}i\" \"%{User-Agent}i\" %X" static_log
  ErrorLog \${APACHE_LOG_DIR}/static_error.log
  CustomLog \${APACHE_LOG_DIR}/static_access.log static_log
</VirtualHost>
STATIC_EOF

a2ensite proxy
a2ensite static
a2dissite 000-default
a2enmod proxy proxy_connect proxy_ftp proxy_http cache_disk cache headers
systemctl restart apache2
systemctl start apache-htcacheclean

sed s/HTCACHECLEAN_SIZE=300M/HTCACHECLEAN_SIZE=5G/ -i /etc/default/apache-htcacheclean
