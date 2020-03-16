Installing
----------

Create an Ubuntu Xenial(16.04LTS) VM, name it `contractor`, set the fqdn to `contractor.site1.test`
Ideally it should be in a /24 network.  Offset 1 is assumed to be the gateway.
All these values can be adjusted either in the setupWizard file before it is run,
or after it is setup, you can use the API to edit these values.
The DNS server will be set for the contractor VM, and bind on the contractor vm will
be set to forward to the DNS server that was originally configured on the VM.

From Source
~~~~~~~~~~~

:doc:`source`


From Packages
~~~~~~~~~~~~~

:doc:`packaged`

Setup
-----

Set up Infrastructure
~~~~~~~~~~~~~~~~~~~~~

To prevent your new contractor VM from taking over the network you are curently
connected to, you will need to configure a issloated network.  There are also
some other Infrastructure related tasks that need to be done.

:doc:`setup_vcenter`

:doc:`setup_virtualbox`

:doc:`setup_ipmi`

:doc:`setup_amt`

:doc:`setup_docker`

the ubuntu toml package is to old, update with::

  apt install -y python3-pip
  pip3 install toml --upgrade

Create Database
~~~~~~~~~~~~~~~

.. raw:: html

    <div style="position: relative; padding-bottom: 56.25%; height: 0; overflow: hidden; max-width: 100%; height: auto;">
        <iframe src="https://www.youtube.com/embed/Wjm6kKus1Ho" frameborder="0" allowfullscreen style="position: absolute; top: 0; left: 0; width: 100%; height: 100%;"></iframe>
    </div>

Install Postgres::

  sudo apt install -y postgresql-client postgresql-10 mongodb-server

Create the postgres db::

  sudo su postgres -c "echo \"CREATE ROLE contractor WITH PASSWORD 'contractor' NOSUPERUSER NOCREATEDB NOCREATEROLE LOGIN;\" | psql"
  sudo su postgres -c "createdb -O contractor contractor"

NOTE, for those two commands you may see something like::

  could not change directory to "/root": Permission denied

this is from the `su` command, thoes messages can be ignored

Configure Apache
~~~~~~~~~~~~~~~~

We will need a HTTP site to serve up static resources, as well as a Proxy server
to bridge from the isolated network.  This proxy server will also cache. We are
using Apache to Proxy with for this example, however you can use any proxy you
would like, just update the `proxy-server` paramater to the `setupWizard` call.

First create the directory for the static resources::

    sudo mkdir -p /var/www/static

now create the proxy site `/etc/apache2/sites-available/proxy.conf` with the following::

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

    # ProxyRemote * http://<up stream proxy>:3128/
  </VirtualHost>

NOTE: if you need to relay through an upstream proxy to have access to the ubuntu
and centos mirrors, enable the `ProxyRemote` line and update it with the upstream proxy.
Now create the static site `/etc/apache2/sites-available/static.conf` with the following::

  <VirtualHost *:80>
    ServerName static
    ServerAlias static.site1.test

    DocumentRoot /var/www/static

    LogFormat "%a %t %D \"%r\" %>s %I %O \"%{Referer}i\" \"%{User-Agent}i\" %X" static_log
    ErrorLog ${APACHE_LOG_DIR}/static_error.log
    CustomLog ${APACHE_LOG_DIR}/static_access.log static_log
  </VirtualHost>

Modify `/etc/apache2/sites-available/contractor.conf` and enable the ServerAlias
line, and change the `<domain>` to `site1.test`

Now enable the proxy and static site, disable the default site, and reload the
apache configuration::

  sudo a2ensite proxy
  sudo a2ensite static
  sudo a2dissite 000-default
  sudo a2enmod proxy proxy_connect proxy_ftp proxy_http cache_disk cache
  sudo systemctl restart apache2
  sudo systemctl start apache-htcacheclean

Setup the database
~~~~~~~~~~~~~~~~~~

Now to create the db::

  /usr/lib/contractor/util/manage.py migrate

Install the iputils functions, this contains the port check function contractor
will use to verify the OS has booted::

  sudo respkg -i contractor-plugins-iputils_*.respkg

Install base os config::

  sudo respkg -i contractor-os-base_*.respkg

If you are going to use IPMI or AMT, Install the disks package, this has the bootstrap,
set-rtc, and disk-wipe PXE images::

  sudo respkg -i disks-contractor_*.respkg

Now to enable plugins.
We use manual for misc stuff that is either pre-configured or handled by something else::

  sudo respkg -i contractor-plugins-manual_*.respkg

