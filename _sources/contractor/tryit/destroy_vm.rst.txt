.. highlight:: bash

Removing the VM(s)
------------------

We can either Delete the VMs with contractorcli::

  contractorcli structure job do-destroy < structure id >
  contractorcli foundation job do-destroy < locator >

wait for those jobs to complete, you can check on them with::

  contractorcli structure job id < structure id >
  contractorcli foundation job id < locator >

and finally::

  contractorcli structure delete < structure id >
  contractorcli foundation delete < locator >

Now the VM is no longer in virtualbox/vcenter nor contractor.

or with the `boss` command on the contractor VM::

  /usr/lib/contractor/util/boss -s <structure id> --do-destroy
  /usr/lib/contractor/util/boss -f <locator> --do-destroy --wait
  /usr/lib/contractor/util/boss -s <structure id> --delete
  /usr/lib/contractor/util/boss -f <locator> --delete

The `boss` command can also trigger jobs, and set the status of foundations and
structures (ie: marking a Foundation or Structure as built, which contractorcli can not do).  See::

  /usr/lib/contractor/util/boss --help

for more info.

Next Steps
----------

:doc:`docker`
