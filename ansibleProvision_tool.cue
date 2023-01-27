package cuefordevops

import (
	"encoding/yaml"
	"tool/exec"
	"tool/cli"
)

command: ansibleProvision: {
	task: cuefordevops: exec.Run & {
		cmd:    "cat -"
		stdin:  yaml.MarshalStream(ansibleProvisionPlaybookObjects)
		stdout: string
	}

	task: display: cli.Print & {
		text: task.cuefordevops.stdout
	}
}
