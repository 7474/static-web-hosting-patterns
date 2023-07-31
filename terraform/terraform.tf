terraform {
  backend "remote" {
    organization = "koudenpa"
    workspaces {
      name = "static-web-hosting-patterns"
    }
  }
}

provider "aws" {
  region     = "ap-northeast-1"
  access_key = var.access_key
  secret_key = var.secret_key

  default_tags {
    tags = {
      Environment = "static-web-hosting-patterns"
    }
  }
}