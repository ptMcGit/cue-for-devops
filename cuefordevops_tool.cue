package cuefordevops

import (
	"list"
)

terraformObjectSets: terraformConfig

terraformObjects: [ for k, v in terraformObjectSets {v.terraform}]

ansibleHostObjectSets: ansibleConfig

ansibleHostObjects: [ for k, v in ansibleConfig {v.hosts[0]}]

ansibleInstallPlaybookObjectSets: {for k, v in ansibleConfig {v.installPlaybooks}}

ansibleInstallPlaybookObjects: [ for k, v in ansibleInstallPlaybookObjectSets {v}]

ansibleProvisionPlaybookSets: {for k, v in ansibleConfig {v.provisionPlaybooks}}

ansibleProvisionPlaybookObjects: [ for k, v in ansibleProvisionPlaybookSets {v}]

packerObjectSets: packerConfig

_packerSourceObjects: [ for k, v in packerObjectSets {"source": v.source}]

_packerBuildObjects: [ for k, v in packerObjectSets {"build": v.build}]

packerObjects: [list.Concat([_packerSourceObjects, _packerBuildObjects])]
