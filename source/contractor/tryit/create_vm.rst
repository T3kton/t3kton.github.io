.. highlight:: bash

Creating a VM (Ubuntu)
~~~~~~~~~~~~~~~~~~~~~~

.. raw:: html

    <div style="position: relative; padding-bottom: 56.25%; height: 0; overflow: hidden; max-width: 100%; height: auto;">
        <iframe src="https://www.youtube.com/embed/6NyUwhYWN48" frameborder="0" allowfullscreen style="position: absolute; top: 0; left: 0; width: 100%; height: 100%;"></iframe>
    </div>

.. note:: The video shows the earlier version of these steps using curl. The steps below do the same thing with contractorcli.

First we need to load the ubuntu blueprints::

  sudo respkg -i contractor-ubuntu-base_*.respkg

Now we create the Foundation of the VM to be created.  Use the foundation type
that matches where you are building VMs, `virtualbox`, `vcenter`, `proxmox`, or
`libvirt`, and the foundation blueprint and complex we set up in the last step.
For VirtualBox, using the complex `demovbox`::

  contractorcli foundation virtualbox create -s site1 -l testvm01 -b virtualbox-vm-base -x demovbox

For VCenter use `foundation vcenter create` with `-b vcenter-vm-base -x demovcenter`.
Run `contractorcli foundation types` to see all of the supported types.

create the interface, replace `< network id >` with the Id of the Network we created
in :doc:`installing`::

  contractorcli foundation interface create testvm01 -n eth0 -y eth0 -t < network id > -p

Now we will create a VM with the Ubuntu Noble blueprint::

  contractorcli structure create -s site1 -f testvm01 -o testvm01 -b ubuntu-noble-base

take note of the structure id.  Now we assign an ip address, we will let contractor
pick, using the `next` helper.  Replace `< structure id >` with the structure id from
the previous call, and `< addressblock id >` with the Id of the AddressBlock the
Network is linked to::

  contractorcli structure address next < structure id > -a < addressblock id > -n eth0 -p

Contractor will not auto-start the create (nor destroy) jobs.  So we need to add two
jobs, one to create the Foundation and one to create the Structure::

  contractorcli foundation job do-create testvm01
  contractorcli structure job do-create < structure id >

Now to see it get built.  Pull up the `http://<contractor ip>`
in a web browser if you don't have it open allready, go to the `Job Log` should see an
entry saying that the foundation build has started.  Goto the `Jobs` should see a Foundation
or Structure Job there.  The Foundation Job won't last long.  In the top right of the
page is a refresh and auto refresh buttons.  You can also follow along with contractorcli::

  contractorcli foundation joblog testvm01
  contractorcli structure job id < structure id >

After the Foundation job completes, a Structure job will auto start, after it completes
your VM should be up and sshable, however the default for ubuntu is to disallow sshing
as root, but we can show the ssh service is listening::

  nc -vz testvm01 22

should output something like::

  Connection to testvm01 22 port [tcp/ssh] succeeded!

If you pull up the console, the default root password is "root".

After you have verified that it is there, logout of the test vm and kick off a
job to clean it up::

  contractorcli foundation job do-destroy testvm01
  contractorcli structure job do-destroy < structure id >

After those jobs have completed you can call the do-create again to rebuild them.

Creating a VM (CentOS)
~~~~~~~~~~~~~~~~~~~~~~

Ok, let's create a centos VM now, is't all the same as the ubuntu VM except the
blueprint we choose.

Load the centos Blueprints::

  sudo respkg -i contractor-centos-base_*.respkg

Foundation, and its interface::

  contractorcli foundation virtualbox create -s site1 -l testvm02 -b virtualbox-vm-base -x demovbox
  contractorcli foundation interface create testvm02 -n eth0 -y eth0 -t < network id > -p

Now we will create a VM with the CentOS7 blueprint::

  contractorcli structure create -s site1 -f testvm02 -o testvm02 -b centos-7-base

and assign the ip address, make sure to use the structure id from the testvm02 structure::

  contractorcli structure address next < structure id > -a < addressblock id > -n eth0 -p

Once again create the create jobs::

  contractorcli foundation job do-create testvm02
  contractorcli structure job do-create < structure id >

Again the jobs should be running to create the CentOS VM.  When it is done, ssh in::

  ssh root@testvm02

Once again the root password is "root", go a head and play around with it for a bit.
Make sure to try deconfiguring both VMs at the same time so you can see Contractor
do more than one thing at a time.

Next Steps
~~~~~~~~~~
:doc:`config_info`
