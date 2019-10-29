From Source
===========

.. raw:: html

    <div style="position: relative; padding-bottom: 56.25%; height: 0; overflow: hidden; max-width: 100%; height: auto;">
        <iframe src="https://www.youtube.com/embed/pstnJfNhtjE" frameborder="0" allowfullscreen style="position: absolute; top: 0; left: 0; width: 100%; height: 100%;"></iframe>
    </div>

Building requires running on a Ubuntu Xenial machine.

Install the required build tools, the PPA has a few required packages for building
and installing::

  sudo apt install -y software-properties-common
  sudo add-apt-repository -y ppa:pnhowe/t3kton
  sudo apt update
  sudo apt install -y git respkg build-essential python3-dev python3-setuptools nodejs npm nodejs-legacy liblzma-dev xorriso python3-django apache2 libapache2-mod-wsgi-py3 python3-parsimonious python3-werkzeug python3-psycopg2 python3-cinp python3-toml python3-jinja2 bind9 bind9utils python3-dhcplib python3-pymongo

Create an empty directory, and cd into it

First clone the contractor and related projects::

  git clone https://github.com/T3kton/contractor.git
  git clone https://github.com/T3kton/contractor_plugins.git
  git clone https://github.com/T3kton/subcontractor.git
  git clone https://github.com/T3kton/subcontractor_plugins.git
  git clone https://github.com/T3kton/resources.git

Now to build Contractor, first we need to get the node requirements for the UI, and fix a bug with react-toolbox::

  cd contractor
  cd ui && npm install
  sed s/"export Ripple from '.\/ripple';"/"export { default as Ripple } from '.\/ripple';"/ -i node_modules/react-toolbox/components/index.js
  sed s/"export Tooltip from '.\/tooltip';"/"export { default as Tooltip } from '.\/tooltip';"/ -i node_modules/react-toolbox/components/index.js
  cd ../..

and build the resources.  The make in the resources can take a while::

  for i in contractor_plugins resources; do cd $i && make -j2 respkg && mv *.respkg .. && cd ..; done

Now to install the python code, NOTE the Makefile will call './setup.py install' for you::

  cd contractor
  sudo DESTDIR=/ make install
  sudo cp debian/cron.d /etc/cron.d/contractor
  sudo cp /etc/contractor.conf.sample /etc/contractor.conf
  sudo ln -sf /etc/contractor.conf /usr/lib/python3/dist-packages/contractor/settings.py
  sudo mkdir -p /etc/bind/contractor/zones
  sudo mkdir -p /var/lib/contractor
  sudo a2ensite contractor.conf
  sudo a2enmod wsgi
  cd ..
  cd contractor_plugins
  sudo DESTDIR=/ make install
  cd ..
  cd subcontractor
  sudo DESTDIR=/ make install
  sudo cp debian/dhcpd.service /lib/systemd/system/
  sudo cp debian/subcontractor.service /lib/systemd/system/
  sudo systemctl enable dhcpd
  sudo systemctl enable subcontractor
  cd ..
  cd subcontractor_plugins
  sudo DESTDIR=/ make install
  cd ..
  sudo systemctl daemon-reload
  sudo systemctl restart cron
  sudo systemctl enable subcontractor
  sudo systemctl enable dhcpd

return to :ref:`contractor/tryit/installing:installing`