if you are using ESX/VCenter::

  sudo respkg -i contractor-plugins-vcenter_*.respkg

if you are using Virtualbox::

  sudo respkg -i contractor-plugins-virtualbox_*.respkg

if you are using IPMI::

  sudo respkg -i contractor-plugins-ipmi_*.respkg

if you are using AMT::

  sudo respkg -i contractor-plugins-amt_*.respkg

if you are using Docker::

  sudo respkg -i contractor-plugins-docker_*.respkg

restart apache so it loads the newly enabled plutings::

  sudo systemctl restart apache2

Now to configure the base contractor information, this includes configuring bind.
This command will prompt you for the password to use for the `root` user that we
will be using for API calls.  Set `< interface name >` to the name of the interface
on the internal network::

  sudo /usr/lib/contractor/setup/setupWizard --no-ip-reservation --dns-server=10.0.0.10 --proxy-server=http://10.0.0.10:3128/ --ntp-server=contractor --primary-interface=< interface name >

It is safe to ignore the message::

  rndc: connect failed: 127.0.0.1#953: connection refused
  WARNING: "rndc reload" failed

Bind (the DNS server) is not running yet, it will be started later.

Environment Setup
~~~~~~~~~~~~~~~~~

.. raw:: html

    <div style="position: relative; padding-bottom: 56.25%; height: 0; overflow: hidden; max-width: 100%; height: auto;">
        <iframe src="https://www.youtube.com/embed/TIEt0UWRrpk" frameborder="0" allowfullscreen style="position: absolute; top: 0; left: 0; width: 100%; height: 100%;"></iframe>
    </div>

We will be using the HTTP API to inject new stuff into contractor.
You can run these commands from either the contractor VM, or any place that can make
http requests to contractor.

we will be using curl, make sure it is installed::

  sudo apt install -y curl

First we will define some Environment values so we don't have to keep tying redundant info
the Contractor server.  This is assuming you will be running these commands from
the contractor VM, if you are running these steps from someplace else, update the
ip address to the ip address of the contractor vm::

  export COPS=( --noproxy \* --header "CInP-Version: 0.9" --header "Content-Type: application/json" )
  export SITE="/api/v1/Site/Site:site1:"
  export CHOST="http://127.0.0.1"

COPS is defining some curl options. SITE defines the uri of the site we are going
to use, and CHOST is the URL to the Contractor server.

now we need to login, replace the `< password >` with the password you passed to
`setupWizard` (the `--root-password` paramater)::

  echo '{ "username": "root", "password": "< password >" }' | curl "${COPS[@]}" --data @- -X CALL $CHOST/api/v1/Auth/User\(login\)

which will output something like::

  "k4of9zewijvze0gf72ylb6p6zxv4srol"

which will return a auth token, save that to our headers, replace `< username >`
with the API username, and `< auth token >` with the result of the last command::

  COPS+=( --header "Auth-Id: root")
  COPS+=( --header "Auth-Token: < auth token >" )

This is adding more headers to our curl options, from here on our curl operations
are authenticated.  Let's make sure our login is working::

  echo '{}' | curl "${COPS[@]}" --data @- -X CALL $CHOST/api/v1/Auth/User\(whoami\)

that should output your username, for example::

  "root"

HTTP Requests Note
~~~~~~~~~~~~~~~~~~

As you may of noticed from the Authentication requests, each request has some JSON
encoded request data, as well as a JSON encoded response.  Contractor uses a REST like
HTTP-JSON library called CInP, which can be found at https://github.com/cinp/.
CInP is the reason for the `CInP-Version: 0.9` HTTP Header.  Going forward most
requests are going to use the heredoc method for passing the request body to
curl.  If you are not familure with this method, keep in mind that for requests
the require modification (ie: the have <something> in them), don't copy paste
everything at once, generally it works to copy paste everything but the last `EOF`
then back arrow, fix what ever values you need to fix, go to the end, hit <enter>
then type in the closing `EOF`.  The requests that don't need modification, you can
copy paste all at once.

