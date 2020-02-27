provider "aws" {
  region  = "us-west-2"
  profile = "default"
}

resource "aws_s3_bucket" "b" {
  bucket = "thegroupdotbucket"
  acl    = "private"

  tags = {
    Name        = "My bucket"
    Environment = "Dev"
  }
}

resource "aws_codecommit_repository" "test" {
  repository_name = "MyTestRepository"
  description     = "This is the Sample App Repository"
}
