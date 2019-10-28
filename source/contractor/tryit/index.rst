Give it a Try
==============

Contents:

.. toctree::
  :maxdepth: 2

  installing
  packaged
  source
  setup_amt
  setup_ipmi
  setup_vcenter
  setup_virtualbox
  complex
  install_baremetal
  create_vm
  config_info
  destroy_vm



*Note*: Contractor is made to solve complex problems, for the most part it presents
a much less complex interface to you.  That being said, there is a bit of a hurdle
to get it up and running, depending on what you are trying to automate.  So, buckle
in, this is going to be a lot of fun.

This demo will require in a VM in a private /24 network that can create and destroy
other VMs in that network.  You can use either VCenter or VirtualBox.  After the
Contractor VM is up and running, you can install more blueprints and plugins to do
docker or other foundations.  The requirement for the private network comes primarally from
the setupWizard's default configuration, if you feel comfortable with modifying
the setupWizard and the Apache Configurations, you can use blueprints and plugins
for hosted providers such as AWS and Azure.

NOTE: setupWizard is going to re-write some bind config files, so don't edit them
until after the install is complete.

If you are not failure with how Contractor handles Networking, you will probably
want to take a look at the overview on :doc:`../Networking`.
