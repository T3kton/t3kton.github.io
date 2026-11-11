.. highlight:: bash

Setup Bare-metal
----------------

.. raw:: html

    <div style="position: relative; padding-bottom: 56.25%; height: 0; overflow: hidden; max-width: 100%; height: auto;">
        <iframe src="https://www.youtube.com/embed/S2eAo1pLzPQ" frameborder="0" allowfullscreen style="position: absolute; top: 0; left: 0; width: 100%; height: 100%;"></iframe>
    </div>

.. note:: The video shows the earlier version of these steps using curl. The steps below do the same thing with contractorcli.

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
large switch/router with blades and/or port split outs.  Keep that link name
handy, we use it when we create the interface below.

When we create the Foundation, you will need to pick the type for your machine.
If you are installing to an IPMI Device, replace the username, password with the
username and password to access the ipmi interface.  The ip will be set by the bootstrap
PXE.  Eventually bootstrap will set the username and password as well.  For now, I
would recommend use the manifacture's default username and password here.  Use the
`-o` flag to set the console (SOL) port if it is not `console`, ie: `ttyS1`.

For AMT, replace the username, password and ip.  The default username is 'admin'
in thoes cases where you do not know what it is.  The Bootstrap PXE profile can not
curently re-configure the username, password nor ip address, so you will need to do
this manually.

Now to load up our ESX host into contractor. First we create the Foundation of
our host.  For IPMI::

  contractorcli foundation ipmi create -s site1 -l esx01 -p test -b ipmi-base -u "< Username >" -a "< Password >" -i "< ip of IPMI interface >"

or for AMT::

  contractorcli foundation amt create -s site1 -l esx01 -p test -b amt-base -u "< Username >" -a "< Password >" -i "< ip of AMT interface >"

create the interface, replace `< network id >` with the Id of the Network we created in :doc:`installing`,
and `< link name >` with the link name from above::

  contractorcli foundation interface create esx01 -n vmnic0 -y eth0 -t < network id > -p -l "< link name >"

Now to create the structure, using the ESX blueprint::

  contractorcli structure create -s site1 -f esx01 -o esx01 -b vmware-esx-base

once again take node of the structure id.  Now we assign and ip address, we are going
to set it at offset 30 which will result in 10.0.0.30.  Replace
`< structure id >` with the structure id from the previous call, and `< addressblock id >` with the Id of the AddressBlock::

  contractorcli structure address add < structure id > -a < addressblock id > -n vmnic0 -o 30 -p

And finally, create the create jobs.  Replace the structure id as you did for the address
creation::

  contractorcli foundation job do-create esx01
  contractorcli structure job do-create < structure id >

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
