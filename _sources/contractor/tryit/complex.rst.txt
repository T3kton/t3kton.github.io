Setting up VM Host
~~~~~~~~~~~~~~~~~~

First we need to make a pre-built entry on a manual foundation to represent the
virtualbox/vcenter/esx host, first creating the foundation::

  cat << EOF | curl "${COPS[@]}" --data @- -X CREATE $CHOST/api/v1/Manual/ManualFoundation
  { "site": "$SITE", "locator": "host", "blueprint": "/api/v1/BluePrint/FoundationBluePrint:manual-foundation-base:" }
  EOF

result::

  {"state": "planned", "id_map": null, "located_at": null, "class_list": "['Metal', 'VM', 'Container', 'Switch', 'Manual']", "blueprint": "/api/v1/BluePrint/FoundationBluePrint:manual-foundation-base:", "created": "2019-02-23T16:48:53.818982+00:00", "built_at": null, "locator": "host", "updated": "2019-02-23T16:48:53.818962+00:00", "site": "/api/v1/Site/Site:site1:", "type": "Manual"}

create the interface::

  cat << EOF | curl "${COPS[@]}" --data @- -X CREATE $CHOST/api/v1/Utilities/RealNetworkInterface
  { "foundation": "/api/v1/Building/Foundation:host:", "name": "eth0", "physical_location": "eth0", "network": "$NETWORK", "is_provisioning": true }
  EOF

result::

  {"mac": null, "foundation": "/api/v1/Building/Foundation:host:", "physical_location": "eth0", "link_name": null, "pxe": null, "name": "eth0", "network": "/api/v1/Utilities/Network:2:", "is_provisioning": true, "updated": "2019-10-24T21:14:47.994825+00:00", "created": "2019-10-24T21:14:47.994854+00:00"}

Now to create the structure::

  cat << EOF | curl -i "${COPS[@]}" --data @- -X CREATE $CHOST/api/v1/Building/Structure
  { "site": "$SITE", "foundation": "/api/v1/Building/Foundation:host:", "hostname": "host", "blueprint": "/api/v1/BluePrint/StructureBluePrint:manual-structure-base:" }
  EOF

result::

  {"config_uuid": "349c8a47-e123-4234-91de-c387a440ffa5", "hostname": "host", "state": "planned", "blueprint": "/api/v1/BluePrint/StructureBluePrint:manual-structure-base:", "built_at": null, "foundation": "/api/v1/Building/Foundation:host:", "config_values": {}, "site": "/api/v1/Site/Site:site1:", "created": "2019-02-23T16:49:20.064258+00:00", "updated": "2019-02-23T16:49:20.064239+00:00"}

Take note of the new structures id.  You might want to write it done somewhere,
we will be using it a few times.

now we need to tell contractor it is allready built so it dosen't try to build it
again.  There curently isn't a API endpoint to manipluate the state of targets,
so we will use a command line utility, this command needs to be run on the
contractor VM. replace `< structure id >` with the id from the previous step::

  /usr/lib/contractor/util/boss -f host --built
  /usr/lib/contractor/util/boss -s < structure id > --built

which will output something like this::

  Working with "ManualFoundation host"
  No Job to Delete
  ManualFoundation host now set to built.
  Working with "Structure #2(host) of "manual-structure-base" in "site1""
  No Job to Delete
  Structure #2(host) of "manual-structure-base" in "site1" now set to built.

Now to define the foundation blueprint and create the complex.

VCenter
~~~~~~~

Environment setup::

  export FBP="/api/v1/BluePrint/FoundationBluePrint:vcenter-vm-base:"
  export FMDL="/api/v1/VCenter/VCenterFoundation"
  export FDATA=', "vcenter_complex": "/api/v1/VCenter/VCenterComplex:demovcenter:"'

First create the VCenterBox Complex, replace `< datacenter >` with the name of
the VCenter datacenter to put the VMs in, if using ESX directly put 'ha-datacenter',
replace `< cluster >` with the name of the cluster to put the vms in, if using
ESX put the fqdn of the ESX server (if you only specified a hostname it will be
<hostname> + '.' ), if it's still default it will be 'localhost.'.
Replace `< structure id >`
with the strudture id from the host creation above, `< username >` and `< password >`
replace with the ESX/VCenter username and password::

  cat << EOF | curl "${COPS[@]}" --data @- -X CREATE $CHOST/api/v1/VCenter/VCenterComplex
  { "site": "$SITE", "name": "demovcenter", "description": "Demo VCenter/ESX Host/Complex", "vcenter_datacenter": "< datacenter >", "vcenter_cluster": "< cluster >", "vcenter_host": "/api/v1/Building/Structure:< structure id>:", "vcenter_username": "< username >", "vcenter_password": "< password >" }
  EOF

result::

  {"built_percentage": 90, "state": "planned", "site": "/api/v1/Site/Site:site1:", "created": "2019-02-23T23:51:33.613222+00:00", "vcenter_host": "/api/v1/Building/Structure:2:", "vcenter_password": "vmware", "updated": "2019-02-23T23:51:33.613199+00:00", "vcenter_cluster": null, "name": "demovcenter", "description": "Demo VCenter/ESX Host/Complex", "vcenter_datacenter": "ha-datacenter", "type": "VCenter", "members": [], "vcenter_username": "root"}

