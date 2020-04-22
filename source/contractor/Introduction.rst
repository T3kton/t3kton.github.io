Introduction to Contractor
==========================

Contractor is an Extendable Resource Management API.  The goal of Contractor
is to provide an API to Automate the Provisioning, Deployment, Configuration and
Management of Resources.

Contractor uses building terms (for the most part) to try to avoid name
collisions with various platforms and systems.

Overview
--------

Contractor is a builder of anything, and is targeted to be used as a generic API
to create/destroy/manipulate your resources no matter where or what they are.
This enables you to focus on what you want to make, and not have to worry about
the details and differences in deployment.

To accomplish this, Contractor breaks deployment/provisioning into two parts.  A
**Structure**, or what it is you want to deploy, and a **Foundation**, or what you want
to deploy it on.

Structure examples are DNS servers, API endpoints, load balancers, web servers,
docker hots, virtualbox hosts, CoreOS servers, etc...

Foundation examples are Docker Containers, Virtualbox VMs, servers with IPMI,
servers with out-of-band controls, switches, PDUs, AWS, GCP, Azure, etc...

A **BluePrint** is used to describe a Structure or Foundation. The BluePrint describes
configuration information needed to create the Structure; as well as the firmware,
machine level configuration (i.e. IPMI),

Each Structure and Foundation belong to a grouping called a **Site**. Sites can belong
to other Sites, and a Structure does not need to belong to the same Site as it's
Foundation. The Site can also contain configuration information for it's Structures
and Foundations to inherit. This way, a configuration such as a DNS server can be
maintained at the Site level and automatically propagate to everything else within
that Site.

By separating the configuration of the "Hosted" (Structure) and
the "Host" (Foundation) we can effectively divide up the job of configuring the system.  As a
Developer/Engineer configures their code, they embody that in a Structure.  They
can package that configuration information along with their code/designs and that configuration can also
be tested and verified via CICD and similar work flows.  This way the very
same configuration information is for all stages of deployment.  It is true
that some Foundations require different considerations, however a well designed
Structure Configuration can work for Containers (and the like) as well as
OS installers (Baremetal/VM/Blade/AWS/Container, etc.)  Now when the Operations
people need to turn it up to 11 (or 12) they just pick the location to deploy
and no matter if it is hosted on premise in VMs, or deployed to AWS for some
peak load handling, Operations can scale as needed, to whatever.

You are also free from vendor lock in.  If a new Cloud provider comes along, they
don't need to have an AWS like API to use them, just a plugin  that talks to that
Cloud provider's API and you are set.  Same if a new class of hardware comes along
(ARM servers anyone?) or a new way of approaching hosting (the next thing after
containers).  And you don't have to try to fit all your use cases into one silver
bullet.

Your Operations teams are also free to try changing out hosting solutions without
retooling everything to try it -- in some cases without involving Engineering
to do so.  By allowing every thing, no matter the platform, to be tracked in the same
place, you now have a single source of truth for your monitoring system to rely on.
You don't have to worry about parts of your Micro Services failing to auto-register.
And, you know exactly what is deployed where; useful when hardware needs to be
swapped out.

Each BluePrint has a **Create** and **Destroy** script that is executed to create and
destroy that Structure, or to provision or deprovision in the case of Foundations.
The scripting language is Turing Complete, and is extended by the loaded plugins,
and target Foundation.

Utiity scripts can also be created. For example, if a new firmware for a storage
controller is released, a utility script can be created to deploy the new firmware
and a job can be created to execute the script.

Jobs are run by the **Foreman** subsystem. When a new Foundation has been
detected, or a Structure's Foundation has been provisioned, Foreman will provide
instructions to a **SubContractor** daemon to do individual tasks required
for that Foundation to be Provisioned or Structure to be created.

SubContractor is a daemon that runs in appropriate parts of the network for handling
tasks as requested by the script being executed within the Job. All tasks are
requested by SubContractor over HTTP (fully proxyable), thus Contractor itself
does not need to access sensitive parts of the network - it only needs to be
visible to SubContractor.

