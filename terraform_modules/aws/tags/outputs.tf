locals {
  tags = {
    Name             = var.name
    CompanyName      = var.company_name
#    TenantName      = var.tenant_name
    ProjectName      = var.project_name
    EnvironmentGroup = var.environment_group
    GitBranch        = var.git_branch
    Description      = var.description
    ManagedByTerraform = true
  }
}

output "tags" {
description = "Combined map of required and optional tags."
value = merge(local.tags, var.additional_tags)
}
