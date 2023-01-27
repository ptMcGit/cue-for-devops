package cuefordevops

terraformObjectSets: terraformConfig

terraformObjects: [ for k, v in terraformObjectSets {v.terraform}]

ansibleHostObjectSets: ansibleConfig

ansibleHostObjects: [ for k, v in ansibleConfig {v.hosts[0]}]

ansibleInstallPlaybookObjectSets: {for k, v in ansibleConfig {v.installPlaybooks}}

ansibleInstallPlaybookObjects: [ for k, v in ansibleInstallPlaybookObjectSets {v}]

ansibleProvisionPlaybookSets: {for k, v in ansibleConfig {v.provisionPlaybooks}}

ansibleProvisionPlaybookObjects: [ for k, v in ansibleProvisionPlaybookSets {v}]
