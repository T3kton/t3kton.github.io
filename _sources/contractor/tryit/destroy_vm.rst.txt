Removing the VM(s)
~~~~~~~~~~~~~~~~~~

We can either Delete the VMs with the `boss` command::

  /usr/lib/contractor/util/boss -s <structure id> --do-destroy
  /usr/lib/contractor/util/boss -f <locator> --do-destroy --wait
  /usr/lib/contractor/util/boss -s <structure id> --delete
  /usr/lib/contractor/util/boss -f <locator> --delete

or via the API::

  curl "${COPS[@]}" -X CALL "${CHOST}/api/v1/Building/Structure:< structure id >:(doDestroy)"
  curl "${COPS[@]}" -X CALL "${CHOST}/api/v1/Building/Foundation:< locator >:(doDestroy)"

wait for that job to complete, and finally::

  curl "${COPS[@]}" -X DELETE "${CHOST}/api/v1/Building/Structure:< structure id >:"
  curl "${COPS[@]}" -X DELETE "${CHOST}/api/v1/Building/Foundation:< locator >:"

Now the VM is no longer in virtualbox/vcenter nor contractor.

The `boss` command can also trigger jobs, and set the status of foundations and
structures.  See::

  /usr/lib/contractor/util/boss --help

for more info.
