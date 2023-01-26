package cuefordevops

terraformConfig: "jupiter": #terraformConfig & {
	cidrBlock:    "10.1.1.0/24"
	instanceType: "t2.micro"
	name:         "jupiter"
	tagAmiName:   "jupiter-ubuntu"
}
