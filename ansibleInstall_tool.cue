package cuefordevops

import (
	"encoding/yaml"
	"tool/exec"
	"tool/cli"
)

command: ansibleInstall: {
	task: cuefordevops: exec.Run & {
		cmd:    "cat -"
		stdin:  yaml.MarshalStream(ansibleInstallPlaybookObjects)
		stdout: string
	}

	task: display: cli.Print & {
		text: task.cuefordevops.stdout
	}
}
