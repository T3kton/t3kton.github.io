Plugins
=======

Plugins add Foundation types (and the functions the scripts use to work with them)
to Contractor.  They are installed with `respkg`, for example
`sudo respkg -i contractor-plugins-ipmi_*.respkg`, and then apache needs to be
restarted.  Run `contractorcli foundation types` to see which Foundation types are
available in your install.

Foundations
-----------

AMT
~~~

Intel AMT out-of-band managed machines.  Used with a Survey Plot, power control through AMT.

AWS
~~~

Amazon EC2 instances.  Creates and destroys instances, power control, and reports the interface MACs and
ip addresses.

Azure
~~~~~

Azure virtual machines, grouped in an Azure Complex.

Docker
~~~~~~

Docker containers.  Containers belong to a Docker Complex (which is a Structure running Docker),
inherit the interface and ip address of their host, and are given ports from a pool of Docker Ports
that are mapped through to the container.

IPMI
~~~~

IPMI managed bare metal.  Used with a Survey Plot.  Power control, and a link test using `ipmitool`.  The
Serial Over LAN port uses the common console port choices: `console`, `ttyS0`, `ttyS1`, `ttyS2`, `ttyS3`.

LibVirt
~~~~~~~

Virtual machines on a LibVirt (KVM) host.  A LibVirt Complex has one member, the host, and the ip address used to manage
LibVirt comes from the member's primary address.  Foundations are tracked by the LibVirt UUID.  A LibVirt Foundation has a
`libvirt_console_type`, either `serial` (default) or `spice`, which selects where the VM's console goes.

Manual
~~~~~~

For things that are pre-configured or handled by something else (ie: the Contractor VM itself, or a VM host that
is already built).  The Foundation and its Structure are normally marked as built with the `boss` command.
Also provides Manual Complexes, and Manual Complexed Foundations.

Proxmox
~~~~~~~

Virtual machines on Proxmox, grouped in a Proxmox Complex.  Requires `python3-proxmoxer`.

RaspberryPI
~~~~~~~~~~~

Raspberry Pi Foundations.

RedFish
~~~~~~~

RedFish (BMC) managed bare metal.  Power control and a link test, with the same console port choices as IPMI.

Test
~~~~

Test Foundations and Complexes with power operations that don't do anything, for developing and testing blueprints and scripts.

VCenter
~~~~~~~

Virtual machines on VMware ESX/VCenter, grouped in a VCenter Complex.  Requires `python3-pyvmomi`.  Also has functions for
datastores, networks, templates and exporting.

VirtualBox
~~~~~~~~~~

Virtual machines on VirtualBox (through the VirtualBox web service), grouped in a VirtualBox Complex.  Requires `python3-zeep`.

Script Functions
----------------

These plugins add functions that can be called from tscript (see :doc:`tscript`),
they don't add a Foundation type.

IPUtils
~~~~~~~

Network checks and SNMP, such as `ping`, `waitForPort`, `snmpGet`, and `snmpSet`.  The port check is what Contractor uses to verify the OS has booted.

SSH
~~~

Run commands on, and copy files to, a target over ssh.

VyOS
~~~~

Configure VyOS routers from the interfaces and addresses in Contractor.

HardDrive
~~~~~~~~~

Records of the hard drives (serial and model) seen in machines.


TODO
====

GCP
