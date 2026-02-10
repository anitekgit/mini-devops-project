terraform {
  required_version = ">= 1.0.0"

  backend "s3" {
    bucket                  = "terraform-s3-state-isengard"
    key                     = "isengard-project"
    region                  = "us-east-1"
    shared_credentials_file = "~/.aws/credentials"
    use_lockfile = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0"
    }
  }
}
