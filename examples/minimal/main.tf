terraform {
  required_version = ">= 1.5.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 7.17, < 8.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = ">= 7.17, < 8.0"
    }
  }
}

variable "project_id" {
  description = "Project that hosts the security policy."
  type        = string
}

module "this" {
  source = "../../"

  name       = "example"
  project_id = var.project_id
  context = {
    organization = "olensys"
    environment  = "test"
    application  = "example"
    owner        = "platform"
    cost_center  = "eng"
  }
}

output "self_link" {
  description = "Self link of the security policy."
  value       = module.this.self_link
}
