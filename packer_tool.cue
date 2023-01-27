package cuefordevops

import (
	"encoding/json"
	"tool/exec"
	"tool/cli"
)

command: packer: {
	task: cuefordevops: exec.Run & {
		cmd:    "cat -"
		stdin:  json.MarshalStream(packerObjects)
		stdout: string
	}

	task: display: cli.Print & {
		text: task.cuefordevops.stdout
	}
}
