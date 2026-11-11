.. highlight:: bash

Setting up VM Host
------------------

.. raw:: html

    <div style="position: relative; padding-bottom: 56.25%; height: 0; overflow: hidden; max-width: 100%; height: auto;">
        <iframe src="https://www.youtube.com/embed/76UKWFLXB_U" frameborder="0" allowfullscreen style="position: absolute; top: 0; left: 0; width: 100%; height: 100%;"></iframe>
    </div>

.. note:: The video shows the earlier version of these steps using curl. The steps below do the same thing with contractorcli.

Place Holder Host
~~~~~~~~~~~~~~~~~

First we need to make a pre-built entry on a manual foundation to represent the
virtualbox/vcenter/esx host, first creating the foundation::

  contractorcli foundation manual create -s site1 -l host -b manual-foundation-base

create the interface, replace `< network id >` with the Id of the Network we created
in :doc:`installing`::

  contractorcli foundation interface create host -n eth0 -y eth0 -t < network id > -p

Now to create the structure::

  contractorcli structure create -s site1 -f host -o host -b manual-structure-base

Take note of the new structures id.  You might want to write it done somewhere,
we will be using it a few times.

now we need to tell contractor it is allready built so it dosen't try to build it
again.  contractorcli can not change the state of targets, so we will use a command
line utility, this command needs to be run on the
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

Now to create the complex for the foundation blueprint we will be using.

VCenter
~~~~~~~

First create the VCenter Complex, replace `< datacenter >` with the name of
the VCenter datacenter to put the VMs in, if using ESX directly put 'ha-datacenter',
replace `< cluster >` with the name of the cluster to put the vms in, if using
ESX put the fqdn of the ESX server (if you only specified a hostname it will be
<hostname> + '.' ), if it's still default it will be 'localhost.'.
Replace `< structure id >`
with the strudture id from the host creation above, `< username >` and `< password >`
replace with the ESX/VCenter username and password.

Technically if you are using VCenter, you should create another structure
so Contractor knows the hosts of the VCenter cluster, however, for the sake of
simplicity, we will just add the ESX Host/VCenter cluster we just added as the host
of the VCenterCluster as it's only member (`-m`), once again the `< structure id >` is
the id of the manual structure we have been using so far::

  contractorcli complex vcenter create -s site1 -l demovcenter -d "Demo VCenter/ESX Host/Complex" -a "< datacenter >" -c "< cluster >" -o < structure id > -m < structure id > -u "< username >" -p "< password >"

now to set the ip address of the vcenter/esx host. This ip will be used by
subcontractor to communicate with VCenter to manipulate vms, and will need to be
route-able from the contractor vm (where subcontractor is installed), this assumes
that address is in the address space of the contractor vm, specifically the network
that setupWizard created.  Change `< offset >`
to the offset of the VCenter/ESX host, if the VCenter/ESX host is not in the same
network that the contractor was created in, (and thus the same network that was
setup bu the setup wizzard), you will need to create another AddressBlock and update
the following call to use that AddressBlock in the following.  Replace structure id
with the id from the structure creation step, and `< addressblock id >` with the Id of the
AddressBlock::

  contractorcli structure address add < structure id > -a < addressblock id > -n eth0 -o < offset > -p

From here on the foundation type and blueprint for the VMs are `vcenter` and `vcenter-vm-base`, with the
complex `demovcenter`.

VirtualBox
~~~~~~~~~~

First create the VirtualBox Complex, replace the `< username >` and `< password >`
with either your username and password for the machine with vbox running on it,
or if you ran the vboxmanage command to disable the auth library, you can leave
the username and password a few random alpha letters.  The host structure we
manually created is added as the member of the complex, replace `< structure id >`
with the id from the manual host structure from above::

  contractorcli complex virtualbox create -s site1 -l demovbox -d "Demo VirtualBox Host/Complex" -u "< username >" -p "< password >" -m < structure id >

now to set the ip address, this is the ip address of virtualbox the host.
This is the same ip that we passed to vboxwebsrv, which is offset 1 of the internal
network we created, once again replace `< structure id >`::

  contractorcli structure address add < structure id > -a < addressblock id > -n eth0 -o 1 -p

From here on the foundation type and blueprint for the VMs are `virtualbox` and `virtualbox-vm-base`, with the
complex `demovbox`.

Contractor is now running, now let's configure it to make a VM.

Next Steps
~~~~~~~~~~

Next up we will create and destroy a VM
:doc:`create_vm`

If you want to skip the demo VM creation and skip right to the docker:
:doc:`docker`
