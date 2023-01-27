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
