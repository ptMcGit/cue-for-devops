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
