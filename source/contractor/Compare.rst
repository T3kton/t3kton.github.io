Comparison Chart
================

Stacks
------

Contractor spans several layers that other tools usually handle one at a time,
so the tools are grouped by the layer they mainly work at.

Bare metal provisioning
  OpenStack Ironic, MAAS, Foreman, Cobbler, xCAT, Metal3, Tinkerbell, Digital Rebar, Fog

Infrastructure provisioning (declarative, multi-provider)
  Terraform (and the OpenTofu fork), Pulumi, Crossplane, AWS CDK

Source of truth (inventory / IPAM, adjacent rather than competing)
  NetBox, Nautobot

Configuration management
  Ansible, SaltStack, Puppet, Chef, CFEngine

Workflow / job orchestration
  Rundeck, AWX, StackStorm, Temporal

Container / application orchestration
  Kubernetes, Rancher (k8s only), OpenShift, Cluster API, Sidero Omni/Talos (k8s only), Nomad, Mesos, Juju (charms)

Platforms Contractor drives
  Bare metal (IPMI/AMT/RedFish), AWS, Azure, Docker, VMWare vCenter, Proxmox,
  VirtualBox, LibVirt.  (Others, such as GCP, are not yet supported.)


Table
-----

Y = yes, P = partial / needs add-ons, N = no.

.. list-table::
   :header-rows: 1
   :widths: 14 9 10 9 8 10 9 16

   * - Tool
     - Bare metal (PXE/BMC)
     - VM / cloud platforms
     - Network / IPAM
     - OS install
     - Config mgmt
     - Central API
     - Tracks state of whole site
   * - Contractor
     - Y
     - Y
     - Y
     - Y
     - P (config values only)
     - Y (CInP, UI, CLI)
     - Y (Foundation, Structure, Complex, Dependency)
   * - Terraform / OpenTofu
     - P (via providers, ie: MAAS)
     - Y (providers)
     - P
     - P (via providers, ie: MAAS)
     - N
     - P (paid server)
     - P (state file, one resource at a time)
   * - Pulumi
     - N
     - Y
     - P
     - N
     - N
     - P
     - P
   * - OpenStack Ironic
     - Y
     - N
     - P
     - Y (image)
     - N
     - Y
     - P (nodes only)
   * - MAAS
     - Y
     - P (KVM, LXD)
     - Y
     - Y
     - N
     - Y
     - P (machines)
   * - Foreman
     - Y
     - Y (compute resources)
     - Y
     - Y
     - P (Puppet/Ansible)
     - Y
     - P (hosts)
   * - Cobbler
     - Y
     - P
     - P (DHCP/DNS)
     - Y
     - N
     - Y
     - N
   * - xCAT
     - Y
     - P
     - Y
     - Y
     - P
     - P
     - P
   * - Metal3
     - Y
     - N
     - P
     - Y (image)
     - N
     - Y (k8s API)
     - P
   * - Ansible / AWX
     - P (modules)
     - P (modules)
     - P
     - P
     - Y
     - P (AWX)
     - N (stateless)
   * - SaltStack
     - N
     - P (salt-cloud)
     - N
     - N
     - Y
     - Y
     - N
   * - Puppet / Chef
     - N
     - N
     - N
     - N
     - Y
     - Y
     - N
   * - Temporal
     - N
     - N
     - N
     - N
     - N
     - Y
     - P (workflow state only)
   * - Kubernetes
     - N
     - P (cluster API)
     - P (CNI)
     - N
     - N
     - Y
     - Y (workloads only)
   * - Digital Rebar
     - Y
     - P
     - P
     - Y
     - P
     - Y
     - P (machines)
   * - Cluster API
     - P (via Metal3, MAAS providers)
     - Y (AWS, Azure, Google, vSphere providers)
     - P
     - N
     - N
     - Y (k8s API)
     - P (clusters only)
   * - Sidero Omni / Talos
     - Y (bare metal provider)
     - P (KubeVirt, libvirt, Proxmox, vSphere providers)
     - N
     - Y (Talos image)
     - N
     - Y
     - P (Kubernetes clusters only)
   * - Nomad
     - N
     - P (QEMU driver)
     - P
     - N
     - N
     - Y
     - P (workloads only)
   * - Juju
     - P (MAAS)
     - Y
     - P
     - N
     - Y (charms)
     - Y
     - Y

