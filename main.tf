provider "aws" {
  region  = "us-west-2"
  profile = "default"
}

terraform {
    backend "s3" {
    region          = "us-west-2"
    bucket          = "thegroupdotbucket"
    key             = "main/terraform.tfstate"
    dynamodb_table  = "tf-state-lock"
    }
}
resource "aws_s3_bucket" "b" {
  bucket = "thegroupdotbucket"
  acl    = "private"

  vesioning {
    enabled = true
  }

  tags = {
    Name        = "My bucket"
    Environment = "Dev"
  }
}

resource "aws_codecommit_repository" "test" {
  repository_name = "MyTestRepository"
  description     = "This is the Sample App Repository"
}
