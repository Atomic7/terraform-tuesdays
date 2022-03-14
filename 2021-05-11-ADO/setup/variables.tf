variable "ado_org_service_url" {
  type        = string
  description = "Org service url for Azure DevOps"
  default     = "https://dev.azure.com/ned-in-the-cloud/ADO"
}

variable "ado_github_repo" {
  type        = string
  description = "Name of the repository in the format <GitHub Org>/<RepoName>"
  default     = "atomic7/terraform-tuesdays"
}

variable "ado_pipeline_yaml_path_1" {
  type        = string
  description = "Path to the yaml for the first pipeline"
  default     = "2021-05-11-ADO/vnet/azure-pipelines.yaml"
}

variable "ado_github_pat" {
  type        = string
  description = "Personal authentication token for GitHub repo"
  sensitive   = true
  default     = "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"
}

variable "prefix" {
  type        = string
  description = "Naming prefix for resources"
  default     = "tacos"
}

variable "az_location" {
  type    = string
  default = "westeurope"
}

variable "az_container_name" {
  type        = string
  description = "Name of container on storage account for Terraform state"
  default     = "terraform-state"
}

variable "az_state_key" {
  type        = string
  description = "Name of key in storage account for Terraform state"
  default     = "key1" #"terraform.tfstate"
}

variable "az_client_id" {
  type        = string
  description = "Client ID with permissions to create resources in Azure, use env variables"
  default     = "fe40b964-81a6-42f6-8f0e-e205c8c9a4b9"
}

variable "az_client_secret" {
  type        = string
  description = "Client secret with permissions to create resources in Azure, use env variables"
  default     = "cZFkJ83-hOsPGWLxlTLTELG37U2hhKvc-H:"
}

variable "az_subscription" {
  type        = string
  description = "Client ID subscription, use env variables"
  default     = "df762d06-9685-438e-aed0-d55b807198a7"
}

variable "az_tenant" {
  type        = string
  description = "Client ID Azure AD tenant, use env variables"
  default     = "b7540979-5063-4ba1-a9a0-49b436141ffb"
}

resource "random_integer" "suffix" {
  min = 10000
  max = 99999
}

locals {
  ado_project_name        = "${var.prefix}-project-${random_integer.suffix.result}"
  ado_project_description = "Project for ${var.prefix}"
  ado_project_visibility  = "private"
  ado_pipeline_name_1     = "${var.prefix}-pipeline-1"

  az_resource_group_name  = "${var.prefix}${random_integer.suffix.result}"
  az_storage_account_name = "${lower(var.prefix)}${random_integer.suffix.result}"

}