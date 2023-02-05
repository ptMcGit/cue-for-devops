# CUE for DevOps

## Overview

This is a tutorial that uses a toy infrastructure project to highlight some of CUE's features and show how it can be used to simplify and manage infrastructure.
Go to [Tutorial](#first-steps) if you want to skip the introductory stuff.

### What is CUE?

From [cuelang.org](https://cuelang.org):

>CUE is an open-source data validation language and inference engine with its roots in logic programming.

One notable difference between CUE and many other programming languages is that types can be used as values.
In other words, we can write an expression where the value of the assignment is, for example, type `string` or an arbitrary string, e.g. `"my string"`.

```
x: string
y: "my string"
```

Expressions such as the one above are order-independent in CUE.
In other words, we can change the order of the expressions and CUE always gives the same result.
Roughly speaking, what is commonplace in other languages -- the reassignment of a variable to another *concrete* value, e.g. `x = 1; x = 2`,  -- is not possible in CUE.
Instead, evaluation of the following by the CUE runtime causes an error:

```
a: 1
a: 2
```

This design feature allows us to be absolutely sure when we observe `a: 1` in the codebase -- and, there are no problems reported by CUE -- that `a` is `1`.

### How can CUE help with DevOps?

- CUE can parse YAML and JSON files and also output data in these formats
- templates are a CUE feature that provide a much more manageable alternative to distributing boilerplate code
- the CUE runtime allows the aggregation of many data sources in a predictable and repeatable way; CUE will not let disagreements or conflicts in the data pass through silently
- CUE provides support for writing CLIs which can be used to interface with DevOps tools

### What is being demonstrated with this tutorial?

With this tutorial we'll create simple declarative interfaces for managing infrastructure in two different projects.
The data conveyed to these interfaces, known as templates, will be combined with data in parent files by CUE at runtime.
The CUE runtime will ensure that data is valid and doesn't violate constraints.
Simple CUE command line tools will allow us to generate appropriate artifacts that Ansible, Terraform, and Packer can consume.

### The Scenario

We have two sets of servers on the Internet for projects *Saturn* and *Jupiter* that run different services.
The configurations are mostly the same with only minor differences such as:

- identifiers
- Ansible roles
- IP addresses

Our workflow for each in this scenario is something like this:

1. We build the AMI with packer.
  - During the build process Packer uses Ansible to modify the AMI.
2. Once our AMI is available we use Terraform to provision an instance.
  - After a server is provisioned we run Ansible against it to configure it further.
3. For any changes to an instance where we wish to avoid a teardown/rebuild we use Ansible.

Note: all `.hcl` files have been converted to `.json` files.

#### Packer

We use an `amazon-ebs` source for both projects. Packer uses a role with the same name located within the project to configure the instance.

#### Terraform

We create a public subnet on an existing VPC for an instance that is spun up.
It finds the AMI created by Packer by name.

#### Ansible

Ansible is used by Packer to configure the AMI.
It is also used to configure instances after the Terraform plan is run.

### Migrating to CUE

We'll approach the needs for Packer, Ansible, and Terraform separately.

There are three important aspects for each which will be addressed.

1. We need to Create the required `*.cue` files, including:
  - files that have project-specific data, e.g. Jupiter uses CIDR block `10.1.1.0/24`
  - parent files that contain templates, general configuration data, and maybe some logic
2. We'll use a few tools to check that our code is correct among other things:
  - `cue eval ./...` - indicates if there are any errors and shows everything CUE evaluates
  - `cue export ./...` - functions similarly to `eval`, but tries to output valid JSON by default
  - `cue fmt ./...` - formats files

For those unfamiliar with Go, `./...` is used to specify all files (CUE files in this case) in the current directory and in all subdirectories.

`eval` and `export` are especially important when run at the root of the project.
When these commands are both successful it means that:

- there are no conflicts
  - no LHS values for the same identifier violate constraints or specify a different concrete value
- there are no syntax errors
- there are no values that are incomplete (unspecified)

Along the way [CUE Playground](https://cuelang.org/play/?id=#cue@export@cue) can be used to interact with CUE code.
`cue vet` can be used to troubleshoot a subset of files.

3. We'll use compact CLIs to output data in a format that can be ingested by the appropriate tool.

## Tutorial

This tutorial is pretty straightforward.
[Here is the repo](https://github.com/ptMcGit/cue-for-devops) with a commit for each major change to the repo.

### First Steps

1. Install cue if you haven't already.
- Go will need to be installed in order to install CUE.
2. Initialize the package with:

``` shell
$ cue mod init
```

3. We split the CUE configurations for each concern (Ansible, Terraform, etc.) into different files.
For general concerns create a file called `cuefordevops.cue`:

```
package cuefordevops
```

- Note that all `*.cue` files in this tutorial will need this exact line (it causes them to be included in the package).

Create `cuefordevops_tool.cue` file (the `_tool` suffix is required) which will support the CLI tools we create:

```
package cuefordevops
```

### Terraform

Our goal here is to have a single file for each project describing infrastructure that can be consumed by `terraform`.

Our baseline is a Terraform module in `./projects/terraform_modules` and the following files in each project:

- `main.tf.json`
- `variables.tf.json`

There aren't many differences between the two projects with regards to Terraform:

``` diff
$ diff projects/jupiter/terraform/main.tf.json projects/saturn/terraform/main.tf.json
51c51
<                         "values": ["jupiter*"]
---
>                         "values": ["saturn*"]

```

- different AMI filter is used

``` diff
$ diff projects/jupiter/terraform/variables.tf.json projects/saturn/terraform/variables.tf.json
9c9
<                 "default": "10.1.1.0/24"
---
>                 "default": "10.1.2.0/24"
```

- different CIDR blocks

### Creating the CUE Files

Before creating Terraform-specific files, add the following to `./cuefordevops.cue`:

```
#AwsProfile: *"development" | "qa" | "prod"
#AwsRegion: string | *"us-east-1"
```

- `#AwsProfile` is an enumeration with a default value of `development` (as indicated by the preference mark `*`; `|` is the join operator).
- `#AwsRegion` is a type that must be a string; it has a default value of `"us-east-1"`

Next, create `./terraform.cue` with the following:

```
package cuefordevops

terraformConfig: [string]: {}

#terraformConfig: {
	moduleAwsPublicSubnet: "../../terraform_modules/aws/subnet_public"
	availabilityZone:      "\(#AwsRegion)a"
	awsProfile:            #AwsProfile
	awsRegion:             #AwsRegion
	cidrBlock:             string
	instanceType:          string
	name:                  string
	tagAmiName:            string
	tagAwsVpc:             "servers"

	terraform: [
		{
			"terraform": {
				"required_providers": {
					"aws": {
						"source":  "hashicorp/aws"
						"version": ">= 4.17.1"
					}
				}
				"required_version": ">= 1.2.2"
			}
		},
		{
			"provider": {
				"aws": {
					"profile": "\(awsProfile)"
					"region":  "\(awsRegion)"
				}
			}
		},
		{
			"data": {
				"aws_vpc": {
					"this": {
						"filter": {
							"name": "tag:EnvironmentGroup"
							"values": ["\(tagAwsVpc)"]
						}
					}
				}
			}
		},
		{
			"module": {
				"aws_subnet_public": {
					"source":            "\(moduleAwsPublicSubnet)"
					"vpc_id":            "${data.aws_vpc.this.id}"
					"cidr_block":        "\(cidrBlock)"
					"availability_zone": "\(availabilityZone)"
				}
			}
		},
		{
			"data": {
				"aws_ami": {
					"this": {
						"most_recent": true
						"filter": {
							"name": "name"
							"values": ["\(tagAmiName)*"]
						}
					}
				}
			}
		},
		{
			"resource": {
				"aws_network_interface": {
					"this": {
						"subnet_id": "${module.aws_subnet_public.aws_subnet.id}"
					}
				}
			}
		},
		{
			"resource": {
				"aws_instance": {
					"this": {
						"ami":               "${data.aws_ami.this.id}"
						"instance_type":     "\(instanceType)"
						"availability_zone": "\(availabilityZone)"
						"network_interface": {
							"network_interface_id": "${aws_network_interface.this.id}"
							"device_index":         0
						}
					}
				}
			}
		},
	]
}
```

Note the following:

- `terraformConfig` is a template which will be merged with configurations for Saturn and Jupiter.
- The availability zone is derived from the region (string interpolation happens between `\(` `)`).
- `#AwsProfile` and `#AwsRegion` come from `./cuefordevops.cue`.
- Type constraints are indicated for various values, e.g. `cidrBlock` must be a `string`.
- We have hardcoded the VPC.
- The value for `terraform` contains the makings of what will be provided to Terraform later (note the various string interpolations).

Next add files with data specific to each project.


In `./projects/jupiter/terraform.cue`:

```
package cuefordevops

terraformConfig: "jupiter": #terraformConfig & {
	cidrBlock:    "10.1.1.0/24"
	instanceType: "t2.micro"
	name:         "jupiter"
	tagAmiName:   "jupiter-ubuntu"
}
```

`terraformConfig` is a template that will exist in the CUE runtime as provided by `./terraform.cue`.
What we are doing here is creating a value for the `jupiter` key on that template that merges the `#terrformConfig` type with a struct literal.


In `./projects/saturn/terraform.cue`:

```
package cuefordevops

terraformConfig: "saturn": #terraformConfig & {
	cidrBlock:    "10.1.2.0/24"
	instanceType: "t2.micro"
	name:         "saturn"
	tagAmiName:   "saturn-ubuntu"
}
```

Check that everything looks good by running these two commands in the root directory:

- `cue eval ./...` -- this will tell us if anything is broken
- `cue export ./...` -- this will output JSON, giving us a glimpse of how close we are to output that is ready for Terraform

Format all files by running `cue fmt ./...` in the root directory of the project.

### CUE Terraform CLI

Next, update `cuefordevops_tool.cue` with the following:

```
terraformObjectSets: terraformConfig

terraformObjects: [ for k, v in terraformObjectSets {v.terraform}]
```

- In the second line we are assigning the result of a list comprehension to `terraformObjects`.

These additions export the data in a way that is directly consumable by Terraform.

Next, create `terraform_tool.cue` which will just export Terraform data.

```
package cuefordevops

import (
	"encoding/json"
	"tool/exec"
	"tool/cli"
)

command: terraform: {
	task: technophage: exec.Run & {
		cmd:    "cat -"
		stdin:  json.MarshalStream(terraformObjects)
		stdout: string
	}

	task: display: cli.Print & {
		text: task.technophage.stdout
	}
}
```

Navigate to `/projects/jupiter` and run the following (this invokes `terraform_tool.cue`):

``` shell
cue cmd terraform ./... > terraform.cue.tf.json
```

With the proper data references in place `terraform.cue.tf.json` should be valid as reported by `terraform validate` after running `terraform init`.

Run the same commands in `./projects/saturn`.

### Ansible

Next, we will create the following for Ansible:

- a hosts file
- a playbook that will configure an instance being built by Packer.
- a playbook that will plan and apply in Terraform, and then configure the running instance.

Create the file `./ansible.cue` with the following:

```
package cuefordevops

import "list"

#AnsibleConfig: {
	hostsConfig: {
		name: string
		ipv4Addresses: [...string]
	}
	installPlaybookConfig: {
		playbook: [
			{
				hosts: "\(hostsConfig.name)"
				tasks: [
					{
						name: "Perform installation."
						"ansible.builtin.include_role": {
							name: "\(hostsConfig.name)"
						}
						tags: [
							"install",
						]
					},
				]
			}]
	}
	provisionPlaybookConfig: {
		playbook: [{
			hosts: "\(hostsConfig.name)"
			tasks: [
				{
					name: "Test the plan."
					"community.general.terraform": {
						project_path: "./"
						state:        "planned"
						force_init:   true
					}
					tags: [
						"provision",
					]
				},
				{
					name: "Apply the plan."
					"community.general.terraform": {
						project_path: "./"
						state:        "present"
					}
					tags: [
						"provision",
					]
				},
				{
					name: "Configure instances."
					"ansible.builtin.include_role": {
						name: "\(hostsConfig.name)"
					}
					tags: [
						"configure",
					]
				},
			]
		}]
	}

	hosts: [{all: children: (hostsConfig.name): hosts: {
		for i in list.Range(0, len(hostsConfig.ipv4Addresses), 1) {
			"\(hostsConfig.name)-\(i)": ansible_host: hostsConfig.ipv4Addresses[i]
		}
	}}]
	provisionPlaybooks: (hostsConfig.name): provisionPlaybookConfig.playbook
	installPlaybooks: (hostsConfig.name):   installPlaybookConfig.playbook
}

ansibleConfig: [string]: {}
```

Note the following:

- We have a comprehension that iterates over the IP addresses, creating a host entry for each; the accessor syntax (`.`) allows us to access fields on `hostsConfig`.
- We aggregate the data for installation and provision playbooks into `installationPlaybooks` and `provisionPlaybooks`, respectively; these are indexed by project name.

Create `./projects/jupiter/ansible.cue` with the following:

```
package cuefordevops

ansibleConfig: "jupiter": #AnsibleConfig & {
	"hostsConfig": {
		name: "jupiter"
		ipv4Addresses: ["10.1.1.100", "10.1.1.200"]
	}
}
```

Also, create `./projects/saturn/ansible.cue` with the following:

```
package cuefordevops

ansibleConfig: "saturn": #AnsibleConfig & {
	"hostsConfig": {
		name: "saturn"
		ipv4Addresses: ["10.1.2.100", "10.1.2.200"]
	}
}
```

`ansibleConfig` is a template into which configurations are merged.
Importantly, each configuration specifies a name with which to identify hosts and IP addresses.

Use the validation steps described earlier for checking the work.

### Ansible CLI Tools

Add the following lines to `cuefordevops_tool.cue` to provide data for our CUE Ansible CLI tools to utilize:

```
ansibleHostObjectSets: ansibleConfig

ansibleHostObjects: [ for k, v in ansibleConfig {v.hosts[0]}]

ansibleInstallPlaybookObjectSets: {for k, v in ansibleConfig {v.installPlaybooks}}

ansibleInstallPlaybookObjects: [ for k, v in ansibleInstallPlaybookObjectSets {v}]

ansibleProvisionPlaybookSets: {for k, v in ansibleConfig {v.provisionPlaybooks}}

ansibleProvisionPlaybookObjects: [ for k, v in ansibleProvisionPlaybookSets {v}]
```

Create `./ansibleHosts_tool.cue` which will create hosts files:

```
package cuefordevops

import (
	"encoding/yaml"
	"tool/exec"
	"tool/cli"
)

command: ansibleHosts: {
	task: cuefordevops: exec.Run & {
		cmd:    "cat -"
		stdin:  yaml.MarshalStream(ansibleHostObjects)
		stdout: string
	}

	task: display: cli.Print & {
		text: task.cuefordevops.stdout
	}
}
```

Navigate to `./projects/jupiter` and create a hosts file for Jupiter by running the following:

```
cue cmd ansibleHosts ./ > hosts.cue.yml
```

Do the same for the Saturn project.

Next, create `ansibleInstall_tool.cue` to create playbooks that can be used by Packer:

```
package cuefordevops

import (
	"encoding/yaml"
	"tool/exec"
	"tool/cli"
)

command: ansibleInstall: {
	task: cuefordevops: exec.Run & {
		cmd:    "cat -"
		stdin:  yaml.MarshalStream(ansibleInstallPlaybookObjects)
		stdout: string
	}

	task: display: cli.Print & {
		text: task.cuefordevops.stdout
	}
}
```

Navigate to `./projects/jupiter` and run the following to create the install playbook:

``` shell
cue cmd ansibleInstall ./ > playbook.install.cue.yml
```

Do the same in `projects/saturn`.

Finally, create `ansibleProvision_tool.cue` to create playbooks that provision instances with `terraform` and perform configuration tasks against the instances:

```
package cuefordevops

import (
	"encoding/yaml"
	"tool/exec"
	"tool/cli"
)

command: ansibleProvision: {
	task: cuefordevops: exec.Run & {
		cmd:    "cat -"
		stdin:  yaml.MarshalStream(ansibleProvisionPlaybookObjects)
		stdout: string
	}

	task: display: cli.Print & {
		text: task.cuefordevops.stdout
	}
}
```

Navigate to `./projects/jupiter` and run the following to create the provision playbook:

``` shell
cue cmd ansibleProvision ./ > playbook.provision.cue.yml
```

Run the same command in `projects/saturn`.

## Packer

Our goal with the Packer configuration data is to create a single JSON file for each project containing both the required `source` and `build` object specifications.

First, create `./packer.cue` with the following:

```
package cuefordevops

_amazonEbsSource:
{
	"ami_name":      string
	"instance_type": "t2.micro"
	"ssh_username":  string
	"region":        #AwsRegion
	"source_ami_filter": {
		"filters": {
			"image-id": string
		}
		"owners": ["679593333241"]
	}
}

_ansibleBuilder:
{

	"playbook_file": "./ansible/playbook.install.cue.yml"
	"ansible_env_vars": [
		"ANSIBLE_ROLES_PATH=../../../ansible_roles",
	]
	"extra_arguments": [...string]

}

packerConfig: [string]: {}

#PackerConfig: {

	sourceConfig: {
		name:       string
		os:         string
		sourceType: string
	}

	buildConfig: {

		buildType_: string
	}

	build: sources: ["sources.\(sourceConfig.sourceType).\(sourceConfig.name)"]
	build: name: sourceConfig.name

	if buildConfig.buildType_ == "amiBuilder" {
		build: provisioner: ansible: {
			if sourceConfig.os == "ubuntu" {
				"extra_arguments": ["--user", "ubuntu", "--tags", "install"]
			}

		} & _ansibleBuilder
	}

	if sourceConfig.sourceType == "amazon-ebs" {

		_ami_name: "\(sourceConfig.name)-\(sourceConfig.os)"

		let Source = sourceConfig
		if sourceConfig.os == "ubuntu" {
			_ssh_username: "ubuntu"
			source: "\(Source.sourceType)": (Source.name): {
				"ami_name":     _ami_name
				"ssh_username": _ssh_username
				"source_ami_filter": {
					"filters": {
						"image-id": "ami-0b9d9398cc54985a5"
					}
				}
			} & _amazonEbsSource
		}
	}
}
```

Note the following:

- we utilize `#AwsRegion` again
- notice that we have hidden structs `_amazonEbsSourceVersions` and `_ansibleBuilderVersions` (the `_` prefix causes them to be hidden)
- we have `extra_arguments` as an open-ended list (as indicated by `...`) with the constraint that the items must be `string`s
- importantly, we add the source to the `sources` list
- notice the conditional logic

`packerConfig` is a template into which configurations are merged.

Next, create `./projects/jupiter/packer.cue`:

```
package cuefordevops

packerConfig: "jupiter": #PackerConfig & {
	sourceConfig: {
		name:       "jupiter"
		sourceType: "amazon-ebs"
		os:         "ubuntu"
	}
	buildConfig: {
		buildType_: "amiBuilder"
	}
}
```

This design attempts to solve the problem of needing to couple source and builder data.
Importantly, this configuration indicates a Packer source (identified by `amazon-ebs`) and a Packer build (identified by `amiBuilder`).

For Saturn create `./projects/saturn/packer.cue`:

```
package cuefordevops

packerConfig: "saturn": #PackerConfig & {
	sourceConfig: {
		name:       "saturn"
		sourceType: "amazon-ebs"
		os:         "ubuntu"
	}
	buildConfig: {
		buildType_: "amiBuilder"
	}
}
```

Use the validation steps described earlier to check the work.

### Packer CLI Tool

Add the following lines to `cuefordevops_tool.cue` to provide data for our CUE Packer tool to utilize:

```
packerObjectSets: packerConfig

_packerSourceObjects: [ for k, v in packerObjectSets {"source": v.source}]

_packerBuildObjects: [ for k, v in packerObjectSets {"build": v.build}]

packerObjects: [list.Concat([_packerSourceObjects, _packerBuildObjects])]
```

Create the `packer_tool.cue` file which is similar to the other tool files:

```
package cuefordevops

import (
	"encoding/json"
	"tool/exec"
	"tool/cli"
)

command: packer: {
	task: cuefordevops: exec.Run & {
		cmd:    "cat -"
		stdin:  json.MarshalStream(packerObjects)
		stdout: string
	}

	task: display: cli.Print & {
		text: task.cuefordevops.stdout
	}
}
```

Navigate to `./projects/jupiter` and run the following to create a JSON file that Packer can consume:

``` shell
cue cmd packer ./ > packer.cue.pkr.json
```

Do the same in `projects/saturn`.

### Additional Constraints and Validation

We can tighten things up further by adding additional constraints and validation to the `cuefordevops.cue` file.
The following sections provide a solution in CUE to a given problem.

#### 1. How do we ensure the AMI built by Packer is used by Terraform?

Use the following:

```
// Check that the terraform config uses the AMI from the packer config

amiValid: true

for tcKey, tcVal in terraformConfig {

	for pcKey, pcVal in packerConfig {

		if (tcKey == pcKey) {
			for _, builder in pcVal.source {
				for _, project in builder {
					amiValid: project.ami_name == tcVal.tagAmiName
				}
			}
		}
	}
}
```

- here we have the key-value pair `amiValid`; CUE will merge each instance of these and if any of these don't agree on value, e.g. an expression evaluates such that `amiValid: false`, an error will be thrown

#### 2. How do we prevent two projects from using the same CIDR block?

Use the following:

```
_allCidrBlocks: [
	for k, v in terraformConfig {v.cidrBlock},
]

_uniqCidrBlocks: [
	for i, x in _allCidrBlocks
	if !list.Contains(list.Drop(_allCidrBlocks, i+1), x) {
		x
	},
]

noCidrCollisions: true
noCidrCollisions: len(_allCidrBlocks) == len(_uniqCidrBlocks)
```

- we collect all CIDR blocks and separately determine unique CIDR blocks; if the lengths of the two are not equal we'll have a conflict in `noCidrCollisions`

#### 3. How can we make sure the CIDR blocks are valid and that the IP addresses allocated are in those blocks?

Use the following:

```
// Multiple checks for all CIDRs and IP addresses

for k, v in terraformConfig {

	// check CIDR is ipv4 with /24 mask
  cidrsValid: (k): true
	cidrsValid: (k): v.cidrBlock =~ "^10\\.(([0-9]|[1-9][0-9]|[1-2][0-5][0-5])\\.){2}0\/24$"

	for l, w in ansibleConfig {
		if (k == l) {
			for i in list.Range(0, len(w.hostsConfig.ipv4Addresses), 1) {
				// check ipv4 address is within CIDR
        ipAddressesValid: (k): true
				ipAddressesValid: (k): w.hostsConfig.ipv4Addresses[i] =~ "^"+strings.Join(strings.Split(v.cidrBlock, ".")[0: 3], "\\.")+"\\.([0-9]|[1-9][0-9]|[1-2][0-5][0-5])$"
			}
		}
	}
}
```

- we iterate over each `terraformConfig` and check it against a regular expression that describes a valid CIDR block -- a `10` in the first octet and a 24-bit mask
- we iterate over each `ansibleConfig` and check the preferred IP addresses are in the block

### Injecting Values at Runtime

Sometimes values need to be bound at runtime.
Tags allow us to inject values at runtime.

Update `cuefordevops.cue` with the following revisions:

```
#AwsProfile: *"development" | "qa" | "prod" | string @tag(awsProfile)
#AwsRegion: string | *"us-east-1" | string @tag(awsRegion)
```

We can now set `awsProfile` and `awsRegion` at runtime:

``` shell
cue export ./... --inject="awsProfile=qa" --inject="awsRegion=us-west-1"
```

### Final Thoughts

There is certainly room for additional improvements.

Hopefully this tutorial has demonstrated how CUE can help to better manage IaC and related concerns.
