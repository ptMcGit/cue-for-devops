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