Some requests create objects, when `-X CREATE` is used with curl, the id of the
created object is found in the header `Object-Id`, for example::

  HTTP/1.1 201 CREATED
  Date: Thu, 23 May 2019 23:42:17 GMT
  Server: Apache/2.4.18 (Ubuntu)
  Verb: CREATE
  Access-Control-Allow-Origin: *
  Cinp-Version: 0.9
  Access-Control-Expose-Headers: Method, Type, Cinp-Version, Count, Position, Total, Multi-Object, Object-Id, Id-Only
  Cache-Control: no-cache
  Object-Id: /api/v1/Utilities/AddressBlock:2:
  Content-Length: 318
  Content-Type: application/json;charset=utf-8

  {"name": "internal", "size": "254", "_max_address": "10.0.0.255", "gateway_offset": null, "updated": "2019-05-23T23:42:17.180084+00:00", "site": "/api/v1/Site/Site:site1:", "netmask": "255.255.255.0", "subnet": "10.0.0.0", "created": "2019-05-23T23:42:17.180121+00:00", "gateway": null, "isIpV4": "True", "prefix": 24}

The url of that newly created AddressBlock is `/api/v1/Utilities/AddressBlock:2:`,
generally we are only concerned with the id which is between the `:` in this case
the id is `2`.  We will point out when you need to take note of id of a created object.

For the most part when we display the output of a request, we are not going to show
the headers, just the response body.

Network Configuration
~~~~~~~~~~~~~~~~~~~~~

.. raw:: html

    <div style="position: relative; padding-bottom: 56.25%; height: 0; overflow: hidden; max-width: 100%; height: auto;">
        <iframe src="https://www.youtube.com/embed/hdY97j2u4rc" frameborder="0" allowfullscreen style="position: absolute; top: 0; left: 0; width: 100%; height: 100%;"></iframe>
    </div>

The setupWizard has pre-loaded the database with a stand in host to represent
the contractor VM and has flagged it as pre-built.  It has also created
a site called `site1` and some base DNS configuration. It also took the network
of the primary interface and loaded it into the database as the Network `main`,
and AddressBlock name `main`.

First we need to set an Environment variable for the existing AddressBlock::

  export ADRBLK="/api/v1/Utilities/AddressBlock:1:"

Now to create network for the internal network.  Contractor will use the name of the Network
to know what virtual network to select when deploying VMs.  Replace `< network name >` with
the name of the network created in vcenter (ie: internal) or virtual box (ie: vboxnet0), for
IPMI and AMT, use 'internal'::

  cat << EOF | curl -i "${COPS[@]}" --data @- -X CREATE $CHOST/api/v1/Utilities/Network
  { "site": "$SITE", "name": "< network name >" }
  EOF

result::

  {"name": "vboxnet0", "address_block_list": [], "site": "/api/v1/Site/Site:site1:", "created": "2019-10-24T17:55:09.024672+00:00", "updated": "2019-10-24T17:55:09.024647+00:00"}

Take note of the id of that created AddressBlock.  Set another environment variable
to the Id value, replace the `< id >` to the id of the above id::

  export NETWORK="/api/v1/Utilities/Network:< id >:"

Now to attach the AddressBlock to the Network::

  cat << EOF | curl -i "${COPS[@]}" --data @- -X CREATE $CHOST/api/v1/Utilities/NetworkAddressBlock
  { "network": "$NETWORK", "address_block": "$ADRBLK" }
  EOF

result::

  {"network": "/api/v1/Utilities/Network:2:", "vlan": 0, "vlan_tagged": false, "address_block": "/api/v1/Utilities/AddressBlock:2:", "updated": "2019-10-24T17:58:54.146006+00:00", "created": "2019-10-24T17:58:54.146044+00:00"}

now to reserve some ip addresses so they do not get auto assigned::

  for OFFSET in 2 3 4 5 6 7 8 9 11 12 13 14 15 16 17 18 19 20; do
  cat << EOF | curl "${COPS[@]}" --data @- -X CREATE $CHOST/api/v1/Utilities/ReservedAddress
  { "address_block": "$ADRBLK", "offset": "$OFFSET", "reason": "Network Reserved" }
  EOF
  done

result::

