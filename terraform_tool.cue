package cuefordevops

import (
	"encoding/json"
	"tool/exec"
	"tool/cli"
)

command: terraform: {
	task: technophage: exec.Run & {
		cmd:    "cat -"
		stdin:  json.MarshalStream(terraformObjects)
		stdout: string
	}

	task: display: cli.Print & {
		text: task.technophage.stdout
	}
}
