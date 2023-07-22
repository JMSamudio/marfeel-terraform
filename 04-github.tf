variable "branch" {
  description = "branch name: "
  type        = string
}

terraform {
  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 5.0"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.7.0"
    }
  }
}

provider "github" {
    owner = "JMSamudio"
}

resource "github_branch" "marfeel" {
  repository = "marfeel-app"
  branch     = "${terraform.workspace == "production" ? "main" : var.branch}"
}