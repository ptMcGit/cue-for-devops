CUE and DevOps
==============

This is a toy project demonstrating how CUE can be used with tools such as Packer, Ansible, and Terraform.
It is not meant to advocate for a specific design nor is this design intended to be used in production.
It is missing major components providing functionality such as load-balancing.
The emphasis here is to show different problems that CUE can solve.

Project Overview (before CUE)
-----------------------------

See tag v0

Note: all `.hcl` files have been converted to `.json` files.

### Packer

We use an `amazon-ebs` source for both projects. Packer uses a role with the same name located within the project to configure the instance.

### Terraform

We create a public subnet on an existing VPC for an instance that is spun up.
It finds the AMI created by Packer by name.

### Ansible

Ansible is used by Packer to configure the AMI.
It is also used to configure instances after the Terraform plan is run.

Project Overview (after CUE)
----------------------------

Most of the CUE files reside in the root directory; project-specific files reside in the appropriate project directory.