{"address_block": "/api/v1/Utilities/AddressBlock:1:", "offset": 2, "updated": "2019-11-05T02:58:26.350596+00:00", "created": "2019-11-05T02:58:26.350625+00:00", "reason": "Network Reserved", "type": "ReservedAddress", "ip_address": "10.0.0.2", "subnet": "10.0.0.0", "netmask": "255.255.255.0", "prefix": "24", "gateway": null}
{"address_block": "/api/v1/Utilities/AddressBlock:1:", "offset": 3, "updated": "2019-11-05T02:58:26.384282+00:00", "created": "2019-11-05T02:58:26.384306+00:00", "reason": "Network Reserved", "type": "ReservedAddress", "ip_address": "10.0.0.3", "subnet": "10.0.0.0", "netmask": "255.255.255.0", "prefix": "24", "gateway": null}
{"address_block": "/api/v1/Utilities/AddressBlock:1:", "offset": 4, "updated": "2019-11-05T02:58:26.420326+00:00", "created": "2019-11-05T02:58:26.420348+00:00", "reason": "Network Reserved", "type": "ReservedAddress", "ip_address": "10.0.0.4", "subnet": "10.0.0.0", "netmask": "255.255.255.0", "prefix": "24", "gateway": null}
{"address_block": "/api/v1/Utilities/AddressBlock:1:", "offset": 5, "updated": "2019-11-05T02:58:26.445826+00:00", "created": "2019-11-05T02:58:26.445852+00:00", "reason": "Network Reserved", "type": "ReservedAddress", "ip_address": "10.0.0.5", "subnet": "10.0.0.0", "netmask": "255.255.255.0", "prefix": "24", "gateway": null}
{"address_block": "/api/v1/Utilities/AddressBlock:1:", "offset": 6, "updated": "2019-11-05T02:58:26.471761+00:00", "created": "2019-11-05T02:58:26.471781+00:00", "reason": "Network Reserved", "type": "ReservedAddress", "ip_address": "10.0.0.6", "subnet": "10.0.0.0", "netmask": "255.255.255.0", "prefix": "24", "gateway": null}
{"address_block": "/api/v1/Utilities/AddressBlock:1:", "offset": 7, "updated": "2019-11-05T02:58:26.496654+00:00", "created": "2019-11-05T02:58:26.496676+00:00", "reason": "Network Reserved", "type": "ReservedAddress", "ip_address": "10.0.0.7", "subnet": "10.0.0.0", "netmask": "255.255.255.0", "prefix": "24", "gateway": null}
{"address_block": "/api/v1/Utilities/AddressBlock:1:", "offset": 8, "updated": "2019-11-05T02:58:26.524865+00:00", "created": "2019-11-05T02:58:26.524899+00:00", "reason": "Network Reserved", "type": "ReservedAddress", "ip_address": "10.0.0.8", "subnet": "10.0.0.0", "netmask": "255.255.255.0", "prefix": "24", "gateway": null}
{"address_block": "/api/v1/Utilities/AddressBlock:1:", "offset": 9, "updated": "2019-11-05T02:58:26.552813+00:00", "created": "2019-11-05T02:58:26.552836+00:00", "reason": "Network Reserved", "type": "ReservedAddress", "ip_address": "10.0.0.9", "subnet": "10.0.0.0", "netmask": "255.255.255.0", "prefix": "24", "gateway": null}
{"address_block": "/api/v1/Utilities/AddressBlock:1:", "offset": 11, "updated": "2019-11-05T02:58:26.579828+00:00", "created": "2019-11-05T02:58:26.579867+00:00", "reason": "Network Reserved", "type": "ReservedAddress", "ip_address": "10.0.0.11", "subnet": "10.0.0.0", "netmask": "255.255.255.0", "prefix": "24", "gateway": null}
{"address_block": "/api/v1/Utilities/AddressBlock:1:", "offset": 12, "updated": "2019-11-05T02:58:26.607718+00:00", "created": "2019-11-05T02:58:26.607740+00:00", "reason": "Network Reserved", "type": "ReservedAddress", "ip_address": "10.0.0.12", "subnet": "10.0.0.0", "netmask": "255.255.255.0", "prefix": "24", "gateway": null}
{"address_block": "/api/v1/Utilities/AddressBlock:1:", "offset": 13, "updated": "2019-11-05T02:58:26.636675+00:00", "created": "2019-11-05T02:58:26.636697+00:00", "reason": "Network Reserved", "type": "ReservedAddress", "ip_address": "10.0.0.13", "subnet": "10.0.0.0", "netmask": "255.255.255.0", "prefix": "24", "gateway": null}
{"address_block": "/api/v1/Utilities/AddressBlock:1:", "offset": 14, "updated": "2019-11-05T02:58:26.662100+00:00", "created": "2019-11-05T02:58:26.662127+00:00", "reason": "Network Reserved", "type": "ReservedAddress", "ip_address": "10.0.0.14", "subnet": "10.0.0.0", "netmask": "255.255.255.0", "prefix": "24", "gateway": null}
{"address_block": "/api/v1/Utilities/AddressBlock:1:", "offset": 15, "updated": "2019-11-05T02:58:26.688283+00:00", "created": "2019-11-05T02:58:26.688311+00:00", "reason": "Network Reserved", "type": "ReservedAddress", "ip_address": "10.0.0.15", "subnet": "10.0.0.0", "netmask": "255.255.255.0", "prefix": "24", "gateway": null}
{"address_block": "/api/v1/Utilities/AddressBlock:1:", "offset": 16, "updated": "2019-11-05T02:58:26.715900+00:00", "created": "2019-11-05T02:58:26.715922+00:00", "reason": "Network Reserved", "type": "ReservedAddress", "ip_address": "10.0.0.16", "subnet": "10.0.0.0", "netmask": "255.255.255.0", "prefix": "24", "gateway": null}
{"address_block": "/api/v1/Utilities/AddressBlock:1:", "offset": 17, "updated": "2019-11-05T02:58:26.745761+00:00", "created": "2019-11-05T02:58:26.745797+00:00", "reason": "Network Reserved", "type": "ReservedAddress", "ip_address": "10.0.0.17", "subnet": "10.0.0.0", "netmask": "255.255.255.0", "prefix": "24", "gateway": null}
{"address_block": "/api/v1/Utilities/AddressBlock:1:", "offset": 18, "updated": "2019-11-05T02:58:26.772841+00:00", "created": "2019-11-05T02:58:26.772863+00:00", "reason": "Network Reserved", "type": "ReservedAddress", "ip_address": "10.0.0.18", "subnet": "10.0.0.0", "netmask": "255.255.255.0", "prefix": "24", "gateway": null}
{"address_block": "/api/v1/Utilities/AddressBlock:1:", "offset": 19, "updated": "2019-11-05T02:58:26.800554+00:00", "created": "2019-11-05T02:58:26.800588+00:00", "reason": "Network Reserved", "type": "ReservedAddress", "ip_address": "10.0.0.19", "subnet": "10.0.0.0", "netmask": "255.255.255.0", "prefix": "24", "gateway": null}
{"address_block": "/api/v1/Utilities/AddressBlock:1:", "offset": 20, "updated": "2019-11-05T02:58:26.827612+00:00", "created": "2019-11-05T02:58:26.827637+00:00", "reason": "Network Reserved", "type": "ReservedAddress", "ip_address": "10.0.0.20", "subnet": "10.0.0.0", "netmask": "255.255.255.0", "prefix": "24", "gateway": null}