Design language
  Contractor: scripts (tscript) attached to BluePrints, driven by jobs.  Terraform/OpenTofu: HCL.
  Pulumi: general purpose languages.  Ansible: YAML playbooks.  Kubernetes: YAML manifests.


Where other tools fall short
----------------------------

These are general points by layer, not a ranking.  Many apply to more than one tool in
a layer, tool specific differences are called out where they matter.

Infrastructure as code (Terraform/OpenTofu, Pulumi, AWS CDK)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

 * Configurations are not portable across providers, each provider has its own resource types
 * Work is a plan/apply of one resource graph, there is no "update" in place for many changes, they are really kill and re-deploy
 * No rolling, and not much notion of the deployment as a whole, it is more individual resources
 * Doing anything outside of creating the resource (ie: running a command in a VM) needs a provisioner or other tool, which often means the tool's host has to SSH into the targets
 * Template tools are usually required to avoid repeating configuration
 * Shared state is a challenge, mostly the locking aspect.  Pulumi reports are mixed on locking with self managed backends (older threads say there is none, newer reviews say it is on by default), and an aborted CI run can leave a stack locked
 * Intended to be used by individuals, with credentials either in the files or prompted for
 * No central server with an API to query against unless using the vendor's paid/hosted service
 * The plan output of what it is about to do is very verbose
 * Some providers (ie: vCenter) are easily confused
 * Pulumi and AWS CDK need a real programming language, so reviewing the "infrastructure" is as hard as reviewing code
 * AWS CDK compiles to CloudFormation, so it is AWS only
 * Bare metal/OS install only by driving another provisioner (ie: Terraform has a MAAS provider), nothing built in

Ansible / AWX
~~~~~~~~~~~~~

 * No state.  It does not remember what exists, it re-checks every run, so drift and inventory of what is deployed has to be kept somewhere else
 * Idempotency depends on how each playbook/module is written, shell/command tasks are not
 * Agentless over SSH, so every run needs a connection (and credentials) to every target, slow on large fleets
 * One playbook run at a time per target, no model of dependencies between hosts beyond ordering in the playbook
 * Cloud/VM modules create things, but updating is a rewrite of the playbook
 * No bare metal discovery, PXE or IPAM of its own, needs Cobbler/Foreman/MAAS or similar underneath
 * A central API/UI needs AWX, which is a separate (and heavy) install

SaltStack / Puppet / Chef / CFEngine
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

 * Configure what is already running, they do not create hosts, networks or addresses
 * Agents (or minions) must already be installed, there is a chicken and egg problem for bare metal and new VMs
 * Each keeps its own view of nodes, which does not agree with the cloud/hypervisor or the IPAM
 * Ordering across many hosts (ie: bring up the database before the app) is awkward.  Open source Puppet agents run whenever they check in, ordered multi-node runs are a Puppet Enterprise feature.  Salt has an orchestrate runner on the master for it
 * Salt minions need their key accepted by the master before they can be managed
 * Puppet masters have been reported to struggle past a few hundred nodes without splitting the master or going masterless (anecdotal)

