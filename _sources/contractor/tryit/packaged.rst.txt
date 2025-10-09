.. highlight:: bash

From Prebuilt Packages
----------------------

First we will need the PPA with the cinp and respkg packages::

  sudo apt install -y software-properties-common
  sudo add-apt-repository -y ppa:pnhowe/t3kton
  sudo apt update

Now you can either `Installing from pre-built packages`_ or `Building Packages`_.
After that make sure you `Building the Resources`_.

Installing from pre-built packages
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Install::

  sudo apt install -y ntp contractor contractor-plugins subcontractor subcontractor-plugins python3-pysnmp4

Building Packages
~~~~~~~~~~~~~~~~~

Install the required build tools, the PPA has a few required packages for building
and installing::

  sudo apt install -y git respkg build-essential dpkg-dev debhelper python3-dev python3-setuptools nodejs npm liblzma-dev

First clone the contractor and related projects::

  git clone https://github.com/T3kton/contractor.git
  git clone https://github.com/T3kton/contractor_plugins.git
  git clone https://github.com/T3kton/subcontractor.git
  git clone https://github.com/T3kton/subcontractor_plugins.git

Now to build Contractor, first we need to get the node requirements for the UI, and fix a bug with react-toolbox::

  cd contractor
  cd ui && npm install && cd ..
  sed s/"export Ripple from '.\/ripple';"/"export { default as Ripple } from '.\/ripple';"/ -i ui/node_modules/react-toolbox/components/index.js
  sed s/"export Tooltip from '.\/tooltip';"/"export { default as Tooltip } from '.\/tooltip';"/ -i ui/node_modules/react-toolbox/components/index.js
  cd ..

Now build the packages::

  for i in contractor subcontractor contractor_plugins subcontractor_plugins; do cd $i && make dpkg && cd ..; done

Install Packages::

  sudo dpkg -i contractor_*.deb contractor-plugins_*.deb subcontractor_*.deb subcontractor-plugins_*.deb
  sudo apt install -f
  sudo systemctl stop dhcpd
  sudo systemctl stop subcontractor
  sudo apt install python3-pysnmp4

NOTE: the `dpkg -i` will fail to install all the packages due to missing the dependandices
the `apt install -f` should fix all that.

Building the Resources
~~~~~~~~~~~~~~~~~~~~~~

The resource packages are not hosted publicly so you will need to build them,
(you don't need, to checkout contractor_plugins if you built the packages)::

  sudo apt install git respkg build-essential liblzma-dev
  git clone https://github.com/T3kton/resources.git
  git clone https://github.com/T3kton/contractor_plugins.git
  for i in contractor_plugins resources; do cd $i && make -j2 respkg && mv *.respkg .. && cd ..; done

If you are doing AMT or IPMI, you will need the PXE images, that is built with::

  sudo apt install -y bc libgcrypt-dev libgpg-error-dev libksba-dev libassuan-dev libnpth0-dev pkg-config zlib1g-dev libelf-dev uuid-dev libdevmapper-dev libreadline-dev libssl-dev gperf gettext libblkid-dev python3-pip
  git clone https://github.com/T3kton/disks.git
  cd disks ; make -j2; make respkg; mv *.respkg ..; cd ..

NOTE: close to the end of the build, there are some sudo commands, so you will be
prompted for sudo password if you are not already root.

return to :ref:`contractor/tryit/installing:installing`
