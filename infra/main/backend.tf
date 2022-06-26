terraform {
  required_version = ">= 0.14.8"

  backend "s3" {
    bucket = "juv-shun.tfstate"
    key    = "csv-database-importer/tfstate.tf"
    region = "ap-northeast-1"
  }
}

provider "aws" {
  region = "ap-northeast-1"
}

variable "service_name" {
  default = "csv-database-importer"
}

variable "s3_bucket" {}

data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket = "juv-shun.tfstate"
    key    = "csv-database-importer/external/tfstate.tf"
    region = "ap-northeast-1"
  }
}
