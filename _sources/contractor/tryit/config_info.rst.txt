Accessing Configuration Information
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Contractor provides three configuration urls for a target.  The first two depend on
what the target is set to PXE boot to, the third is all the configuration information
for that target in JSON format.

ssh into one of the VMs, this will show what it is like from testvm02::

  ssh root@testvm02

First the pxe script, this script is downloaded and run but the iPXE boot loader
that the target VM was told to download from the dhcp server::

  curl http://contractor/config/boot_script/

which will output::

  #!ipxe

  echo Booting form Primary Boot Disk
  sanboot --no-describe --drive 0x80 || echo Primary Boot Disk is not Bootable

The VM is current set to the `normal-boot` pxe.  That script tells it to boot to the
first harddrive.

Next the pxe_template::

  curl http://contractor/config/pxe_template/

output::

  # Normal Boot

once again, with this VM having been set to `normal-boot`, the pxe template is
just a comment at the top.  The pxe_template is stored as a Jinja2 template that
is combined with the configuration information and served out to the target.
This is the URL that is used for the Kickstart and/or Pressed files for the CentOS
and Debian installers.  The source for the CentOS and Ubuntu boot_scripts and
pxe_templates are at https://github.com/T3kton/resources/blob/master/os-bases/centos/usr/lib/contractor/resources/centos.toml
and https://github.com/T3kton/resources/blob/master/os-bases/ubuntu/usr/lib/contractor/resources/ubuntu.toml
those are then packaged during when you built the resources, and installed to
/usr/lib/contractor/resource/ when the resource package was installed.

The third url is::

  curl http://contractor/config/config/

output::

  {"mirror_server": "mirror.centos.org", "memory_size": 2048, "_foundation_locator": "testvm02", "_foundation_id": "testvm02", "__pxe_location": "http://static/pxe/", "azure_image": {"sku": "7.6", "version": "latest", "publisher": "OpenLogic", "offer": "CentOS"}, "dns_search": ["site1.test", "test"], "_primary_interface": "eth0", "root_password_hash": "$6$rootroot$oLo.loyMV45VA7/0sKV5JH/xBAXiq/igL4hQrGz3yd9XUavmC82tZm1lxW2N.5eLxQUlqp53wXKRzifZApP0/1", "__last_modified": "2019-10-28T15:31:07.915815+00:00", "_virtualbox_uuid": "270af40c-33c4-466e-a874-25034757eabb", "mirror_proxy": "http://10.0.0.10:3128/", "__contractor_host": "http://contractor/", "_structure_id": 4, "dns_servers": ["10.0.0.10"], "vcenter_guest_id": "centos7_64Guest", "_structure_config_uuid": "eff1ddb6-47b5-4e07-8120-a1c14e7ee94a", "installer_pxe": "centos-7", "_site": "site1", "_interface_map": {"eth0": {"network": "vboxnet0", "name": "eth0", "mac": "08:00:27:f1:c8:60", "physical_location": "eth0", "address_list": [{"subnet": "10.0.0.0", "gateway": null, "vlan": 0, "tagged": false, "netmask": "255.255.255.0", "sub_interface": null, "mtu": 1500, "auto": true, "primary": true, "prefix": 24, "address": "10.0.0.124"}]}}, "_fqdn": "testvm02.site1.test", "_provisioning_interface_mac": "08:00:27:f1:c8:60", "_domain_name": "site1.test", "__timestamp": "2019-10-28T15:45:12.941159+00:00", "distro_version": "7", "_provisioning_address": {"subnet": "10.0.0.0", "gateway": null, "netmask": "255.255.255.0", "sub_interface": null, "mtu": 1500, "auto": true, "primary": true, "prefix": 24, "address": "10.0.0.124"}, "_foundation_interface_list": [{"network": "vboxnet0", "name": "eth0", "mac": "08:00:27:f1:c8:60", "physical_location": "eth0", "address_list": [{"subnet": "10.0.0.0", "gateway": null, "vlan": 0, "tagged": false, "netmask": "255.255.255.0", "sub_interface": null, "mtu": 1500, "auto": true, "primary": true, "prefix": 24, "address": "10.0.0.124"}]}], "ntp_servers": ["ntp.ubuntu.com"], "virtualbox_guest_type": "RedHat_64", "_structure_state": "planned", "_foundation_state": "built", "_primary_address": {"subnet": "10.0.0.0", "gateway": null, "netmask": "255.255.255.0", "sub_interface": null, "mtu": 1500, "auto": true, "primary": true, "prefix": 24, "address": "10.0.0.124"}, "_hostname": "testvm02", "__pxe_template_location": "http://contractor/config/pxe_template/c/eff1ddb6-47b5-4e07-8120-a1c14e7ee94a", "_virtualbox_complex": "demovbox", "_foundation_type": "VirtualBox", "_blueprint": "centos-7-base", "_primary_interface_mac": "08:00:27:f1:c8:60", "domain_name": "site1.test", "swap_size": 512, "_foundation_class_list": ["VM", "VirtualBox"], "distro": "centos", "_provisioning_interface": "eth0"}

This url can be used by what ever scripts/CMS as a source of configuration
information.  See the documentation at :doc:`../ConfigurationValues` for more
information on how these values are compiled.  One value to point out here is
`_structure_config_uuid`, this value is set when the structure record is created
or when the structure is destroyed.  This way if there is a stale copy of the
structure (old VM snapshot, or a VM that didn't get cleaned up properly, etc)
comes on-line, it (or some other monitoring system) can detect that it is no
longer current and take action.

Contractor uses the source ip address of this URL requests to determine which
target's information to return.  You can also use the structure id, foundation
locater or config uuid, to tell contractor which configuration to return.

by config uuid::

  curl http://contractor/config/config/c/< _structure_config_uuid >

example::

  curl http://contractor/config/config/c/eff1ddb6-47b5-4e07-8120-a1c14e7ee94a

by structure id::

  curl http://contractor/config/config/s/< structure id >

example::

  curl http://contractor/config/config/s/4

by foundation locator::

  curl http://contractor/config/config/f/< foundation locator >

example::

  curl http://contractor/config/config/f/testvm02

or by ip address::

  curl http://contractor/config/config/a/< ip address >

example::

  curl http://contractor/config/config/a/10.0.0.124

Next Steps
~~~~~~~~~~
:doc:`destroy_vm`