In turn, Each SubContractor can be configured to only do certain types of work.
For example, a SubContractor can be configured to do only IPMI taks, enable the
IPMI network to be isolated from other networks. Other SubContractors can then
handle PXE booting the servers, and performing other checks such as checking that
port 22 is open (a common and easy way to make sure a Structure with SSH installed
has sucessfully booted).

High Level Look
===============

Foundations and Structures
--------------------------

First two terms are **Foundation** and **Structure**.  A Foundation is something
to build on, a Structure is the thing you want to build.  Say we want to
build a Web Server.  Our Structure is a set of configuration values and scripts
required to build that web server, i.e., Install Ubuntu LTS 18.04 and install and
Configure Apache (more on those details in .....).  The Foundation is what we
want to install that on, i.e., a VM, Container, Blade Server, Bare-metal Server,
Raspberry PI, ECS, GCD, etc...  Not all Foundations are going to be compatible
with all Structures, however a well defined Structure can be installed on most
of them.

So far we have this::

  +-----------------------------+
  |                             |
  |  Structure (Web Server)     |
  |                             |
  +-----------------------------+
               |
               |
  +-----------------------------+
  |                             |
  |   Foundation                |
  |                             |
  +-----------------------------+


Sites
-----

The next term is **Site**.  A site is a Logical grouping of things.  Let's put
our Web Server in a Site called "Cluster 1"

::

  +-------------------------------------+
  |  Cluster 1                          |
  |                                     |
  |    +-----------------------------+  |
  |    |                             |  |
  |    |  Structure (Web Server)     |  |
  |    |                             |  |
  |    +------------+----------------+  |
  |                 |                   |
  |                 |                   |
  |    +------------+----------------+  |
  |    |                             |  |
  |    |   Foundation                |  |
  |    |                             |  |
  |    +-----------------------------+  |
  |                                     |
  +-------------------------------------+

Each Item we have used so far contains configuration values.  These are Key
Value pairs that can be overlay-ed.  In this case Contractor will take the
configuration values of "Cluster 1" then overlay them with "Foundation" and
the "Structure".

Sites can be be put into other Sites.  For example we have Clusters 1, 2, and 3
in "Datacenter West".

::

  +---------------------------------------------------------------------------------------------+
  | Datacenter West                                                                             |
  |                                                                                             |
  |  +-------------------------------------+ +----------------------+ +----------------------+  |
  |  |  Cluster 1                          | |  Cluster 2           | |  Cluster 3           |  |
  |  |                                     | |                      | |                      |  |
  |  |    +-----------------------------+  | |    +--------------+  | |    +--------------+  |  |
  |  |    |                             |  | |    |              |  | |    |              |  |  |
  |  |    |  Structure (Web Server)     |  | |    |  Structure   |  | |    |  Structure   |  |  |
  |  |    |                             |  | |    |              |  | |    |              |  |  |
  |  |    +------------+----------------+  | |    +-----+--------+  | |    +-----+--------+  |  |
  |  |                 |                   | |          |           | |          |           |  |
  |  |                 |                   | |          |           | |          |           |  |
  |  |    +------------+----------------+  | |    +-----+--------+  | |    +-----+--------+  |  |
  |  |    |                             |  | |    |              |  | |    |              |  |  |
  |  |    |   Foundation                |  | |    |  Foundation  |  | |    |  Foundation  |  |  |
  |  |    |                             |  | |    |              |  | |    |              |  |  |
  |  |    +-----------------------------+  | |    +--------------+  | |    +--------------+  |  |
  |  |                                     | |                      | |                      |  |
  |  +-------------------------------------+ +----------------------+ +----------------------+  |
  |                                                                                             |
  +---------------------------------------------------------------------------------------------+

Now the configuration information will first have site "Datacenter West" then,
Cluster X, Foundation, Structure.  This comes in handy for propagating configuration
information without having to set it for each item individually.  For example,
we can have the DNS Search Zones be set to "west.site.com" in the site "Datacenter West"
and prepend that with "cluster1.site.com" in "Cluster 1".  If at any time we want
some other global DNS search zone, we add it to the top and it automatically propagates
down.  You could also set "Release"="Prod" in "Datacenter West" and then create a
"Cluster Test" and override the "Release" to the value "Test".  You could also do
A-B testing, etc.

Any Item can make an HTTP request to Contractor and Contractor will reply with a JSON
encoded reply with that item's combined configuration values.

