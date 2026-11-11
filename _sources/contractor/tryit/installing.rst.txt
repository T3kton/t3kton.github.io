.. highlight:: bash

Installing
----------

Create an Ubuntu Noble(24.04LTS) VM, name it `contractor`, set the fqdn to `contractor.site1.test`
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

we will be using curl to download a few files, make sure it is installed::

  sudo apt install -y curl

and :ref:`contractor/contractorcli:installing contractorcli`, the command line client we will use to talk to Contractor.
You can install it on the contractor VM, or on any machine that can reach it.

Set up Infrastructure
~~~~~~~~~~~~~~~~~~~~~

To prevent your new contractor VM from taking over the network you are curently
connected to, you will need to configure a issloated network.  There are also
some other Infrastructure related tasks that need to be done.

:doc:`setup_vcenter`

:doc:`setup_virtualbox`

:doc:`setup_proxmox`

:doc:`setup_ipmi`

:doc:`setup_amt`

:doc:`setup_docker`

the ubuntu toml package is to old, update with::

  sudo apt install -y python3-pip
  sudo pip3 install toml --upgrade

Create Database
~~~~~~~~~~~~~~~

.. raw:: html

    <div style="position: relative; padding-bottom: 56.25%; height: 0; overflow: hidden; max-width: 100%; height: auto;">
        <iframe src="https://www.youtube.com/embed/Wjm6kKus1Ho" frameborder="0" allowfullscreen style="position: absolute; top: 0; left: 0; width: 100%; height: 100%;"></iframe>
    </div>

Install Postgres::

  sudo apt install -y postgresql-client postgresql mongodb-server

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
would like, just update the `proxy-server` parameter to the `setupWizard` call.

There is a script that will the apache setup.  Download and make it executable::

  curl -o apache_setup.sh https://t3kton.github.io/_static/apache_setup.sh
  chmod +x apache_setup.sh

If you do NOT have an upstream proxy::

  sudo ./apache_setup.sh

If you do have an upstream proxy::

  UPSTREAM_PROXY=<upstream proxy, ie: http://myproxy:3128/> sudo ./apache_setup.sh

Setup the Database
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

if you are using Proxmox::

  sudo respkg -i contractor-plugins-proxmox_*.respkg

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

.. note:: The video shows the earlier version of these steps using curl. The steps below do the same thing with contractorcli.

We will be using contractorcli to inject new stuff into contractor.  If you have
not installed it yet, see :ref:`contractor/contractorcli:installing contractorcli`.
You can run these commands from either the contractor VM, or any place that can make
http requests to contractor.

contractorcli reads its connection information from `~/.contractorcli.ini`.  Create
it with the address of the contractor VM, and the password you passed to
`setupWizard` (the `--admin-password` parameter).  If you are running these commands
from someplace other than the contractor VM, use the ip address of the contractor
vm for the host::

  cat << EOF > ~/.contractorcli.ini
  [contractor]
  host: http://127.0.0.1
  username: root
  password: < password >
  EOF

Let's make sure the login is working::

  contractorcli contractor_version
  contractorcli site list

the second command should list the site `site1`, which the setupWizard created.

.. note:: Contractor's API is a REST like HTTP-JSON API called CInP, which can be found at https://github.com/cinp/.  contractorcli is a small client for it.  If you would like to see the raw requests, or use another language, see :doc:`other_languages`.

Most contractorcli commands take the id of the thing to work with as an argument, and
flags for the values.  Use `--help` on any command to see the flags, for example
`contractorcli foundation interface create --help`.  When a command creates something it
prints it out, take note of the `Id` where we point it out below.  Add `--json` to
get the output as JSON.

Network Configuration
~~~~~~~~~~~~~~~~~~~~~

.. raw:: html

    <div style="position: relative; padding-bottom: 56.25%; height: 0; overflow: hidden; max-width: 100%; height: auto;">
        <iframe src="https://www.youtube.com/embed/hdY97j2u4rc" frameborder="0" allowfullscreen style="position: absolute; top: 0; left: 0; width: 100%; height: 100%;"></iframe>
    </div>

.. note:: The video shows the earlier version of these steps using curl. The steps below do the same thing with contractorcli.

The setupWizard has pre-loaded the database with a stand in host to represent
the contractor VM and has flagged it as pre-built.  It has also created
a site called `site1` and some base DNS configuration. It also took the network
of the primary interface and loaded it into the database as the Network `main`,
and AddressBlock name `main`.

Take a look at the existing AddressBlock, the Id of `main` will be used below, it is
normally `1`::

  contractorcli addressblock list

Now to create network for the internal network.  Contractor will use the name of the Network
to know what virtual network to select when deploying VMs.  Replace `< network name >` with
the name of the network created in vcenter (ie: internal) or virtual box (ie: vboxnet0), for
IPMI and AMT, use 'internal'::

  contractorcli network create -s site1 -n "< network name >"

Take note of the Id of that created Network.  Now to attach the AddressBlock to the Network,
replace `< network id >` with the Id of the Network, and `< addressblock id >` with the Id
of the AddressBlock from above::

  contractorcli network link create < network id > -a < addressblock id >

now to reserve some ip addresses so they do not get auto assigned::

  for OFFSET in 2 3 4 5 6 7 8 9 11 12 13 14 15 16 17 18 19 20; do
    contractorcli addressblock reserve < addressblock id > -o $OFFSET -r "Network Reserved"
  done

If you are installing to AMT/IPMI you will need some dynamic Ips for devices we
do not yet have MAC addresses for, we are going to set these to PXE boot to the
bootstrap image, if you are not going to to AMT/IPMI, skip this step, you probably
do not have the bootstrap PXE image loaded::

  for OFFSET in 21 22 23 24 25; do
    contractorcli addressblock dynamic < addressblock id > -o $OFFSET -p bootstrap
  done

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
boot problems. Make sure to run `systemctl restart tftpd-hpa` to reload.  If you
using a network that has a smaller MTU, add `-B 1200` that will make sure your tftp
packets make it through.  (If your MTU is less than about 1220, you will want to go smaller)
If you get the error "tftpd: read: Connection refused" from tftpd, make sure you do not
have address conflicts.

Next Steps
~~~~~~~~~~

If you are installing to VCenter or VirtualBox:
:doc:`complex`

If you are installing on a BareMetal/IPMI machine:
:doc:`install_baremetal`
