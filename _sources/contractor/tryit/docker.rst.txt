.. highlight:: bash

Working with Docker
-------------------

.. raw:: html

    <div style="position: relative; padding-bottom: 56.25%; height: 0; overflow: hidden; max-width: 100%; height: auto;">
        <iframe src="https://www.youtube.com/embed/IzdTStAEvuk" frameborder="0" allowfullscreen style="position: absolute; top: 0; left: 0; width: 100%; height: 100%;"></iframe>
    </div>


Set up the Docker Host
~~~~~~~~~~~~~~~~~~~~~~

If you skipped the Demo VM, make sure the ubuntu blueprints are loaded::

  sudo respkg -i contractor-ubuntu-base_*.respkg

First we need a Docker host, we will create a Ubuntu VM and request docker be
installed during the OS install, the foundation is the same as the VM install::

  cat << EOF | curl "${COPS[@]}" --data @- -X CREATE $CHOST/$FMDL
  { "site": "$SITE", "locator": "docker01", "blueprint": "$FBP" $FDATA }
  EOF

result::

  {"locator": "docker01", "site": "/api/v1/Site/Site:site1:", "blueprint": "/api/v1/BluePrint/FoundationBluePrint:virtualbox-vm-base:", "id_map": null, "located_at": null, "built_at": null, "updated": "2019-11-22T17:06:30.236870+00:00", "created": "2019-11-22T17:06:30.236883+00:00", "virtualbox_complex": "/api/v1/VirtualBox/VirtualBoxComplex:demovbox:", "virtualbox_uuid": null, "state": "planned", "type": "VirtualBox", "class_list": "['VM', 'VirtualBox']"

create the interface::

  cat << EOF | curl "${COPS[@]}" --data @- -X CREATE $CHOST/api/v1/Utilities/RealNetworkInterface
  { "foundation": "/api/v1/Building/Foundation:docker01:", "name": "eth0", "physical_location": "eth0", "network": "$NETWORK", "is_provisioning": true }
  EOF

result::

  {"name": "eth0", "is_provisioning": true, "network": "/api/v1/Utilities/Network:2:", "updated": "2019-11-22T17:06:46.733288+00:00", "created": "2019-11-22T17:06:46.733313+00:00", "mac": null, "foundation": "/api/v1/Building/Foundation:docker01:", "physical_location": "eth0", "link_name": null, "pxe": null}

Next we need to create a VM with Docker installed.  If we were doing a simple one-off
we could set the config values for this structure directly.  However this one is a little
bit more involved, and makes a good example of rolling your own blueprint.  First
we need to make a blue print file, edit `/root/dockerhost.toml`, and paste this
into it::

  [ structure.docker-host ]
    description = 'Docker Host'
    parents = [ 'ubuntu-bionic-base' ]
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

  cat << EOF | curl -i "${COPS[@]}" --data @- -X CREATE $CHOST/api/v1/Building/Structure
  { "site": "$SITE", "foundation": "/api/v1/Building/Foundation:docker01:", "hostname": "docker01", "blueprint": "/api/v1/BluePrint/StructureBluePrint:docker-host:" }
  EOF

result::

  {"hostname": "docker01", "site": "/api/v1/Site/Site:site1:", "blueprint": "/api/v1/BluePrint/StructureBluePrint:ubuntu-bionic-base:", "foundation": "/api/v1/Building/Foundation:docker01:", "config_uuid": "bdf2fefc-299a-4b34-bc3c-894cea1411d7", "config_values": {">package_list": ["docker.io"]}, "built_at": null, "updated": "2019-11-22T17:13:16.509773+00:00", "created": "2019-11-22T17:13:16.509800+00:00", "state": "planned"}

once again take node of the structure id.  And again, let Contractor pick the ip address,
Replace `< structure id >` with the structure id from the previous call::

  cat << EOF | curl "${COPS[@]}" --data @- -X CALL "${CHOST}${ADRBLK}(nextAddress)"
  { "networked": "/api/v1/Utilities/Networked:< structure id >:", "interface_name": "eth0", "is_primary": true }
  EOF

result::

  "/api/v1/Utilities/Address:30:"

Now the create jobs, replace the <structure id> with the structure id of the docker01
structure::

  curl "${COPS[@]}" -X CALL "${CHOST}/api/v1/Building/Foundation:docker01:(doCreate)"
  curl "${COPS[@]}" -X CALL "${CHOST}/api/v1/Building/Structure:< structure id >:(doCreate)"

Set up The Complex
~~~~~~~~~~~~~~~~~~

Much like VCenter/Virtualbox, the containers belong to a complex.  Now we create
a Docker Complex

First we need to re-define our foundation related environment variables to do docker:

Environment setup::

  export FBP="/api/v1/BluePrint/FoundationBluePrint:docker-container-base:"
  export FMDL="/api/v1/Docker/DockerFoundation"
  export FDATA=', "docker_complex": "/api/v1/Docker/DockerComplex:demodocker:"'

Now to Create the Docker Complex::

  cat << EOF | curl "${COPS[@]}" --data @- -X CREATE $CHOST/api/v1/Docker/DockerComplex
  { "site": "$SITE", "name": "demodocker", "description": "Demo Docker Host/Complex" }
  EOF

result::

  {"name": "demodocker", "site": "/api/v1/Site/Site:site1:", "description": "Demo Docker Host/Complex", "built_percentage": 90, "updated": "2019-11-23T00:00:04.930488+00:00", "created": "2019-11-23T00:00:04.930524+00:00", "members": [], "state": "planned", "type": "Docker"}

Now we add the structure host we manually created as a member of the complex,
replace `< structure id >` with the id from the vm from above::

  cat << EOF | curl "${COPS[@]}" --data @- -X CREATE $CHOST/api/v1/Building/ComplexStructure
  { "complex": "/api/v1/Building/Complex:demodocker:", "structure": "/api/v1/Building/Structure:< structure id>:" }
  EOF

result::

  {"complex": "/api/v1/Building/Complex:demodocker:", "structure": "/api/v1/Building/Structure:3:", "updated": "2019-11-23T00:01:12.093790+00:00", "created": "2019-11-23T00:01:12.093821+00:00"}

Docker containters don't have their own IP address, they use the IP address of
the host.  To expose services Docker mapps ports thgrough, we need to give Contractor
a list of Ports to use to map through::


  for PORT in $(seq 6000 6050); do
  cat << EOF | curl "${COPS[@]}" --data @- -X CREATE $CHOST/api/v1/Docker/DockerPort
  { "complex": "/api/v1/Docker/DockerComplex:demodocker:", "address_offset": 0, "port": $PORT }
  EOF
  done

result::

  {"complex": "/api/v1/Docker/DockerComplex:demodocker:", "port": 6000, "address_offset": 0, "foundation": null, "foundation_index": 0, "updated": "2019-12-20T20:31:52.061279+00:00", "created": "2019-12-20T20:31:52.061299+00:00"}
  {"complex": "/api/v1/Docker/DockerComplex:demodocker:", "port": 6001, "address_offset": 0, "foundation": null, "foundation_index": 0, "updated": "2019-12-20T20:31:52.093897+00:00", "created": "2019-12-20T20:31:52.093918+00:00"}
  ...
  {"complex": "/api/v1/Docker/DockerComplex:demodocker:", "port": 6048, "address_offset": 0, "foundation": null, "foundation_index": 0, "updated": "2019-12-20T20:31:53.299457+00:00", "created": "2019-12-20T20:31:53.299482+00:00"}
  {"complex": "/api/v1/Docker/DockerComplex:demodocker:", "port": 6049, "address_offset": 0, "foundation": null, "foundation_index": 0, "updated": "2019-12-20T20:31:53.324446+00:00", "created": "2019-12-20T20:31:53.324469+00:00"}
  {"complex": "/api/v1/Docker/DockerComplex:demodocker:", "port": 6050, "address_offset": 0, "foundation": null, "foundation_index": 0, "updated": "2019-12-20T20:31:53.350806+00:00", "created": "2019-12-20T20:31:53.350848+00:00"}

Create a Container
~~~~~~~~~~~~~~~~~~

First up the Foundation::

  cat << EOF | curl "${COPS[@]}" --data @- -X CREATE $CHOST/$FMDL
  { "site": "$SITE", "locator": "container01", "blueprint": "$FBP" $FDATA }
  EOF

result::

  {"locator": "container01", "site": "/api/v1/Site/Site:site1:", "blueprint": "/api/v1/BluePrint/FoundationBluePrint:docker-container-base:", "id_map": null, "located_at": null, "built_at": null, "updated": "2019-11-27T05:02:12.052970+00:00", "created": "2019-11-27T05:02:12.052984+00:00", "docker_complex": "/api/v1/Docker/DockerComplex:demodocker:", "docker_id": null, "state": "planned", "type": "Docker", "class_list": "['Docker']"}

Containers inherit the interface and ip address from their host, so we don't
create an interface.  Next up create the structure::

  cat << EOF | curl -i "${COPS[@]}" --data @- -X CREATE $CHOST/api/v1/Building/Structure
  { "site": "$SITE", "foundation": "/api/v1/Building/Foundation:container01:", "hostname": "container01", "blueprint": "/api/v1/BluePrint/StructureBluePrint:ubuntu-bionic-base:", "config_values": { "docker_command": [ "/bin/sh", "-c", "echo \"use IO::Socket; my \\\\\$sock = new IO::Socket::INET (LocalHost=>'0.0.0.0', LocalPort=>'22', Proto=>'tcp', Listen=>1); while(1){ \\\\\$sock->accept(); };\" | perl" ], "port_list": [ "22/tcp" ] } }
  EOF

result::

  {"hostname": "container01", "site": "/api/v1/Site/Site:site1:", "blueprint": "/api/v1/BluePrint/StructureBluePrint:ubuntu-bionic-base:", "foundation": "/api/v1/Building/Foundation:container01:", "config_uuid": "f08daa97-3788-469d-a1ae-51cafe6e6af9", "config_values": {"docker_command": ["/bin/sh", "-c", "echo \"use IO::Socket; my \\$sock = new IO::Socket::INET (LocalHost=>'0.0.0.0', LocalPort=>'22', Proto=>'tcp', Listen=>1); while(1){ \\$sock->accept(); };\" | perl"], "port_list": ["22/tcp"]}, "built_at": null, "updated": "2019-12-30T21:33:06.493784+00:00", "created": "2019-12-30T21:33:06.493825+00:00", "state": "planned"}

take note of the new structure id.

Note: we picked the same blueprint as we did for Ubuntu Bionic VMs, this blueprint
not only has the configuration information for PXE installing, but also the
name of official bionic container on docker hub.

Note 2: the `docker_command` in this case is just using the perl binary allready in
the container to listen on port 22 so the port check will succeed.  `docker_command`
can be either a string or a list, in this case a list so we can control how it is parsed.

Now the create jobs, replace the <structure id> with the structure id of the container01
structure::

  curl "${COPS[@]}" -X CALL "${CHOST}/api/v1/Building/Foundation:container01:(doCreate)"
  curl "${COPS[@]}" -X CALL "${CHOST}/api/v1/Building/Structure:< structure id >:(doCreate)"

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
  eb3c74946a2f        ubuntu:bionic       "/bin/sh -c 'echo \"u…"   31 seconds ago      Up 14 seconds       0.0.0.0:6010->22/tcp   container01

Destruction and cleanup of the container is the same procedure as in the VM example::

  curl "${COPS[@]}" -X CALL "${CHOST}/api/v1/Building/Structure:< structure id >:(doDestroy)"
  curl "${COPS[@]}" -X CALL "${CHOST}/api/v1/Building/Foundation:container01:(doDestroy)"

and::

  curl "${COPS[@]}" -X DELETE "${CHOST}/api/v1/Building/Structure:< structure id >:"
  curl "${COPS[@]}" -X DELETE "${CHOST}/api/v1/Building/Foundation:container01:"
