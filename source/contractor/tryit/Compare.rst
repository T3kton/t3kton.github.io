Comparison Chart
================


Contractor compared to other tools

Note: Omitting the platform specific tools such as Azure Resource Manager/Google Cloud Deployment Manager/Cloud Formation/Docker Swarm/Vmware vCenter Configuration Manager
Note2: Omitting some older, not seemingly under active maintenance like Cloudify

http://www.devopsbookmarks.com/orchestration
https://phoenixnap.com/blog/container-orchestration-tools
https://ll-labs.readthedocs.io/en/latest/calm/orchestration.html
https://www.burwood.com/blog-archive/automation-vs-orchestration-whats-the-difference

Contractor

Terraform
Kubernetes
Foreman
Cobbler
Chef
OpenStack Ironic
Rancher

Rundeck
Awx/Tower
StackStorm

Ansible
SaltStack
Puppet
CFEngine

JuJu
Pulumi
NixOS
Otter
Heat
Pallet
Openshift

Jenkins
Vagrant

Mesos
Container crane

LXC
Container Linux

Platforms:
Baremetal (IPMI/AMT/Redfish)
AWS
GCD
Azure
Other Clouds
Docker
VMWare
ProxMox
VirtualBox
Xen

Design Language

License/Business Model

+-----------------+--------------+
|
+-----------------+




Configurations are not portalbale across providers
Can only really do one thing at a time
No “update”
“changes” are really kill and re-deploy
Template tools required
dosen’t really do infrastructure
Everything is done one thing at a time
No rolling
Dosen’t really look at the deployment as a whole, more individual resources.
shared state is a challenge, (mostly in the locking aspect)
Intended to be use by individuals with auth either in the files or prompted for
What it is about to do is very verbose
Vcenter provider is easily confused
No central server with API to query against (unless using Enterprise)
No support for vmware tools command execution, which requires the terraform server to ssh into targets