Bare metal provisioners (Ironic, MAAS, Foreman, Cobbler, xCAT, Metal3, Tinkerbell)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

 * Stop at "the OS is installed", anything on top (VMs, containers, apps, dependencies between hosts) is another tool
 * Several are tied to a larger stack: Ironic to OpenStack (or Metal3/Kubernetes), MAAS is Ubuntu centric (custom non-Ubuntu images are supported but still boot using an Ubuntu ephemeral OS, and LXD is the preferred VM host with libvirt only a legacy option), Foreman is built around Puppet and the optional Katello content manager
 * Foreman hands off to a configuration management tool once the host is built, and by default deleting a host does not destroy its VM on the compute resource, so recreating a VM of the same name fails.  Every host needs a domain, subnet and smart proxy (DHCP/DNS/TFTP) set up first
 * Need DHCP/PXE on the provisioning network, which is often a hard fit with existing networks; a proxy or helper is needed across networks
 * Provisioning is slow (full PXE boot cycle), failures during boot or cleanup can leave nodes stuck (with Metal3 a host that won't boot during deprovisioning can block deletion for a long time)
 * Cobbler manages DHCP/DNS only through ISC dhcpd or dnsmasq (and BIND for DNS), the two can't be mixed, Kea is not supported, and the config is regenerated on `cobbler sync`
 * Ironic in the OpenStack overcloud assumes a trusted tenant environment, nodes have access to the control network.  It can't use OVN's built in DHCP, and nodes on an isolated bare metal network can't PXE boot
 * Hardware inventory and IPAM are often separate from the cloud/VM side, Foreman is the exception here, it has subnets/IPAM, DHCP/DNS (through smart proxies) and many compute resources (libvirt, VMware, oVirt, Proxmox, EC2, Azure, GCE, OpenStack)
 * Digital Rebar is the closest in scope to Contractor, an API driven provisioning system with composable workflows (PXE and UEFI iPXE boot, disk partitioning, image writing, cloud-init), but the material found describes it as provisioning machines, not a model of VMs/containers/dependencies across platforms
 * Tinkerbell is a set of services (Smee for DHCP/iPXE, Tootles for metadata, HookOS and the Tink workflow engine), its DHCP service needs to listen directly on the layer 2 network of the machines

Kubernetes, Rancher, OpenShift, Crossplane, Cluster API
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

 * Manage workloads (and with Crossplane/Cluster API, cloud resources) but need a working cluster first, which something else has to build.  Rancher (node drivers) and OpenShift (installer provisioned infrastructure, assisted installer) can create the hosts for their own clusters, but only to run Kubernetes, Rancher otherwise imports existing clusters
 * Everything is expressed as Kubernetes objects, the underlying hosts, switches and non-container systems are second class
 * Cluster API needs a management cluster to run its infrastructure providers (AWS, Azure, Google, vSphere, bare metal through Metal3/MAAS), each provider has its own prerequisites and credentials
 * Sidero Omni/Talos provisions bare metal (and KubeVirt, libvirt, Proxmox, vSphere) only for Kubernetes clusters on the Talos OS, the older Sidero Metal project is no longer being developed in favor of Omni
 * Nomad runs containers, binaries and QEMU VMs on hosts that already exist, its exec driver is Linux/root only and the client to task interface is not a security boundary
 * Reconciliation loops hide the order of operations, which makes one-time, ordered procedures (ie: install a rack of servers in sequence) hard to express
 * Deletion can block on finalizers when the external system is stuck, the documented workaround is to remove the finalizer by hand, which skips the cleanup it guards
 * A full cloud provider adds around a thousand CRDs, which has caused scaling problems in the cluster itself
 * A Composition doesn't declare which provider it needs, a missing provider leaves the claim stuck unsynced

Workflow tools (Rundeck, AWX, StackStorm, Temporal, Jenkins)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

 * They run jobs, they don't know what the resulting infrastructure looks like.  Rundeck has a node list of hosts, but not networks, addresses or the lifecycle of what is built
 * Jenkins is CI, it is often pressed into doing operations work it was not designed for
 * AWX needs Ansible expertise and has been described as limited by its monolithic architecture; Rundeck is reported to have a steep learning curve and scaling limits (these are mostly vendor comparison write ups)
 * The model of the datacenter (hosts, networks, addresses) has to be built and kept up to date by hand in each job
 * Temporal is the closest to tscript, it keeps a workflow's state durable across restarts and failures, and can retry/pause/wait for long running steps.  But it is a programming framework: the workflows and every "activity" (create a VM, set PXE, wait for the host) have to be written in code (Go, Java, Python, TypeScript...) and run by your own stateless workers
 * Temporal workflow code must be deterministic (replayed from history), anything that touches the outside world has to be in an activity, which should be idempotent because it may be retried.  Changing a running workflow's code needs care to not break replay
 * Temporal has no knowledge of infrastructure, no inventory, networking, bare metal or platform integrations, those are all things you write.  It also needs its own server cluster and a database (Cassandra, MySQL or PostgreSQL) plus a visibility store to run

Adjacent tools
--------------

NetBox and Nautobot (Nautobot began as a NetBox fork) are sources of truth for DCIM/IPAM, racks, connections and
virtualization.  They hold the data and other automation (Ansible, Terraform, Nautobot's own Jobs) acts on it, they
don't provision anything themselves.  They overlap Contractor's Site/Network/AddressBlock/Plot modelling, Contractor
holds that data and drives the provisioning from it.

Claude's Note: checked by web search (see below): Pulumi state locking; Ansible state and SSH overhead;
the Ironic, Metal3, MAAS, Foreman, Cobbler, Crossplane, Puppet/Salt, Rancher, OpenShift,
Tinkerbell, workflow tool and Temporal points; and the table entries for Terraform (MAAS provider),
Foreman, xCAT (bare metal, OS install, KVM), Juju (MAAS, clouds), Salt (salt-cloud, REST API), Cluster API
(providers), Sidero Omni (providers), Nomad (drivers) and Digital Rebar (features).
Still a judgement rather than checked: the remaining Y/P/N ratings in the table (ie: xCAT network
management, Pulumi bare metal, Digital Rebar's network/config/cloud ratings), and no list of Tinkerbell specific limits was found.
Many of the sources are blogs and vendor comparisons, so verify against the project docs before
relying on any single point.

Sources
~~~~~~~

 * https://docs.temporal.io/temporal-service/persistence
 * https://community.temporal.io/t/why-cant-workflows-contain-non-deterministic-code-and-how-does-using-activity-solve-the-problem/3231
 * https://docs.openstack.org/ironic/2023.1/user/architecture.html
 * https://docs.redhat.com/en/documentation/red_hat_openstack_platform/13/html-single/bare_metal_provisioning/index
 * https://canonical.com/maas/docs/reference-release-notes-maas-3-1
 * https://docs.theforeman.org/3.7/Provisioning_Hosts/index-katello.html
 * https://cobbler.readthedocs.io/en/v3.3.7/user-guide/dhcp-management.html
 * https://archive.repo.saltproject.io/en/2017.7/topics/orchestrate/orchestrate_runner.html
 * https://docs.crossplane.io/knowledge-base/guides/troubleshoot/
 * https://upbound.io/blog/scaling-kubernetes-to-thousands-of-crds
 * https://www.eficode.com/blog/terraform-vs-pulumi-is-there-a-new-king-in-town
 * https://kestra.io/resources/whitepapers/infrastructure-orchestration
 * https://github.com/canonical/terraform-provider-maas
 * https://docs.tinkerbell.org
 * https://documentation.suse.com/cloudnative/rancher-manager/v2.9/en/rancher-admin/global-configuration/provisioning-drivers/provisioning-drivers.html
 * https://docs.redhat.com/en/documentation/openshift_container_platform/4.17/html-single/installing_on_bare_metal
 * https://xcat-core.readthedocs.io/en/latest/overview/features.html
 * https://documentation.ubuntu.com/juju/3.6/reference/cloud
 * https://docs.saltproject.io/en/3006/topics/netapi/index.html
 * https://docs.theforeman.org/3.15/Planning_for_Project/index-foreman-el.html
 * https://provision.readthedocs.io/stable/home/
 * https://release-1-10.cluster-api.sigs.k8s.io/reference/providers
 * https://www.siderolabs.com/blog/omni-source-code-now-available/
 * https://developer.hashicorp.com/nomad/docs/drivers
 * https://netboxlabs.com/blog/why-dcim-and-ipam-solutions-belong-together/