If you are installing to AMT/IPMI you will need some dynamic Ips for devices we
do not yet have MAC addresses for, we are going to set these to PXE boot to the
bootstrap image, if you are not going to to AMT/IPMI, skip this step, you probably
do not have the bootstrap PXE image loaded::

  for OFFSET in 21 22 23 24 25; do
  cat << EOF | curl "${COPS[@]}" --data @- -X CREATE $CHOST/api/v1/Utilities/DynamicAddress
  { "address_block": "$ADRBLK", "offset": "$OFFSET", "pxe": "/api/v1/BluePrint/PXE:bootstrap:" }
  EOF
  done

result::

  {"address_block": "/api/v1/Utilities/AddressBlock:1:", "offset": 21, "updated": "2019-11-05T02:58:45.380257+00:00", "created": "2019-11-05T02:58:45.380307+00:00", "pxe": "/api/v1/BluePrint/PXE:bootstrap:", "type": "DynamicAddress", "ip_address": "10.0.0.21", "subnet": "10.0.0.0", "netmask": "255.255.255.0", "prefix": "24", "gateway": null}
  {"address_block": "/api/v1/Utilities/AddressBlock:1:", "offset": 22, "updated": "2019-11-05T02:58:45.415840+00:00", "created": "2019-11-05T02:58:45.415876+00:00", "pxe": "/api/v1/BluePrint/PXE:bootstrap:", "type": "DynamicAddress", "ip_address": "10.0.0.22", "subnet": "10.0.0.0", "netmask": "255.255.255.0", "prefix": "24", "gateway": null}
  {"address_block": "/api/v1/Utilities/AddressBlock:1:", "offset": 23, "updated": "2019-11-05T02:58:45.448887+00:00", "created": "2019-11-05T02:58:45.448930+00:00", "pxe": "/api/v1/BluePrint/PXE:bootstrap:", "type": "DynamicAddress", "ip_address": "10.0.0.23", "subnet": "10.0.0.0", "netmask": "255.255.255.0", "prefix": "24", "gateway": null}
  {"address_block": "/api/v1/Utilities/AddressBlock:1:", "offset": 24, "updated": "2019-11-05T02:58:45.475547+00:00", "created": "2019-11-05T02:58:45.475569+00:00", "pxe": "/api/v1/BluePrint/PXE:bootstrap:", "type": "DynamicAddress", "ip_address": "10.0.0.24", "subnet": "10.0.0.0", "netmask": "255.255.255.0", "prefix": "24", "gateway": null}
  {"address_block": "/api/v1/Utilities/AddressBlock:1:", "offset": 25, "updated": "2019-11-05T02:58:45.501742+00:00", "created": "2019-11-05T02:58:45.501762+00:00", "pxe": "/api/v1/BluePrint/PXE:bootstrap:", "type": "DynamicAddress", "ip_address": "10.0.0.25", "subnet": "10.0.0.0", "netmask": "255.255.255.0", "prefix": "24", "gateway": null}

