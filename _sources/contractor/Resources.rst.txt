Resources
=========

OS Base
-------

OS Base
~~~~~~~

Structure BluePrints
^^^^^^^^^^^^^^^^^^^^

linux-base
..........


Ubuntu
~~~~~~

Structure BluePrints
^^^^^^^^^^^^^^^^^^^^

ubuntu-base
...........

ubuntu-trusty-base
..................

ubuntu-xenial-base
..................

ubuntu-bionic-base
..................

PXE
^^^

ubuntu
......

  :__pxe_location:
  :__pxe_template_location:
  :_interface_map:
  :_hostname:
  :_domain_name:
  :dns_servers: list of dns server ip address
  :mirror_server: ubuntu mirror server, ie: `us.archive.ubuntu.com`
  :mirror_proxy: proxy server to access the mirror_server (optional), ie: 'http://proxy:3128/'
  :distro_version: ubuntu version, ie: `xenial`
  :root_pass: hashed root password
  :ntp_servers: list of ntp servers
  :packages: list of packages to install, ie: `[ 'open-vm-tools' ]`
  :postinstall_script: url to a script to download and executed in the target install, ie: `http://static/stuff.sh`
  :postinstall_commands: list of commands to run in the target install, ie: `[ 'echo "configured" > /etc/file', 'ls -l / > /stock_root' ]`

NOTE: `postinstall_script` is executed before `postinstall_commands`

CentOS
~~~~~~

Structure BluePrints
^^^^^^^^^^^^^^^^^^^^

centos-base
...........

centos-6-base
.............

centos-7-base
.............

PXE
^^^

centos-6
........

  :__pxe_location:
  :__pxe_template_location:
  :_fqdn:
  :_interface_map:
  :mirror_server:
  :mirror_proxy:
  :dns_servers:
  :root_pass:
  :packages:
  :postinstall_script:
  :postinstall_commands:

See ububntu pxe for details

centos-7
........

Same as centos-6

Utility
-------

Utility
~~~~~~~

Structure BluePrints
^^^^^^^^^^^^^^^^^^^^

linux-jumpbox
.............


VMWare
------
