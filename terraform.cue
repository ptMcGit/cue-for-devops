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
