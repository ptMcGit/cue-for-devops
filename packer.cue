#ubuntu: "ubuntu"

#ubuntuAmiFilter: {
    "filters": {
        "image-id": string
    }
    "owners": ["679593333241"]
}

#environment: string @tag(environment,type=string)
#project: string @tag(project,type=string)

#packerSubnetFilter: {
    "tag:ProjectName" : "packer"
}

#ubuntuSource: "\(#ubuntu)": {
    "ami_name": "\( #project )-\(#ubuntu)-\( #environment )",
    "ssh_username": string | *"ubuntu",
    "subnet_filter": #packerSubnetFilter,
    "ami_filter": #ubuntuAmiFilter
    "instance_type": string | *"t2.micro"

    // if #environment == "prod" {
    //     "instance_type": "t2.large"
    // }

    // if #environment == "qa" {
    //     "instance_type": "t2.micro"
    // }
}

#ubuntuBuilder: {
    "name": "\( #project )-\(#ubuntu)-\( #environment )-builder",
    "sources": ["source.amazon-ebs.\(#ubuntu)"],
    "provisioner": {
        "ansible": {
            "playbook_file": string | *"../ansible/playbook",
            "extra_arguments": [
                "--extra-vars",
                "ENVIRONMENT=\( #environment )",
                "--tags",
                "\( #environment )"
            ]
        }
    }
}

// #amazonLinux2: "amazon-linux-2": {
//     "ami_name":
"source": {
    "amazon-ebs": #ubuntuSource
}
"build": #ubuntuBuilder


//}
