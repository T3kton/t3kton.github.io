Creating a VM (Ubuntu)
~~~~~~~~~~~~~~~~~~~~~~

First we need to load the ubuntu blueprints::

  sudo respkg -i contractor-ubuntu-base_*.respkg

Now we create the Foundation of the VM to be created::

  cat << EOF | curl "${COPS[@]}" --data @- -X CREATE $CHOST/$FMDL
  { "site": "$SITE", "locator": "testvm01", "blueprint": "$FBP" $FDATA }
  EOF

result::

  {"state": "planned", "site": "/api/v1/Site/Site:site1:", "type": "VirtualBox", "id_map": "", "virtualbox_complex": "/api/v1/VirtualBox/VirtualBoxComplex:demovbox:", "blueprint": "/api/v1/BluePrint/FoundationBluePrint:virtualbox-vm-base:", "built_at": null, "locator": "tesvm01", "located_at": null, "updated": "2019-02-20T04:58:52.855473+00:00", "created": "2019-02-20T04:58:52.855507+00:00", "class_list": "['VM', 'VirtualBox']", "virtualbox_uuid": null}

create the interface::

  cat << EOF | curl "${COPS[@]}" --data @- -X CREATE $CHOST/api/v1/Utilities/RealNetworkInterface
  { "foundation": "/api/v1/Building/Foundation:testvm01:", "name": "eth0", "physical_location": "eth0", "network": "$NETWORK", "is_provisioning": true }
  EOF

result::

  {"mac": null, "is_provisioning": true, "name": "eth0", "physical_location": "eth0", "network": "/api/v1/Utilities/Network:2:", "created": "2019-10-27T04:01:42.209918+00:00", "foundation": "/api/v1/Building/Foundation:testvm01:", "updated": "2019-10-27T04:01:42.209881+00:00", "link_name": null, "pxe": null}

Now we will create a VM with the Ubuntu Bionic blueprint::

  cat << EOF | curl -i "${COPS[@]}" --data @- -X CREATE $CHOST/api/v1/Building/Structure
  { "site": "$SITE", "foundation": "/api/v1/Building/Foundation:testvm01:", "hostname": "testvm01", "blueprint": "/api/v1/BluePrint/StructureBluePrint:ubuntu-bionic-base:" }
  EOF

once again take node of the structure id.  Now we assign and ip address, we will
let contractor pick, we are going to use the helper method `nextAddress`.  Replace
`< structure id >` with the structure id from the previous call::

  cat << EOF | curl "${COPS[@]}" --data @- -X CALL "${CHOST}${ADRBLK}(nextAddress)"
  { "networked": "/api/v1/Utilities/Networked:< structure id >:", "interface_name": "eth0", "is_primary": true }
  EOF

result::

  "/api/v1/Utilities/Address:30:"

Contractor will not auto-start the create (nor destroy) jobs.  So we need to add two
jobs, one to create the Foundation and one to create the Structure::

  curl "${COPS[@]}" -X CALL "${CHOST}/api/v1/Building/Foundation:testvm01:(doCreate)"
  curl "${COPS[@]}" -X CALL "${CHOST}/api/v1/Building/Structure:< structure id >:(doCreate)"

Now to see it get built.  Pull up the `http://<contractor ip>`
in a web browser if you don't have it open allready, go to the `Job Log` should see an
entry saying that the foundation build has started.  Goto the `Jobs` should see a Foundation
or Structure Job there.  The Foundation Job won't last long.  In the top right of the
page is a refresh and auto refresh buttons.

After the Foundation job completes, a Structure job will auto start, after it completes
your VM should be up and sshable, however the default for ubuntu is to disallow sshing
as root, but we can show the ssh service is listening::

  nc -vz testvm01 22

should output something like::

  Connection to testvm01 22 port [tcp/ssh] succeeded!

If you pull up the console, the default root password is "root".

After you have verified that it is there, logout of the test vm and kick off a
job to clean it up::

  curl "${COPS[@]}" -X CALL "${CHOST}/api/v1/Building/Foundation:testvm01:(doDestroy)"
  curl "${COPS[@]}" -X CALL "${CHOST}/api/v1/Building/Structure:< structure id >:(doDestroy)"

After those jobs have completed you can call the doCreate again to rebuild them.

Creating a VM (CentOS)
~~~~~~~~~~~~~~~~~~~~~~

