Accessing Configuration Information
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Contractor provides three configuration urls for a target.  The first two depend on
what the target is set to PXE boot to, the third is all the configuration information
for that target in JSON format.

ssh into one of the VMs, this will show what it is like from testvm02::

  ssh root@testvm02

First the pxe script, this script is downloaded and run but the iPXE boot loader
that the target VM was told to download from the dhcp server.::

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

  {"installer_pxe": "centos-7", "__pxe_template_location": "http://contractor/config/pxe_template/", "_structure_config_uuid": "118e0e44-457e-47df-b8c0-d157d5dde1b4", "mirror_server": "mirror.centos.org", "_blueprint": "centos-7-base", "__timestamp": "2019-03-11T14:32:27.909856+00:00", "_foundation_state": "built", "domain_name": "site1.test", "dns_search": ["site1.test", "test"], "_structure_state": "built", "__pxe_location": "http://static/pxe/", "distro": "centos", "_hostname": "testvm02", "_foundation_class_list": ["VM", "VCenter"], "dns_servers": ["10.0.0.10"], "memory_size": 2048, "_foundation_type": "VCenter", "_provisioning_interface": "eth0", "_vcenter_complex": "demovcenter", "_interface_map": {"eth0": {"physical_location": "eth0", "name": "eth0", "mac": "00:50:56:03:1e:6d", "address_list": [{"vlan": null, "address": "10.0.0.123", "prefix": 24, "netmask": "255.255.255.0", "primary": true, "sub_interface": null, "network": "10.0.0.0", "tagged": false, "gateway": null, "auto": true, "mtu": 1500}]}}, "_foundation_locator": "testvm02", "_vcenter_uuid": "52545577-0025-e8d7-1915-bd64585f47c1", "_vcenter_cluster": "localhost.", "_site": "site1", "ntp_servers": ["ntp.ubuntu.com"], "distro_version": "7", "_fqdn": "testvm02.site1.test", "mirror_proxy": "http://10.0.0.10:3128/", "_foundation_interface_list": [{"physical_location": "eth0", "name": "eth0", "mac": "00:50:56:03:1e:6d", "address_list": [{"vlan": null, "address": "10.0.0.123", "prefix": 24, "netmask": "255.255.255.0", "primary": true, "sub_interface": null, "network": "10.0.0.0", "tagged": false, "gateway": null, "auto": true, "mtu": 1500}]}], "__contractor_host": "http://contractor/", "_foundation_id": "testvm02", "vcenter_guest_id": "rhel7_64Guest", "swap_size": 512, "_structure_id": 4, "__last_modified": "2019-03-11T14:01:18.090983+00:00", "_provisioning_interface_mac": "00:50:56:03:1e:6d", "_vcenter_datacenter": "ha-datacenter", "virtualbox_guest_type": "RedHat_64", "root_pass": "$6$rootroot$oLo.loyMV45VA7/0sKV5JH/xBAXiq/igL4hQrGz3yd9XUavmC82tZm1lxW2N.5eLxQUlqp53wXKRzifZApP0/1"}

This url can be used by what ever scripts/CMS as a source of configuration
information.  See the documentation at :doc:`ConfigurationValues` for more
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

  curl http://contractor/config/config/c/118e0e44-457e-47df-b8c0-d157d5dde1b4

by structure id::

  curl http://contractor/config/config/s/4

by foundation locator::

  curl http://contractor/config/config/f/testvm02

one way for a target to detect if it is slit good and in cases when the ip address
might change, is to request it's config by the uuid.

Next Steps
~~~~~~~~~~
:doc:`TryIt_destroy_vm`