This is all fun and all, but not really useful.  Let's change things up a bit and
install ESX on the bare-metal and put a few Web servers on ESX.

Before we do that we need to dig into Foundations a little more. The **Foundation**
class is meant as a root class for specific target handlers to work against.

We are going to use the **IPMIFoundation** to handle the bare-metal machines on which
we are installing ESX on, and **VCenterFoundation** to handle the vms on the
ESX/VCenter.

Complexes
---------

Note: we are going to omit Cluster 2 and 3 for now, they are clones of Cluster 1::

  +-----------------------------------------------------------------------------+
  | Datacenter West                                                             |
  |                                                                             |
  |  +-----------------------------------------------------------------------+  |
  |  |  Cluster 1                                                            |  |
  |  |                                                                       |  |
  |  |  +-----------------------------+ +-----------------------------+      |  |
  |  |  |                             | |                             |      |  |
  |  |  |  Structure (Web Server)     | |  Structure (Web Server)     |      |  |
  |  |  |                             | |                             |      |  |
  |  |  +------------+----------------+ +------------+----------------+      |  |
  |  |               |                               |                       |  |
  |  |               |                               |                       |  |
  |  |  +------------+----------------+ +------------+----------------+      |  |
  |  |  |                             | |                             |      |  |
  |  |  |   VCenterFoundation         | |   VCenterFoundation         |      |  |
  |  |  |                             | |                             |      |  |
  |  |  +------------------------+----+ +---+-------------------------+      |  |
  |  |                           |          |                                |  |
  |  |                      +----+----------+---+                            |  |
  |  |                      |                   |                            |  |
  |  |                      | VCenter Complex   |                            |  |
  |  |                      |                   |                            |  |
  |  |                      +--------+----------+                            |  |
  |  |                               |                                       |  |
  |  |                  +------------+----------------+                      |  |
  |  |                  |                             |                      |  |
  |  |                  |  Structure (ESX)            |                      |  |
  |  |                  |                             |                      |  |
  |  |                  +------------+----------------+                      |  |
  |  |                               |                                       |  |
  |  |                               |                                       |  |
  |  |                  +------------+----------------+                      |  |
  |  |                  |                             |                      |  |
  |  |                  |   IPMIFoundation            |                      |  |
  |  |                  |                             |                      |  |
  |  |                  +-----------------------------+                      |  |
  |  |                                                                       |  |
  |  +-----------------------------------------------------------------------+  |
  |                                                                             |
  +-----------------------------------------------------------------------------+

This introduces our next item the **Complex** as in a building complex.  A Complex
is a group of Structures providing something for more Foundations to be built on.
A Complex (depending on the type) can have one or more Structures as members.
NOTE: the configuration info of the Structure and Foundations that make up a
cluster do **NOT** flow through to the Foundations and Structures built on that
complex.  The Members of the Complex can even belong to another site.

For Example::

  +-----------------------------------------------------------------------------+
  | Datacenter West                                                             |
  |                                                                             |
  |  +-----------------------------------------------------------------------+  |
  |  |  Cluster 1                                                            |  |
  |  |                                                                       |  |
  |  |  +-----------------------------+ +-----------------------------+      |  |
  |  |  |                             | |                             |      |  |
  |  |  |  Structure (Web Server)     | |  Structure (Web Server)     |      |  |
  |  |  |                             | |                             |      |  |
  |  |  +------------+----------------+ +------------+----------------+      |  |
  |  |               |                               |                       |  |
  |  |               |                               |                       |  |
  |  |  +------------+----------------+ +------------+----------------+      |  |
  |  |  |                             | |                             |      |  |
  |  |  |   VCenterFoundation         | |   VCenterFoundation         |      |  |
  |  |  |                             | |                             |      |  |
  |  |  +------------------------+----+ +---+-------------------------+      |  |
  |  |                           |          |                                |  |
  |  +-----------------------------------------------------------------------+  |
  |  |                           |          |                                |  |
  |  |  Cluster 1 Hosting   +----+----------+---+                            |  |
  |  |                      |                   |                            |  |
  |  |                      | VCenter Complex   |                            |  |
  |  |                      |                   |                            |  |
  |  |                      +---+-------------+-+                            |  |
  |  |                          |             |                              |  |
  |  |                          |             |                              |  |
  |  |                          |             |                              |  |
  |  |                          |             |                              |  |
  |  |     +--------------------+------+   +--+-------------------------+    |  |
  |  |     |                           |   |                            |    |  |
  |  |     | Structure (ESX)           |   | Structure (ESX)            |    |  |
  |  |     |                           |   |                            |    |  |
  |  |     +----------+----------------+   +-----------+----------------+    |  |
  |  |                |                                |                     |  |
  |  |                |                                |                     |  |
  |  |     +----------+----------------+   +-----------+----------------+    |  |
  |  |     |                           |   |                            |    |  |
  |  |     |  IPMIFoundation           |   |  IPMIFoundation            |    |  |
  |  |     |                           |   |                            |    |  |
  |  |     +---------------------------+   +----------------------------+    |  |
  |  |                                                                       |  |
  |  +-----------------------------------------------------------------------+  |
  |                                                                             |
  +-----------------------------------------------------------------------------+

