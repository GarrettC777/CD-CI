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

  versioning {
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

resource "aws_iam_group" "thegroup" {
  name   = "thegroup"
  path   = "/cit480/"
}

resource "aws_iam_user" "user_creation" {
  count  = "${length(var.username)}"
  name   = "${element(var.username, count.index)}"
  path   = "/cit480/"
}

resource "aws_iam_user_group_membership" "add" {
  count = "${length(var.username)}"
  user = "${element(var.username, count.index)}"

  groups = [
    "${aws_iam_group.thegroup.name}",
  ]
}

resource "aws_iam_group_policy" "cit480policy" {
  name = "cit480policy"
  group = "${aws_iam_group.thegroup.id}"
  
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "*",
      "Resource": "*"
    }
  ]
}
POLICY
}

 resource "aws_iam_user_login_profile" "loginprofile" {
  count  = "${length(var.username)}"
  user = "${element(var.username, count.index)}"
  pgp_key = "${element(var.keybase, count.index)}"
}

output "password" {
  value = "${aws_iam_user_login_profile.loginprofile.*.encrypted_password}"
}
