.. highlight:: bash

Working with Docker
-------------------

.. raw:: html

    <div style="position: relative; padding-bottom: 56.25%; height: 0; overflow: hidden; max-width: 100%; height: auto;">
        <iframe src="https://www.youtube.com/embed/IzdTStAEvuk" frameborder="0" allowfullscreen style="position: absolute; top: 0; left: 0; width: 100%; height: 100%;"></iframe>
    </div>

.. note:: The video shows the earlier version of these steps using curl. The steps below do the same thing with contractorcli.


Set up the Docker Host
~~~~~~~~~~~~~~~~~~~~~~

If you skipped the Demo VM, make sure the ubuntu blueprints are loaded::

  sudo respkg -i contractor-ubuntu-base_*.respkg

First we need a Docker host, we will create a Ubuntu VM and request docker be
installed during the OS install, the foundation is the same as the VM install,
use the foundation type and complex for the platform you used in :doc:`complex`
(this example is VirtualBox)::

  contractorcli foundation virtualbox create -s site1 -l docker01 -b virtualbox-vm-base -x demovbox

create the interface, replace `< network id >` with the Id of the Network we created
in :doc:`installing`::

  contractorcli foundation interface create docker01 -n eth0 -y eth0 -t < network id > -p

Next we need to create a VM with Docker installed.  If we were doing a simple one-off
we could set the config values for this structure directly.  However this one is a little
bit more involved, and makes a good example of rolling your own blueprint.  First
we need to make a blue print file, edit `/root/dockerhost.toml`, and paste this
into it::

  [ structure.docker-host ]
    description = 'Docker Host'
    parents = [ 'ubuntu-noble-base' ]
  [ structure.docker-host.config_values ]
    '>package_list' = [ 'docker.io' ]
    'postinstall_script' = 'http://static/dockersetup'

Now we need to load the blueprint into contractor::

  /usr/lib/contractor/util/blueprintLoader /root/dockerhost.toml

Normally for a few simple commands we could of used `ostinstall_command_list`, instead
of the `postinstall_script`, but our setup is on the side of more complex.  Edit
`/var/www/static/dockersetup` and put this in it::

  #!/bin/sh

  echo "Starting docker setup..."

  mkdir /etc/systemd/system/docker.service.d

  cat << EOF > /etc/systemd/system/docker.service.d/override.conf
  [Service]
  ExecStart=
  ExecStart=/usr/bin/dockerd -H fd:// -H tcp://0.0.0.0:2376 --containerd=/run/containerd/containerd.sock
  Environment="http_proxy=http://10.0.0.10:3128/ https_proxy=http://10.0.0.10:3128/"
  EOF

  systemctl daemon-reload
  systemctl enable docker.service

  echo "Done!"

With the BluePrint and it's resources ready to go, we can create a structure with our new blueprint::

  contractorcli structure create -s site1 -f docker01 -o docker01 -b docker-host

once again take node of the structure id.  And again, let Contractor pick the ip address,
Replace `< structure id >` with the structure id from the previous call, and `< addressblock id >`
with the Id of the AddressBlock::

  contractorcli structure address next < structure id > -a < addressblock id > -n eth0 -p

Now the create jobs, replace the <structure id> with the structure id of the docker01
structure::

  contractorcli foundation job do-create docker01
  contractorcli structure job do-create < structure id >

Set up The Complex
~~~~~~~~~~~~~~~~~~

Much like VCenter/Virtualbox, the containers belong to a complex.  Now we create
a Docker Complex

.. note:: contractorcli does not yet have commands for Docker Complexes or Docker Ports, so this section uses the HTTP API with curl. 

First set up the curl options.  Log in with your `root` password, which will output an auth token, and
use it in the `Auth-Token` header (replace `< auth token >`)::

  export COPS=( --noproxy \* --header "CInP-Version: 0.9" --header "Content-Type: application/json" )
  export SITE="/api/v1/Site/Site:site1:"
  export CHOST="http://127.0.0.1"
  echo '{ "username": "root", "password": "< password >" }' | curl "${COPS[@]}" --data @- -X CALL $CHOST/api/v1/Auth/User\(login\)
  COPS+=( --header "Auth-Id: root" --header "Auth-Token: < auth token >" )

Now to Create the Docker Complex::

  cat << EOF | curl "${COPS[@]}" --data @- -X CREATE $CHOST/api/v1/Docker/DockerComplex
  { "site": "$SITE", "name": "demodocker", "description": "Demo Docker Host/Complex" }
  EOF

Now we add the structure host we created as a member of the complex,
replace `< structure id >` with the id from the vm from above::

  cat << EOF | curl "${COPS[@]}" --data @- -X CREATE $CHOST/api/v1/Building/ComplexStructure
  { "complex": "/api/v1/Building/Complex:demodocker:", "structure": "/api/v1/Building/Structure:< structure id>:" }
  EOF

Docker containters don't have their own IP address, they use the IP address of
the host.  To expose services Docker mapps ports thgrough, we need to give Contractor
a list of Ports to use to map through::

  for PORT in $(seq 6000 6050); do
  cat << EOF | curl "${COPS[@]}" --data @- -X CREATE $CHOST/api/v1/Docker/DockerPort
  { "complex": "/api/v1/Docker/DockerComplex:demodocker:", "address_offset": 0, "port": $PORT }
  EOF
  done

Create a Container
~~~~~~~~~~~~~~~~~~

First up the Foundation::

  contractorcli foundation docker create -s site1 -l container01 -b docker-container-base -x demodocker

Containers inherit the interface and ip address from their host, so we don't
create an interface.  Next up create the structure, with a Ubuntu blueprint (which
one is up to you, the blueprint has the name of the container image to pull)::

  contractorcli structure create -s site1 -f container01 -o container01 -b ubuntu-noble-base

take note of the new structure id.

Note: we picked the same blueprint as we did for Ubuntu VMs, this blueprint
not only has the configuration information for PXE installing, but also the
name of the official ubuntu container on docker hub.

Note 2: the `docker_command` in this case is just using the perl binary allready in
the container to listen on port 22 so the port check will succeed.  `docker_command`
can be either a string or a list, in this case a list so we can control how it is parsed.

Now the create jobs, replace the <structure id> with the structure id of the container01
structure::

  contractorcli foundation job do-create container01
  contractorcli structure job do-create < structure id >

Due to the fact that the OS is installed as part of the container, the OS
is "installed" during the foundation deploy, so that the foundation deploy
deploys the correct OS, the foundation looks at the structure blueprint for the
name of the container to download and install from dockerhub.  The Structure
create script detects that it is a container, and just does the port check to
verify that ssh is running.  Also with the container inheriting the ip address
of the host, contractor will do the ssh port check for the port that has
been assigned during the deploy.

if you ssh to the docker01 vm (`ssh root@docker01` from the contractor vm, the root
password should be `root`), and run a `docker ps` you will see our new container
along with the forwared port::

  root@docker01:~# docker ps -a
  CONTAINER ID        IMAGE               COMMAND                   CREATED             STATUS              PORTS                  NAMES
  eb3c74946a2f        ubuntu:noble       "/bin/sh -c 'echo \"u…"   31 seconds ago      Up 14 seconds       0.0.0.0:6010->22/tcp   container01

Destruction and cleanup of the container is the same procedure as in the VM example::

  contractorcli structure job do-destroy < structure id >
  contractorcli foundation job do-destroy container01

and once the jobs are done::

  contractorcli structure delete < structure id >
  contractorcli foundation delete container01
