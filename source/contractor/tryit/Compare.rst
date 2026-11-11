Comparison Chart
================

Stacks
------

Contractor spans several layers that other tools usually handle one at a time,
so the tools are grouped by the layer they mainly work at.

Bare metal provisioning
  OpenStack Ironic, MAAS, Foreman, Cobbler, xCAT, Metal3, Tinkerbell, Fog

Infrastructure provisioning (declarative, multi-provider)
  Terraform (and the OpenTofu fork), Pulumi, Crossplane, AWS CDK

Configuration management
  Ansible, SaltStack, Puppet, Chef, CFEngine

Workflow / job orchestration
  Rundeck, AWX/Ansible Automation Platform, StackStorm

Container / application orchestration
  Kubernetes, Rancher (k8s only), OpenShift, Mesos, Juju (charms)

Platforms Contractor drives
  Bare metal (IPMI/AMT/RedFish), AWS, Azure, Docker, VMWare vCenter, Proxmox,
  VirtualBox, LibVirt.  (Others, such as GCP, are not yet supported.)


Table
-----

Y = yes, P = partial / needs add-ons, N = no.  License as of writing, check the
project for current terms.

.. list-table::
   :header-rows: 1
   :widths: 12 8 9 8 7 9 8 14 10

   * - Tool
     - Bare metal (PXE/BMC)
     - VM / cloud platforms
     - Network / IPAM
     - OS install
     - Config mgmt
     - Central API
     - Tracks state of whole site
     - License
   * - Contractor
     - Y
     - Y
     - Y
     - Y
     - P (config values only)
     - Y (CInP, UI, CLI)
     - Y (Foundation, Structure, Complex, Dependency)
     - Apache 2.0
   * - Terraform / OpenTofu
     - N
     - Y (providers)
     - P
     - N
     - N
     - P (paid server)
     - P (state file, one resource at a time)
     - BSL (Terraform), MPL (OpenTofu)
   * - Pulumi
     - N
     - Y
     - P
     - N
     - N
     - P
     - P
     - Apache 2.0
   * - OpenStack Ironic
     - Y
     - N
     - P
     - Y (image)
     - N
     - Y
     - P (nodes only)
     - Apache 2.0
   * - MAAS
     - Y
     - P (KVM, LXD)
     - Y
     - Y
     - N
     - Y
     - P (machines)
     - AGPL 3
   * - Foreman
     - Y
     - Y (compute resources)
     - Y
     - Y
     - P (Puppet/Ansible)
     - Y
     - P (hosts)
     - GPL 3
   * - Cobbler
     - Y
     - P
     - P (DHCP/DNS)
     - Y
     - N
     - Y
     - N
     - GPL 2
   * - xCAT
     - Y
     - P
     - Y
     - Y
     - P
     - P
     - P
     - EPL
   * - Metal3
     - Y
     - N
     - P
     - Y (image)
     - N
     - Y (k8s API)
     - P
     - Apache 2.0
   * - Ansible / AWX
     - P (modules)
     - P (modules)
     - P
     - P
     - Y
     - P (AWX)
     - N (stateless)
     - GPL 3 / Apache 2.0
   * - SaltStack
     - N
     - P (salt-cloud)
     - N
     - N
     - Y
     - Y
     - N
     - Apache 2.0
   * - Puppet / Chef
     - N
     - N
     - N
     - N
     - Y
     - Y
     - N
     - Apache 2.0
   * - Kubernetes
     - N
     - P (cluster API)
     - P (CNI)
     - N
     - N
     - Y
     - Y (workloads only)
     - Apache 2.0
   * - Juju
     - P (MAAS)
     - Y
     - P
     - N
     - Y (charms)
     - Y
     - Y
     - AGPL 3

Design language
  Contractor: scripts (tscript) attached to BluePrints, driven by jobs.  Terraform: HCL.
  Pulumi: general purpose languages.  Ansible: YAML playbooks.  Kubernetes: YAML manifests.

Business model
  Contractor: Apache 2.0.  Terraform: source-available (BSL) with a paid
  enterprise server.  Pulumi, Foreman, Ansible: open core / vendor backed.


Where other tools fall short
----------------------------

Terraform (and similar declarative tools):

 * Configurations are not portable across providers
 * Can only really do one thing at a time
 * No "update", "changes" are really kill and re-deploy
 * Template tools required
 * Doesn't really do infrastructure, doesn't look at the deployment as a whole, more individual resources
 * No rolling
 * Shared state is a challenge (mostly the locking aspect)
 * Intended to be used by individuals with auth either in the files or prompted for
 * What it is about to do is very verbose
 * VCenter provider is easily confused
 * No central server with API to query against (unless using Enterprise)
 * No support for vmware tools command execution, which requires the terraform server to ssh into targets
