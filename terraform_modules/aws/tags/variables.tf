variable "name" {
  type = string
  default = ""
}

variable "company_name" {
  type = string
  default = "DMinor7Flat9"
}

variable "project_name" {
type = string
default = "none"
}

variable "environment_group" {
type = string
default = "none"
description = "The environment, e.g. development, production, etc."
}

variable "git_branch" {
type = string
default = "none"
description = "The git branch for the environment, e.g. master, feature-244, etc."
}

variable "description" {
type = string
default = "none"
}

variable "favorited" {
type = bool
default = false
description = "All resources start out as not favorited."
}

variable "included" {
type = bool
default = true
description = "All resources start out as included."
}

variable "additional_tags" {
type = map(string)
default = {
EnvironmentGroup = "fuck"
}
description = "Additional tags to consolidate with required tags."
}

# variable "VPCGroup" {
# type = string
# default = "none"
# description = "The VPC in which this resource should be situated."
# }
# variable "TenantName" {
# type = string
# default = "none"
# }
