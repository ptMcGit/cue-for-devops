package cuefordevops

terraformConfig: "saturn": #terraformConfig & {
	cidrBlock:    "10.1.2.0/24"
	instanceType: "t2.micro"
	name:         "saturn"
	tagAmiName:   "saturn-ubuntu"
}