Starting DNS
~~~~~~~~~~~~

Restart bind with new zones::

  sudo systemctl restart bind9

Now to force a re-gen of the DNS files::

  sudo /usr/lib/contractor/cron/genDNS

This VM needs to use the contractor generated dns, so edit the file in /etc/netplan/
to set the dns server to "127.0.0.1", and set the dns search to "site1.test site1".
For example::

  network:
    ...
    enp0s3:
      ...
      nameservers:
        search: [site1.test test]
        addresses: [127.0.0.1]

then apply the networking configuration::

  sudo netplan apply

now let's see if the network and bind settings are working properly::

  host static

results::

  static.site1.test is an alias for contractor.site1.test.
  contractor.site1.test has address <contractor ip>
  contractor.site1.test is an alias for enp0s8.contractor.site1.test.

The "search" value from netplan file is used to convert "static" to
"static.site1.test".  The first line resolving the alias is from the bind file
that contractor just generated. The second line is systemd-resolved reading your
/etc/hosts file to resolve contractor.site1.test. The third line is from bind as
well.

NOTE: if you were to::

  dig @127.0.0.1 +short static.site1.test

you would get::

  contractor.site1.test.
  enp0s8.contractor.site1.test.
  10.0.0.10

which results in a different ip address, this is the result from external hosts
resolving against bind.  In this case systemd-resolved is not consulted, and the
value in your /etc/hosts file is not used.  If you would like the same result
externally and internally, you can either cut systemd-resolvd out of the loop internally
or edit your /etc/hosts file and change the ip address(<contractor ip>) to the ip
of the internal interface(10.0.0.10).

now take a look at the contractor ui at http://<contractor ip>, (this ip is the ip
you assigned to the first interface)

Subcontractor
~~~~~~~~~~~~~

.. raw:: html

    <div style="position: relative; padding-bottom: 56.25%; height: 0; overflow: hidden; max-width: 100%; height: auto;">
        <iframe src="https://www.youtube.com/embed/O_fCrUK3mvs" frameborder="0" allowfullscreen style="position: absolute; top: 0; left: 0; width: 100%; height: 100%;"></iframe>
    </div>

install tfptd (used for PXE booting) and the PXE booting agent::

  sudo apt install -y tftpd-hpa
  sudo respkg -i contractor-ipxe_*.respkg

now edit `/etc/subcontractor.conf`
enable the modules you want to use, remove the ';' and set the 0 to a 1.
The 1 means one task for that plugin at a time.  If you want to be able to process
more targets at the same time, you can try 2 or 4 depending on the plugin, the
resources of your vm, etc.  You may also want to change the `poll_interval` to 5, this
will cause subcontractor to ask for more tasks every 5 seconds instead of the default
20.  If we were setting up a system that would be processing a lot of tasks, we would
want to slow this down to reduce the overhead on contractor. In the dhcpd section,
make sure `listen_interface` and `tftp_server` are correct, `tftp_server` should be the ip of
the vm on the new internal interface.

now start up subcontractor::

  sudo systemctl start subcontractor
  sudo systemctl start dhcpd

make sure they are running::

  sudo systemctl status subcontractor
  sudo systemctl status dhcpd

optional, edit `/etc/default/tftpd-hpa` and add '-v ' to TFTP_OPTIONS.  This will
cause tfptd to log transfers to syslog.  This can be helpful in troubleshooting
boot problems. Make sure to run `systemctl restart tftpd-hpa` to reload.

Next Steps
~~~~~~~~~~

If you are installing to VCenter or VirtualBox:
:doc:`complex`

If you are installing on a BareMetal/IPMI machine:
:doc:`install_baremetal`