Ok, let's create a centos VM now, is't all the same as the ubuntu VM except the
blueprint we choose.

Load the centos Blueprints::

  sudo respkg -i contractor-centos-base_*.respkg

Foundation::

  cat << EOF | curl "${COPS[@]}" --data @- -X CREATE $CHOST/$FMDL
  { "site": "$SITE", "locator": "testvm02", "blueprint": "$FBP" $FDATA }
  EOF

result::

  {"state": "planned", "site": "/api/v1/Site/Site:site1:", "type": "VirtualBox", "id_map": "", "virtualbox_complex": "/api/v1/VirtualBox/VirtualBoxComplex:demovbox:", "blueprint": "/api/v1/BluePrint/FoundationBluePrint:virtualbox-vm-base:", "built_at": null, "locator": "tesvm01", "located_at": null, "updated": "2019-02-20T04:58:52.855473+00:00", "created": "2019-02-20T04:58:52.855507+00:00", "class_list": "['VM', 'VirtualBox']", "virtualbox_uuid": null}

create the interface::

  cat << EOF | curl "${COPS[@]}" --data @- -X CREATE $CHOST/api/v1/Utilities/RealNetworkInterface
  { "foundation": "/api/v1/Building/Foundation:testvm02:", "name": "eth0", "physical_location": "eth0", "network": "$NETWORK", "is_provisioning": true }
  EOF

result::

  {"pxe": null, "name": "eth0", "is_provisioning": true, "physical_location": "eth0", "network": "/api/v1/Utilities/Network:2:", "updated": "2019-02-25T14:28:36.245466+00:00", "mac": null, "foundation": "/api/v1/Building/Foundation:testvm02:", "created": "2019-02-25T14:28:36.245500+00:00"}

Now we will create a VM with the CentOS7 blueprint::

  cat << EOF | curl -i "${COPS[@]}" --data @- -X CREATE $CHOST/api/v1/Building/Structure
  { "site": "$SITE", "foundation": "/api/v1/Building/Foundation:testvm02:", "hostname": "testvm02", "blueprint": "/api/v1/BluePrint/StructureBluePrint:centos-7-base:" }
  EOF

result::

  HTTP/1.1 201 CREATED
  Date: Mon, 11 Mar 2019 13:45:58 GMT
  Server: Apache/2.4.18 (Ubuntu)
  Cache-Control: no-cache
  Verb: CREATE
  Cinp-Version: 0.9
  Object-Id: /api/v1/Building/Structure:4:
  Access-Control-Expose-Headers: Method, Type, Cinp-Version, Count, Position, Total, Multi-Object, Object-Id, Id-Only
  Access-Control-Allow-Origin: *
  Content-Length: 413
  Content-Type: application/json;charset=utf-8

  {"hostname": "testvm02", "created": "2019-03-11T13:45:58.963923+00:00", "config_values": null, "config_uuid": "d8821d29-f884-4c2d-af63-7d0292b2ce41", "updated": "2019-03-11T13:45:58.963901+00:00", "blueprint": "/api/v1/BluePrint/StructureBluePrint:centos-7-base:", "site": "/api/v1/Site/Site:site1:", "foundation": "/api/v1/Building/Foundation:testvm02:", "built_at": null, "state": "planned"}

and assign the ip address, make sure to use the structure id from the testvm02 structure::

  cat << EOF | curl "${COPS[@]}" --data @- -X CALL "${CHOST}${ADRBLK}(nextAddress)"
  { "networked": "/api/v1/Utilities/Networked:< structure id >:", "interface_name": "eth0", "is_primary": true }
  EOF

result::

  "/api/v1/Utilities/Address:30:"

Once again create the create jobs::

  curl "${COPS[@]}" -X CALL "${CHOST}/api/v1/Building/Foundation:testvm02:(doCreate)"
  curl "${COPS[@]}" -X CALL "${CHOST}/api/v1/Building/Structure:< structure id >:(doCreate)"

Again the jobs should be running to create the CentOS VM.  When it is done, ssh in::

  ssh root@testvm02

Once again the root password is "root", go a head and play around with it for a bit.
Make sure to try deconfiguring both VMs at the same time so you can see Contractor
do more than one thing at a time.

Next Steps
~~~~~~~~~~
:doc:`config_info`
