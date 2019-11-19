Setup Bare-metal
----------------

.. raw:: html

    <div style="position: relative; padding-bottom: 56.25%; height: 0; overflow: hidden; max-width: 100%; height: auto;">
        <iframe src="https://www.youtube.com/embed/S2eAo1pLzPQ" frameborder="0" allowfullscreen style="position: absolute; top: 0; left: 0; width: 100%; height: 100%;"></iframe>
    </div>

We are going to install ESX on our IPMI/AMT device.  First we need vmware blueprints::

  sudo respkg -i contractor-vmware-base_*.respkg

Next we need to extract is ESXi installer.  First you need to get the ESXi installer .iso,
it will be named something like `VMware-VMvisor-Installer-6.7.0.update01-10302608.x86_64.iso`.
You can get it from VMware's web site, by signing up for the esx/vcenter demo.  To
extract the iso execute::

  sudo /usr/lib/contractor/resources/esxExtractISO <path to .iso> /var/www/static

Before we can install anything, we first need to figure out how we are going to identify
our hardware.  There are a few options for this.  One way is to identify our hardware
by the LLDP information.  LLDP is something a switch can make visible on it's ports.  There
are two ways to identify via LLDP.  The first is '<name>-<slot>-<port>-<subport>', the
second is '<switch mac>-<slot>-<port>-<subport>'.  In this example, the machine is
pluggined into a Unifi swich named 'DevSwitch' in port 7, so the 'link_name' is
'DevSwitch-0-7-0'.  Generally the slot and support are 0, unless you are using a
large switch/router with blades and/or port split outs.::

  export IFIDENT=', "link_name": "<link name>"'

If you are installing to an IPMI Device, replace the username, password with the
username and password to access the ipmi interface.  The ip will be set by the bootstrap
PXE.  Eventually bootstrap will set the username and password as well.  For now, I
would recommend use the manifacture's default username and password here.::

  export FBP="/api/v1/BluePrint/FoundationBluePrint:ipmi-base:"
  export FMDL="/api/v1/IPMI/IPMIFoundation"
  export FDATA=', "ipmi_username": "< Username >", "ipmi_password": "< Password >", "ipmi_ip_address": "< ip of IPMI interface >"'

or AMT, replace the username, password and ip.  The default username is 'admin'
in thoes cases where you do not know what it is.  The Bootstrap PXE profile can not
curently re-configure the username, password nor ip address, so you will need to do
this manually.::

  export FBP="/api/v1/BluePrint/FoundationBluePrint:amt-base:"
  export FMDL="/api/v1/AMT/AMTFoundation"
  export FDATA=', "amt_username": "< Username >", "amt_password": "< Password >", "amt_ip_address": "< ip of AMT interface >"'

Now to load up our ESX host into contractor. First we create the Foundation of
our host::

  cat << EOF | curl "${COPS[@]}" --data @- -X CREATE $CHOST/$FMDL
  { "site": "$SITE", "locator": "esx01", "blueprint": "$FBP" $FDATA }
  EOF

result::

  {"locator": "esx01", "site": "/api/v1/Site/Site:site1:", "blueprint": "/api/v1/BluePrint/FoundationBluePrint:amt-base:", "id_map": null, "located_at": null, "built_at": null, "updated": "2019-11-05T04:37:29.855004+00:00", "created": "2019-11-05T04:37:29.855021+00:00", "amt_username": "admin", "amt_password": "asdf", "amt_ip_address": "10.0.0.90", "state": "planned", "type": "AMT", "class_list": "['Physical', 'AMT']"}

create the interface::

  cat << EOF | curl "${COPS[@]}" --data @- -X CREATE $CHOST/api/v1/Utilities/RealNetworkInterface
  { "foundation": "/api/v1/Building/Foundation:esx01:", "name": "vmnic0", "physical_location": "eth0", "network": "$NETWORK", "is_provisioning": true $IFIDENT }
  EOF

result::

  {"name": "vmnic0", "is_provisioning": true, "network": "/api/v1/Utilities/Network:2:", "updated": "2019-11-05T04:39:27.042076+00:00", "created": "2019-11-05T04:39:27.042113+00:00", "mac": null, "foundation": "/api/v1/Building/Foundation:esx01:", "physical_location": "eth0", "link_name": null, "pxe": null}

Now to create the structure, using the ESX blueprint::

  cat << EOF | curl -i "${COPS[@]}" --data @- -X CREATE $CHOST/api/v1/Building/Structure
  { "site": "$SITE", "foundation": "/api/v1/Building/Foundation:esx01:", "hostname": "esx01", "blueprint": "/api/v1/BluePrint/StructureBluePrint:vmware-esx-base:" }
  EOF

result::

  {"hostname": "esx01", "site": "/api/v1/Site/Site:site1:", "blueprint": "/api/v1/BluePrint/StructureBluePrint:vmware-esx-base:", "foundation": "/api/v1/Building/Foundation:esx01:", "config_uuid": "bf2ce43e-76c1-4b58-b825-dc6e91521d8c", "config_values": {}, "built_at": null, "updated": "2019-11-05T04:41:06.904005+00:00", "created": "2019-11-05T04:41:06.904020+00:00", "state": "planned"}

once again take node of the structure id.  Now we assign and ip address, we are going
to set it at offset 30 which will result in 10.0.0.30.  Replace
`< structure id >` with the structure id from the previous call::

  cat << EOF | curl "${COPS[@]}" --data @- -X CREATE $CHOST/api/v1/Utilities/Address
  { "networked": "/api/v1/Utilities/Networked:< structure id >:", "address_block": "$ADRBLK", "interface_name": "vmnic0", "offset": 30, "is_primary": true }
  EOF

result::

  {"address_block": "/api/v1/Utilities/AddressBlock:1:", "offset": 30, "updated": "2019-11-05T04:44:05.444313+00:00", "created": "2019-11-05T04:44:05.444336+00:00", "networked": "/api/v1/Utilities/Networked:2:", "interface_name": "vmnic0", "sub_interface": null, "pointer": null, "is_primary": true, "type": "Address", "ip_address": "10.0.0.30", "subnet": "10.0.0.0", "netmask": "255.255.255.0", "prefix": "24", "gateway": null}

And finally, create the create jobs.  Replace the structure id as you did for the address
creation::

  curl "${COPS[@]}" -X CALL "${CHOST}/api/v1/Building/Foundation:esx01:(doCreate)"
  curl "${COPS[@]}" -X CALL "${CHOST}/api/v1/Building/Structure:< structure id >:(doCreate)"

Now power up the machine, it will PXE boot the bootstrap.  After that loads it will
send it's information to Contractor, which in turn will reply back with the configuration
for esx01.  After the IPMI(if being used) is configured, it will power off.  After a few
seconds, the foundation job will run.  Then the Structure job will run and install ESX.
Now that you have an ESX server, let's install some VMs to it.

NOTE: Contractor has allready set up the internal network on the ESX server, you should
be able to continue on with the next step of setting up the complex host and install away.

Next Steps
~~~~~~~~~~

Skip past the Place Holder host, you use the stucture id from this host for the
vcenter host.  You also skip the final step in the VCenter host setup of assigning and
ip address, we have allready done that. Use the value `ha-datacenter` for the datacenter
and `esx01.site1.test` for the cluster in the next section.  The username is `root` the password is `root`.

:doc:`complex`
