In Docker
=========

*NOTE:* the docker container version of contractor does not include an
instance of subcontractor, nor is it fully configured for supplying
static files for some types of deployments.  This is really intended
for developing/testing against the API and/or previewing contractor.
The best way to deploy contractor for regular workloads is via the debian
packaging.  There is a PPA at: https://launchpad.net/~pnhowe/+archive/ubuntu/t3kton

Running the Docker Container
----------------------------

First pull down the container::

  docker pull t3kton/contractor:latest

And start it up::

  docker start -p80:80 --name contractor t3kton/contractor

The pre-built container only has the `iputils` and `manual` plugins loaded.
If you would like to enable other plugins, the packages for the `amt`, `ipmi`,
`azure`, `docker`, `ipmi`, `vcenter`, and `virtualbox` are in the container.  If you
would like to enable one or more of these plugins (this example is for ipmi) replace
the "ipmi" with the plugin you want to enable::

  docker exec -it contractor /bin/bash
  respkg -i contractor-plugins-ipmi_*.respkg
  apachectl restart

Building the Container
----------------------

see https://github.com/t3kton/docker
