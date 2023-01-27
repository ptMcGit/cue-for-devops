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
