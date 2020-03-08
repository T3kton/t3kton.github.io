contractorcli
=============

contractorcli is a client for working with Contractor, you can get a pre-built binary
from https://github.com/T3kton/contractorcli/releases.

Configuration
-------------

contractorcli's config file is stored at ~/.contractorcli.ini.  Here is an example
file::

  [contractor]
  host: http://192.168.200.10
  username: root
  password: root


Usage
-----

For most options you can use the flag `-j` or `--json` to output the results as
JSON::

  $ ./contractorcli site config site1
  ntp_servers:	[contractor]
  dns_search:	[site1.test test]
  dns_servers:	[10.0.0.10]
  domain_name:	site1.test
  mirror_proxy:	http://10.0.0.10:3128/

  $ ./contractorcli -j site config site1
  {
   "dns_search": [
    "site1.test",
    "test"
   ],
   "dns_servers": [
    "10.0.0.10"
   ],
   "domain_name": "site1.test",
   "mirror_proxy": "http://10.0.0.10:3128/",
   "ntp_servers": [
    "contractor"
   ]
  }

Most commands can also be used in the interactive mode, for example::

  $ ./contractorcli structure list
  Id	Site	Hostname	Foundation	Blueprint	Created	Updated
  1	site1	contractor	contractor	manual-structure-base	2020-01-07 00:42:58.932884 +0000 +0000	2020-01-07 00:42:59.111802 +0000 +0000
  2	site1	esx01	esx01	vmware-esx-base	2020-01-07 00:46:55.566979 +0000 +0000	2020-02-26 16:22:26.463778 +0000 +0000

  $ ./contractorcli shell
  contractor> structure list
  Id	Site	Hostname	Foundation	Blueprint	Created	Updated
  1	site1	contractor	contractor	manual-structure-base	2020-01-07 00:42:58.932884 +0000 +0000	2020-01-07 00:42:59.111802 +0000 +0000
  2	site1	esx01	esx01	vmware-esx-base	2020-01-07 00:46:55.566979 +0000 +0000	2020-02-26 16:22:26.463778 +0000 +0000
  contractor>


Version
~~~~~~~

::

  $ ./contractorcli version
  contractorcli
    Version:	0.2
    Commit:	df562afc8f68dba32689c4981ad4973b7a57783c

Sites
~~~~~

For Sites, the name is also the id

List available sites::

  $ ./contractorcli site list
  Id	Name	Description	Created	Updated
  site1	site1	Initial Site "site1"	2020-01-07 00:42:58.664308 +0000 +0000	2020-02-25 05:53:39.14986 +0000 +0000

