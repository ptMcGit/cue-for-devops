package cuefordevops

import (
	"encoding/yaml"
	"tool/exec"
	"tool/cli"
)

command: ansibleHosts: {
	task: cuefordevops: exec.Run & {
		cmd:    "cat -"
		stdin:  yaml.MarshalStream(ansibleHostObjects)
		stdout: string
	}

	task: display: cli.Print & {
		text: task.cuefordevops.stdout
	}
}
