Networking
==========

Sites can also hold network configuration information (such as DNS servers and DNS
search zones) which can be Site specific.  See the Config Values page.

Networked
---------

`Networked` is an attribute applied to things with IP Addresses.  It also has a
hostname attribute.  Structures are Networked, as well as some foundations
such as the `IPMIFoundation` or `AMTFoundation` which has an Ip Address on it's IPMI interface.

Ip Addresses
------------

Ip Addresses are grouped together in named networks called `AddressBlocks`.  Ip Addresses
inside the AddressBlock is identified by the offset inside that network.  The AddressBlock
stores the subnet and prefix of the network.  There is an optional offset for the gateway
of the network.  The Subnet and Prefix operate like standard CIDR ( https://en.wikipedia.org/wiki/Classless_Inter-Domain_Routing )
mechanics.  If the subnet and/or prefix of the AddressBlock is changed, all Ip Addresses
connected to that AddressBlock will follow.  No two AddressBlocks in the same site can overlap.  An
AddressBlock is also tied to a Site.  An Address enforces that the Site the Networked
belongs to is the same as the AddressBlock the Address Belongs to, thereby simplifying
management, helping to assure that the address will work.

NOTE: When setting the subnet of an AddressBlock, Contractor will round to the top
of the Subnet, so setting the subnet to 10.0.0.10 or 10.0.0.0 (assuming the prefix
is small enough to include .0 and .10 in the same subnet) will result in the
same value of 10.0.0.0.

You can calculate the subnet of an Ip Address by subtracting the subnet from the Ip Address
For example 23.33.10.30 in the subnet 23.33.10.0/24 is 30.

In some cases (such as with containers), a Structure doesn't have it's own IpAddress, but relies on its host IpAddress.  In
these cases, Address can be configured to point to another Address.  NOTE: the site is not checked through the pointer
field, this way the host and the hosted can belong to different sites, make sure
your site and network configuration works for this.  Address also
has a boolean value is_primary, which defines which of all the potential Addresses
this Networked device is to be used as it's primary DNS name, as well as the Address
to use when referring to it.

Examples
~~~~~~~~

+---------------------+---------------------+------------------------+-------------------------+
| AddressBlock Subnet | AddressBlock Prefix | Ip Address at offset 1 | Ip Address at offset 20 |
+=====================+=====================+========================+=========================+
| 10.0.0.0            | 21                  | 10.0.0.1               | 10.0.0.20               |
+---------------------+---------------------+------------------------+-------------------------+
| 192.168.23.0        | 24                  | 192.168.23.1           | 192.168.23.20           |
+---------------------+---------------------+------------------------+-------------------------+
| 169.254.57.127      | 23                  | 168.254.57.128         | 168.154.57.147          |
+---------------------+---------------------+------------------------+-------------------------+
| 2001:db8:\:         | 96                  | 2001:db8::1            | 2001:db8::20            |
+---------------------+---------------------+------------------------+-------------------------+
| 2001::1000          | 120                 | 2001::1001             | 2001::1020              |
+---------------------+---------------------+------------------------+-------------------------+


IP Address Types
~~~~~~~~~~~~~~~~

**ReservedAddress** adds a single field which is a description of the reason
the Address has been reserved.

**DynamicAddress** adds a PXE value which is used to PXE boot what ever device
gets this lease and wants to PXE boot.  This is optional.
Ip Addresses come in a few flavors, there is a BaseAddress class which all Ip Addresses
belong to that defines an Ip Address as an Offset in an AddressBlock.  The flavors
of BaseAddress are `Address` - an Address that can belong to Networked.
`ReservedAddress` - an Address that is reserved by something outside Contractor's
scope.  And `DynamicAddress` - an Address that belongs to a DHCP group.


Networks
--------

A `Network` is used to name the physical/logical networks that `NetworkInterface`s are attached
to.  AddressBlocks are associated with Networks, with optional vlan tagging.  The
Network name is used by plugins such as VCenter/AWS/Azure to know the name of the
Switch/Network to attach to.

NetworkInterfaces
-----------------

A `NetworkInterface` is a named connection between a Networked, a set of IpAddressed and a Network.
A NetworkInterface has a flag is_provisioning which indicates which interface should be used for communication
during provisioning.  During provisioning only the primary IP on the provisioning
interface is used.  Not until the final Structure(i.e., Operating System) is installed
and configured will the other interfaces and Ip Addresses be used.  NetworkInterface
has three flavors, **RealNetworkInterface**, **AbstractNetworkInterface**, and
**AggregatedNetworkInterface**.

Interface Types
~~~~~~~~~~~~~~~

**RealNetworkInterface** is to identify physical ports, (or in case of things like
Blades/VMs, Real as far as the OS/BIOS is concerned).  This type requires a MAC address
and is PXE bootable.

**AbstractNetworkInterface** is for interfaces that do not "physically" exist, like
internal bridge interfaces, or loop back interfaces.

**AggregatedNetworkInterface** is for grouping multiple NetworkInterfaces together
into a single AbstractNetworkInterface.  This is for things such as Port Channels,
Bonded Interfaces, LACP, etc.  One interface is designated as the master interface.
When the final Structure is not installed and configured, this is the interface
that is used.  There is also a list of the other interfaces that are grouped
in as well as a Key/Value field to store configuration information (such as
the bonding mode).

NOTE: All networking information is combined together and added to the Configuration
Information of the Structure/Foundation as a whole.

NOTE2: Technically speaking other than dedicated NetworkInterfaces, such as the IPMI
port on the IPMIFoundation, Foundations do not have Ip Addresses.  Thus most Physical
Foundations will borrow the Address information of the Structure that they are configured
with to do tasks of the Foundation Jobs.  Without a Structure, Foundation Jobs that
require an Address can not be done. (This is something that will hopefully change
in the future by borrowing from a dynamic pool, but for now a Structure is required.)