Complexes also cause Contractor to build the Web Server Structure/Foundations
after the ESX Structure/Foundations are done.  Also the example would look pretty
much the same for a Docker/OpenStack/etc Complex.

Dependencies
------------

One final piece of the deployment puzzle, the **Dependency**.  This is to make sure
your deployments happen in order.  For example, you can't install any OSes until
the Switch is provisioned.  Also you may have to allocate space on an NFS mount
before installing a VM.  This is where Dependencies come in, allowing a Foundation
to Depend on a Structure being built, and/or a job being run on a Structure.


BluePrints
----------

Now that we have talked about the parts, we need to talk about how those things
are confugred and that is handled by **BluePrint**, specifically the
**FoundationBluePrint** and the **StructureBluePrint**.  A Blueprint also holds
configuration values, as well as links to scripts which are executed when the
Structure/Foundation that blueprint is for is configured, destroyed, or had a named
script run on it.  The BluePrint is the thing that Engineering and Operations
build to embody the process and configuration information of Creating the
Structure/Foundation.

A **BluePrint** can have multiple parents, this is useful for centralizing
configuration information.

A Blueprint must have (or one through it's parents) two **Scripts**.  A
"create" and a "destroy" script.  I can also have other named scripts
for other tasks.  These scripts are written in **tscript** (see :doc:`tscript`).

Taking our example from above, the blueprint for the webserver would look something
like (see :doc:ConfigurationValues for info on the configuration values)::


  [ structure.webserver ]
    description = 'My Serbserver'
    parents = [ 'ubuntu-bionic-base' ]
  [ structure.webserver.config_values ]
    '>package_list' = [ 'apache', 'myapp' ]

It would inherit the create/destroy scripts from `linux-installer`, which is an
ancestor to `ubuntu-bionic-base` which is defined in https://github.com/T3kton/resources/blob/master/os-bases/ubuntu/usr/lib/contractor/resources/ubuntu.toml.
`linux-installer` is defined here https://github.com/T3kton/resources/blob/master/os-bases/os_base/usr/lib/contractor/resources/base_os.toml.


Other
-----

There are other Classes/Components in Contractor, but they are mostly for dealing
with Configure/Destroy/Misc Jobs (the Foreman/SubContractor module), or managing
DNS Zones (Directory module), keeping track of Ip Addresses and other
"Utilities" in the Utilities module, the physical location of things (Survey Module),
and Audit log (Records Module).  Those are documented else where.


Future
------
Contractor being able to build everything can also be used as a single source of
truth, thus providing a place where you can ask questions such as "How many Load
Balancers do we have", "What Services will taking this host down affect", or
"How many VM resources are being used to support this service".  Contractor has a
Bind zone file generating ability that can be used to maintain DNS records, which
will automatically update when things are added/removed.  With Contractor you do
not have to wait for a new VM to register with a service.  That Service can query
Contractor to know what should be registered with it and act if a registered
resource is not connected.  Contractor will also have webhooks so that services can
be notified on Creation/Destruction events or even hardware events, thus allowing
a service able to ask for a harddrive replacment to wait until it is able
to take that harddrive out of service nicely.