Technically if you are using VCenter, you should create another structure
so Contractor knows the hosts of the VCenter cluster, however, for the sake of
simplicity, we will just add the ESX Host/VCenter cluster we just added as the host
of the VCenterCluster as it's only member,  once again the `< structure id >` is
the id of the manual structure  we have been using so far::

  cat << EOF | curl "${COPS[@]}" --data @- -X CREATE $CHOST/api/v1/Building/ComplexStructure
  { "complex": "/api/v1/Building/Complex:demovcenter:", "structure": "/api/v1/Building/Structure:< structure id>:" }
  EOF

result::

  {"created": "2019-02-24T00:02:06.164123+00:00", "complex": "/api/v1/Building/Complex:demovcenter:", "structure": "/api/v1/Building/Structure:2:", "updated": "2019-02-24T00:02:06.164082+00:00"}

now to set the ip address of the vcenter/esx host. This ip will be used by
subcontractor to communicate with VCenter to manipulate vms, and will need to be
route-able from the contractor vm (where subcontractor is installed), this assumes
that address is in the address space of the contractor vm, specifically the network
that setupWizard created.  Change `< offset >`
to the offset of the VCenter/ESX host, if the VCenter/ESX host is not in the same
network that the contractor was created in, (and thus the same network that was
setup bu the setup wizzard), you will need to create another AddressBlock and update
the following call to use that AddressBlock in the following.  Replace structure id
with the id from the structure creation step::

  cat << EOF | curl "${COPS[@]}" --data @- -X CREATE $CHOST/api/v1/Utilities/Address
  { "networked": "/api/v1/Utilities/Networked:< structure id >:", "address_block": "$ADRBLK", "interface_name": "eth0", "offset": < offset >, "is_primary": true }
  EOF

result::

  {"netmask": "255.255.255.0", "updated": "2019-02-23T18:51:53.521628+00:00", "type": "Address", "prefix": "24", "ip_address": "192.168.13.22", "interface_name": "eth0", "network": "192.168.13.0", "sub_interface": null, "address_block": "/api/v1/Utilities/AddressBlock:1:", "is_primary": false, "offset": 22, "pointer": null, "gateway": "192.168.13.1", "created": "2019-02-23T18:51:53.521652+00:00", "networked": "/api/v1/Utilities/Networked:2:"}

VirtualBox
~~~~~~~~~~

Environment setup::

  export FBP="/api/v1/BluePrint/FoundationBluePrint:virtualbox-vm-base:"
  export FMDL="/api/v1/VirtualBox/VirtualBoxFoundation"
  export FDATA=', "virtualbox_complex": "/api/v1/VirtualBox/VirtualBoxComplex:demovbox:"'

First create the VirtualBox Complex, replace the `< username >` and `< password >`
with either your username and password for the machine with vbox running on it,
or if you ran the vboxmanage command to disable the auth library, you can leave
the username and password a few random alpha letters::

  cat << EOF | curl "${COPS[@]}" --data @- -X CREATE $CHOST/api/v1/VirtualBox/VirtualBoxComplex
  { "site": "$SITE", "name": "demovbox", "virtualbox_username": "< username >", "virtualbox_password": "< password >", "description": "Demo VirtualBox Host/Complex" }
  EOF

result::

  {"description": "Demo VirtualBox Host/Complex", "updated": "2019-03-05T03:29:33.401162+00:00", "site": "/api/v1/Site/Site:site1:", "built_percentage": 90, "virtualbox_password": "asdf", "name": "demovbox", "virtualbox_username": "asdf", "state": "planned", "created": "2019-03-05T03:29:33.401328+00:00", "members": [], "type": "VirtualBox"}

Now we add the structure host we manually created as a member of the complex,
replace `< structure id >` with the id from the manul host structure from above::

  cat << EOF | curl "${COPS[@]}" --data @- -X CREATE $CHOST/api/v1/Building/ComplexStructure
  { "complex": "/api/v1/Building/Complex:demovbox:", "structure": "/api/v1/Building/Structure:< structure id>:" }
  EOF

result::

  {"complex": "/api/v1/Building/Complex:demovbox:", "structure": "/api/v1/Building/Structure:2:", "created": "2019-02-20T04:55:31.730431+00:00", "updated": "2019-02-20T04:55:31.730357+00:00"}

now to set the ip address, this is the ip address of virtualbox the host.
This is the same ip that we passed to vboxwebsrv, which is offset 1 of the internal
network we created, once again replace `< structure id >`::

  cat << EOF | curl "${COPS[@]}" --data @- -X CREATE $CHOST/api/v1/Utilities/Address
  { "networked": "/api/v1/Utilities/Networked:< structure id >:", "address_block": "$ADRBLK", "interface_name": "eth0", "offset": 1, "is_primary": true }
  EOF

result::

  {"netmask": "255.255.255.0", "updated": "2019-02-23T18:51:53.521628+00:00", "type": "Address", "prefix": "24", "ip_address": "192.168.13.22", "interface_name": "eth0", "network": "192.168.13.0", "sub_interface": null, "address_block": "/api/v1/Utilities/AddressBlock:1:", "is_primary": false, "offset": 22, "pointer": null, "gateway": "192.168.13.1", "created": "2019-02-23T18:51:53.521652+00:00", "networked": "/api/v1/Utilities/Networked:2:"}

Contractor is now running, now let's configure it to make a VM.

Next Steps
~~~~~~~~~~
:doc:`create_vm`
