package cuefordevops

terraformObjectSets: terraformConfig

terraformObjects: [ for k, v in terraformObjectSets {v.terraform}]