Get a Site::

  $ ./contractorcli site get site1
  Site:          site1
  Description:   Initial Site "site1"
  Parent:
  Zone:          site1
  Config Values: map[dns_search:[site1.test test] dns_servers:[10.0.0.10] domain_name:site1.test mirror_proxy:http://10.0.0.10:3128/ ntp_servers:[contractor]]
  Created:       2020-01-07 00:42:58.664308 +0000 +0000
  Updated:       2020-02-25 05:53:39.14986 +0000 +0000

Create a new Site::

  $ ./contractorcli site create -d "New Site" -n nsite

Update an Existing site::

  $ ./contractorcli site update nsite -d "New Description"

Delete a site::

  $ ./contractorcli site delete nsite

Get Effective/Full/Compiled configuration for a site::

  $ ./contractorcli site config site1 -f
  __pxe_location:	http://static/pxe/
  dns_search:	[site1.test test]
  dns_servers:	[10.0.0.10]
  domain_name:	site1.test
  ntp_servers:	[contractor]
  _site:	site1
  __timestamp:	2020-03-07T04:46:04.873917+00:00
  __pxe_template_location:	http://contractor/config/pxe_template/
  mirror_proxy:	http://10.0.0.10:3128/
  __last_modified:	2020-02-25T05:53:39.149860+00:00
  __contractor_host:	http://contractor/

Get the Configuration values for a site::

  $ ./contractorcli site config site1
  dns_servers:	[10.0.0.10]
  domain_name:	site1.test
  mirror_proxy:	http://10.0.0.10:3128/
  new:	value
  ntp_servers:	[contractor]
  dns_search:	[site1.test test]

Set/Add a new configuration value::

  $ ./contractorcli site config site1 -n new -v value
  dns_search:	[site1.test test]
  dns_servers:	[10.0.0.10]
  domain_name:	site1.test
  mirror_proxy:	http://10.0.0.10:3128/
  ntp_servers:	[contractor]
  new:	value

Delete/Remove configuration value::

  $ ./contractorcli site config site1 -d new
  dns_search:	[site1.test test]
  dns_servers:	[10.0.0.10]
  domain_name:	site1.test
  mirror_proxy:	http://10.0.0.10:3128/
  ntp_servers:	[contractor]

Structure
---------

For Structures the id is a number

NOTE: List, Get, Update, Create, Configuration sections are similar to Site

View Existing Job information (this is for structure 2)::

  $ ./contractorcli structure job 2 -i
  Site           /api/v1/Site/Site:site1:
  Structure      /api/v1/Building/Structure:2:
  State:         waiting
  Status:        []
  Progress:      0.0
  Message:
  Script Name:   destroy
  Can Start:     True
  Updated:       2020-03-01 06:29:21.829421 +0000 +0000
  Created:       2020-03-01 06:29:21.829439 +0000 +0000


Create a new Create(-c)/Destroy(-d) Job (this is for structure 1)::

  ./contractorcli structure job 1 -d
  job:	12

Show Job Status (this is for structure 1)::

  $ ./contractorcli structure job 1 -s
  Variables: map[config.__contractor_host:http://contractor/ config.__last_modified:2020-03-07 04:47:44.194113+00:00 config.__pxe_location:http://static/pxe/ config.__pxe_template_location:http://contractor/config/pxe_template/c/1005b8d0-cefa-4c3f-b221-02d5b5332212 config.__timestamp:2020-03-07 04:52:48.310913+00:00 config._blueprint:manual-structure-base config._domain_name:site1.test config._foundation_class_list:['Metal', 'VM', 'Container', 'Switch', 'Manual'] config._foundation_id:contractor config._foundation_id_map:None config._foundation_interface_list:[{'name': 'enp0s8', 'network': 'main', 'address_list': [{'address': '10.0.0.10', 'netmask': '255.255.255.0', 'prefix': 24, 'subnet': '10.0.0.0', 'gateway': None, 'auto': True, 'mtu': 1500, 'sub_interface': None, 'primary': True, 'vlan': 0, 'tagged': False}], 'mac': None, 'physical_location': 'enp0s8'}] config._foundation_locator:contractor config._foundation_state:built config._foundation_type:Manual config._fqdn:contractor.site1.test config._hostname:contractor config._interface_map:{'enp0s8': {'name': 'enp0s8', 'network': 'main', 'address_list': [{'address': '10.0.0.10', 'netmask': '255.255.255.0', 'prefix': 24, 'subnet': '10.0.0.0', 'gateway': None, 'auto': True, 'mtu': 1500, 'sub_interface': None, 'primary': True, 'vlan': 0, 'tagged': False}], 'mac': None, 'physical_location': 'enp0s8'}} config._primary_address:{'address': '10.0.0.10', 'netmask': '255.255.255.0', 'prefix': 24, 'subnet': '10.0.0.0', 'gateway': None, 'auto': True, 'mtu': 1500, 'sub_interface': None, 'primary': True} config._primary_interface:enp0s8 config._primary_interface_mac:None config._provisioning_address:{'address': '10.0.0.10', 'netmask': '255.255.255.0', 'prefix': 24, 'subnet': '10.0.0.0', 'gateway': None, 'auto': True, 'mtu': 1500, 'sub_interface': None, 'primary': True} config._provisioning_interface:enp0s8 config._provisioning_interface_mac:None config._site:site1 config._structure_config_uuid:1005b8d0-cefa-4c3f-b221-02d5b5332212 config._structure_id:1 config._structure_state:built config.dns_search:['site1.test', 'test'] config.dns_servers:['10.0.0.10'] config.domain_name:site1.test config.mirror_proxy:http://10.0.0.10:3128/ config.ntp_servers:['contractor'] foundation.blueprint:manual-foundation-base foundation.class:<class 'contractor.plugins.Manual.models.ManualFoundation'> foundation.foundation:ManualFoundation contractor foundation.id:contractor foundation.interface_list:[<RealNetworkInterface: RealNetworkInterface "enp0s8" mac "None">] foundation.locator:contractor foundation.provisioning_interface:RealNetworkInterface "enp0s8" mac "None" foundation.site:site1 foundation.type:Manual structure.hostname:contractor structure.id:1 structure.primary_interface:RealNetworkInterface "enp0s8" mac "None" structure.primary_ip:10.0.0.10 structure.provisioning_interface:RealNetworkInterface "enp0s8" mac "None" structure.provisioning_ip:10.0.0.10]
  Script State: []
  Script Line No: 0
  -- Script --
  # Uninstall Manual OS
  pause( msg='Resume When OS is Uninstalled' )

Foundation
----------

For Foundations the Locator is also the id

NOTE: List, Get sections are similar to Site
NOTE2: Job section is similar to Structure

List the foundation types that are supported by contractorcli and the contractor
instance it is configured to talk to::

  $ ./contractorcli foundation types
  type:	[docker manual virtualbox]

Get any type of foundation::

  $ ./contractorcli foundation get esx01
  Locator:       esx01
  Type:          AMT
  Site:          site1
  Blueprint:     amt-base
  Structure:     2
  Id Map:        {'hardware': {'dmi': {'BIOS Info': [{'Vendor': 'Intel Corporation', 'Version': 'MYBDWi5v.86A.0039.2017.1016.1545', 'Release Date': '10/16/2017', 'BIOS Revision': '5.6'}], 'System Info': [{'Manufacturer': '', 'Product Name': '', 'Version': '', 'Serial Number': '', 'UUID': '4917D980-B0E4-11E5-BF2D-94C69110F1DC', 'SKU Number': '', 'Family': ''}], 'Base Board Information': [{'Manufacturer': 'Intel Corporation', 'Product Name': 'NUC5i5MYBE', 'Version': 'H47797-208', 'Serial Number': 'GEMY72300148', 'Asset Tag': '', 'Type': 'Motherboard'}], 'Chassis Information': [{'Manufacturer': '', 'Type': 'Desktop', 'Version': '', 'Serial Number': '', 'Asset Tag': '', 'Boot-up State': 'Safe', 'Power Supply State': 'Safe', 'Thermal State': 'Safe', 'Height': '0', 'Number Of Power Cords': '1', 'SKU Number': 'To be filled by O.E.M.'}], 'OEM Strings': [{'String 1': 'To Be Filled By O.E.M.'}], 'System Configuration Options': [{'Option 1': 'To Be Filled By O.E.M.'}], 'Processor Information': [{'Socket Designation': 'SOCKET 0', 'Family': 'Core i5', 'Manufacturer': 'Intel(R) Corporation', 'ID': '0xbfebfbff000306d4', 'Version': 'Intel(R) Core(TM) i5-5300U CPU @ 2.30GHz', 'Status': 'Enabled', 'Serial Number': 'NULL', 'Asset Tag': 'To Be Filled By O.E.M', 'Part Number': 'To Be Filled By O.E.M', 'Core Count': '2', 'Core Enabled': '2', 'Thread Count': '4'}], 'Memory Device': [{'Size': 'No Module Installed', 'Set': 'None', 'Locator': 'SODIMM0', 'Bank Locator': 'CHANNEL A DIMM0', 'Type': 'Unknown', 'Speed': 'Unknown', 'Manufacturer': 'Not Specified', 'Serial Number': 'Not Specified', 'Asset Tag': 'Not Specified', 'Part Number': 'Not Specified'}, {'Size': '16384 MB', 'Set': 'None', 'Locator': 'SODIMM1', 'Bank Locator': 'CHANNEL B DIMM0', 'Type': 'DDR3', 'Speed': '1600 MHz', 'Manufacturer': '1315', 'Serial Number': 'E06E80B7', 'Asset Tag': '9876543210', 'Part Number': 'CT204864BF160B.M16'}]}, 'pci': {'0000:00:00.00': {'vendor': 32902, 'device': 5636}, '0000:00:02.00': {'vendor': 32902, 'device': 5654}, '0000:00:03.00': {'vendor': 32902, 'device': 5644}, '0000:00:16.00': {'vendor': 32902, 'device': 40122}, '0000:00:16.03': {'vendor': 32902, 'device': 40125}, '0000:00:19.00': {'vendor': 32902, 'device': 5538}, '0000:00:1b.00': {'vendor': 32902, 'device': 40096}, '0000:00:1d.00': {'vendor': 32902, 'device': 40102}, '0000:00:1f.00': {'vendor': 32902, 'device': 40131}, '0000:00:1f.02': {'vendor': 32902, 'device': 40067}, '0000:00:1f.03': {'vendor': 32902, 'device': 40098}}, 'total_ram': 15910.9609375, 'total_cpu_count': 4, 'total_cpu_sockets': 1}, 'network': {'eth0': {'mac': '94:c6:91:10:f1:dc', 'lldp': {'mac': 'f0:9f:c2:19:56:05', 'name': 'DevSwitch', 'slot': 0, 'port': 7, 'subport': 0}, 'primary': True}}, 'disks': [{'protocol': 'ATA', 'serial': 'JR1000D33LS4YE', 'model': 'HGST HTS721010A9E630', 'name': 'sda', 'location': 'ATA 0', 'firmware': 'JB0OA3U0', 'capacity': 931.5133895874023, 'devpath': '/devices/pci0000:00/0000:00:1f.2/ata1/host0/target0:0:0/0:0:0:0/scsi_disk/0:0:0:0', 'pcipath': '/pci0000:00/0000:00:1f.2/ata1/host0/target0:0:0/0:0:0:0', 'isSSD': False, 'isVirtualDisk': False}, {'protocol': 'ATA', 'serial': '1710161C6AF5', 'model': 'Crucial_CT1050MX300S', 'name': 'sdb', 'location': 'ATA 3', 'firmware': 'M0CR040', 'capacity': 978.0885543823242, 'devpath': '/devices/pci0000:00/0000:00:1f.2/ata4/host3/target3:0:0/3:0:0:0/scsi_disk/3:0:0:0', 'pcipath': '/pci0000:00/0000:00:1f.2/ata4/host3/target3:0:0/3:0:0:0', 'isSSD': False, 'isVirtualDisk': False}]}
  Class List:    []
  State:         built
  Located At:    2020-01-07 04:06:31.336942 +0000 +0000
  Built At:      2020-01-07 04:10:14.123422 +0000 +0000
  Created:       2020-01-07 00:46:42.322098 +0000 +0000
  Updated:       2020-01-07 04:10:14.12944 +0000 +0000

Get specific type of foundation (Note the addition of AMT specific values)::

  $ ./contractorcli foundation amt get esx01
  Locator:        esx01
  AMT Username:   admin
  AMT Password:   asdQWE1@3
  AMT Ip Address: 192.168.200.95
  Plot:           test
  Type:           AMT
  Site:           site1
  Blueprint:      amt-base
  Id Map:         {'hardware': {'dmi': {'BIOS Info': [{'Vendor': 'Intel Corporation', 'Version': 'MYBDWi5v.86A.0039.2017.1016.1545', 'Release Date': '10/16/2017', 'BIOS Revision': '5.6'}], 'System Info': [{'Manufacturer': '', 'Product Name': '', 'Version': '', 'Serial Number': '', 'UUID': '4917D980-B0E4-11E5-BF2D-94C69110F1DC', 'SKU Number': '', 'Family': ''}], 'Base Board Information': [{'Manufacturer': 'Intel Corporation', 'Product Name': 'NUC5i5MYBE', 'Version': 'H47797-208', 'Serial Number': 'GEMY72300148', 'Asset Tag': '', 'Type': 'Motherboard'}], 'Chassis Information': [{'Manufacturer': '', 'Type': 'Desktop', 'Version': '', 'Serial Number': '', 'Asset Tag': '', 'Boot-up State': 'Safe', 'Power Supply State': 'Safe', 'Thermal State': 'Safe', 'Height': '0', 'Number Of Power Cords': '1', 'SKU Number': 'To be filled by O.E.M.'}], 'OEM Strings': [{'String 1': 'To Be Filled By O.E.M.'}], 'System Configuration Options': [{'Option 1': 'To Be Filled By O.E.M.'}], 'Processor Information': [{'Socket Designation': 'SOCKET 0', 'Family': 'Core i5', 'Manufacturer': 'Intel(R) Corporation', 'ID': '0xbfebfbff000306d4', 'Version': 'Intel(R) Core(TM) i5-5300U CPU @ 2.30GHz', 'Status': 'Enabled', 'Serial Number': 'NULL', 'Asset Tag': 'To Be Filled By O.E.M', 'Part Number': 'To Be Filled By O.E.M', 'Core Count': '2', 'Core Enabled': '2', 'Thread Count': '4'}], 'Memory Device': [{'Size': 'No Module Installed', 'Set': 'None', 'Locator': 'SODIMM0', 'Bank Locator': 'CHANNEL A DIMM0', 'Type': 'Unknown', 'Speed': 'Unknown', 'Manufacturer': 'Not Specified', 'Serial Number': 'Not Specified', 'Asset Tag': 'Not Specified', 'Part Number': 'Not Specified'}, {'Size': '16384 MB', 'Set': 'None', 'Locator': 'SODIMM1', 'Bank Locator': 'CHANNEL B DIMM0', 'Type': 'DDR3', 'Speed': '1600 MHz', 'Manufacturer': '1315', 'Serial Number': 'E06E80B7', 'Asset Tag': '9876543210', 'Part Number': 'CT204864BF160B.M16'}]}, 'pci': {'0000:00:00.00': {'vendor': 32902, 'device': 5636}, '0000:00:02.00': {'vendor': 32902, 'device': 5654}, '0000:00:03.00': {'vendor': 32902, 'device': 5644}, '0000:00:16.00': {'vendor': 32902, 'device': 40122}, '0000:00:16.03': {'vendor': 32902, 'device': 40125}, '0000:00:19.00': {'vendor': 32902, 'device': 5538}, '0000:00:1b.00': {'vendor': 32902, 'device': 40096}, '0000:00:1d.00': {'vendor': 32902, 'device': 40102}, '0000:00:1f.00': {'vendor': 32902, 'device': 40131}, '0000:00:1f.02': {'vendor': 32902, 'device': 40067}, '0000:00:1f.03': {'vendor': 32902, 'device': 40098}}, 'total_ram': 15910.9609375, 'total_cpu_count': 4, 'total_cpu_sockets': 1}, 'network': {'eth0': {'mac': '94:c6:91:10:f1:dc', 'lldp': {'mac': 'f0:9f:c2:19:56:05', 'name': 'DevSwitch', 'slot': 0, 'port': 7, 'subport': 0}, 'primary': True}}, 'disks': [{'protocol': 'ATA', 'serial': 'JR1000D33LS4YE', 'model': 'HGST HTS721010A9E630', 'name': 'sda', 'location': 'ATA 0', 'firmware': 'JB0OA3U0', 'capacity': 931.5133895874023, 'devpath': '/devices/pci0000:00/0000:00:1f.2/ata1/host0/target0:0:0/0:0:0:0/scsi_disk/0:0:0:0', 'pcipath': '/pci0000:00/0000:00:1f.2/ata1/host0/target0:0:0/0:0:0:0', 'isSSD': False, 'isVirtualDisk': False}, {'protocol': 'ATA', 'serial': '1710161C6AF5', 'model': 'Crucial_CT1050MX300S', 'name': 'sdb', 'location': 'ATA 3', 'firmware': 'M0CR040', 'capacity': 978.0885543823242, 'devpath': '/devices/pci0000:00/0000:00:1f.2/ata4/host3/target3:0:0/3:0:0:0/scsi_disk/3:0:0:0', 'pcipath': '/pci0000:00/0000:00:1f.2/ata4/host3/target3:0:0/3:0:0:0', 'isSSD': False, 'isVirtualDisk': False}]}
  Class List:     ['Physical', 'AMT']
  State:          built
  Located At:     2020-01-07 04:06:31.336942 +0000 +0000
  Built At:       2020-01-07 04:10:14.123422 +0000 +0000
  Created:        2020-01-07 00:46:42.322098 +0000 +0000
  Updated:        2020-01-07 04:10:14.12944 +0000 +0000

Update and Create are similar to Site except that you must specify the type of
foundation::

  $ ./contractorcli foundation amt update rtest -b amt-base

Blueprint
---------

For Blueprints the name is also the id

NOTE: List, Get, Update, Create, Configuration sections are similar to Site
