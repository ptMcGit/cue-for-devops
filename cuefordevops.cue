package cuefordevops

import (
	"strings"
	"list"
)

#AwsProfile: *"development" | "qa" | "prod"
#AwsRegion:  string | *"us-east-1"
