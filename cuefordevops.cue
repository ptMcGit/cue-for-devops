package cuefordevops

import (
	"strings"
	"list"
)

#AwsProfile: *"development" | "qa" | "prod" | string @tag(awsProfile)
#AwsRegion:  string | *"us-east-1" | string          @tag(awsRegion)

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
