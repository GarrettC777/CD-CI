# Provider ----------------------------------------------------------------------------------------------------
# Specify AWS services and infrastructure. 
provider "aws" { 
	region = "us-west-2"
}


# S3 Bucket ---------------------------------------------------------------------------------------------------
# Required function call for backend of the s3 bucket called cit481gps3bucket stored in s3.tf.
terraform {
    backend  "s3" {
    region         = "us-west-2"
    bucket         = "cit481gps3bucket"
    # The key can be specified by different users, but it must remain the same for consistency
    key            = "remotesession" 
    dynamodb_table = "tf-state-lock"
    }
} 
 

# CodeCommit --------------------------------------------------------------------------------------------------
# This resource creates a blank CodeCommit data repository 
resource "aws_codecommit_repository" "test" {
  repository_name = "MyRepository"
  description     = "This is a blank CodeCommit data repository"
}


# EC2 Instance ------------------------------------------------------------------------------------------------
resource "aws_instance" "main" {
  ami                  = "ami-0d6621c01e8c2de2c"
  instance_type        = "t2.micro"
  key_name             = "kp1"
  subnet_id            = "subnet-04c19729b0ae97ce0" 
  associate_public_ip_address = true
  iam_instance_profile = "${aws_iam_instance_profile.main.name}"

  vpc_security_group_ids = [
    "${aws_security_group.http.id}",
    "${aws_security_group.ssh.id}",
    "${aws_security_group.allow_all_outbound.id}",
  ]

  tags = {
    Name = "PipelineDemo"
  }

  provisioner "remote-exec" {
    script = "./install_codedeploy_agent.sh"

    connection {
      host        = aws_instance.main.public_ip
      agent       = false
      type        = "ssh"
      user        = "ec2-user"
      private_key = "${file("~/Desktop//kp1.pem")}"
    }
  }
}


# Security Groups ---------------------------------------------------------------------------------------------
resource "aws_security_group" "http" {
  name        = "allow-http"
  description = "Allow all http inbound traffic"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "ssh" {
  name        = "allow-ssh"
  description = "Allow ssh traffic"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "allow_all_outbound" {
  name        = "allow-all-outbound"
  description = "Allow outbound traffic"

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}


# CodeDeploy --------------------------------------------------------------------------------------------------
# Create a service (IAM) role for codedeploy
resource "aws_iam_role" "codedeploy_service" {
  name = "codedeploy-service-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": [
          "codedeploy.amazonaws.com"
        ]
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

# attach AWS managed policy called AWSCodeDeployRole required for deployments which are to an EC2 compute platform
resource "aws_iam_role_policy_attachment" "codedeploy_service" {
  role       = "${aws_iam_role.codedeploy_service.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole"
}

# create a service (IAM) role for ec2 
resource "aws_iam_role" "instance_profile" {
  name = "codedeploy-instance-profile"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": [
          "ec2.amazonaws.com"
        ]
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

# provide ec2 access to s3 bucket to download revision. This role is needed by the CodeDeploy agent on EC2 instances.
resource "aws_iam_role_policy_attachment" "instance_profile_codedeploy" {
  role       = "${aws_iam_role.instance_profile.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforAWSCodeDeploy"
}

resource "aws_iam_instance_profile" "main" {
  name = "codedeploy-instance-profile"
  role = "${aws_iam_role.instance_profile.name}"
}

# Create a CodeDeploy application
resource "aws_codedeploy_app" "main" {
  name = "Deployed_Application"
}

# Create a deployment group
resource "aws_codedeploy_deployment_group" "main" {
  app_name              = "${aws_codedeploy_app.main.name}"
  deployment_group_name = "Deploy_Group"
  service_role_arn      = "${aws_iam_role.codedeploy_service.arn}"

  deployment_config_name = "CodeDeployDefault.OneAtATime" # AWS defined deployment config

  # Trigger a rollback on deployment failure event
  auto_rollback_configuration {
    enabled = true
    events = [
      "DEPLOYMENT_FAILURE",
    ]
  }
}


# Pipeline (pathway) -----------------------------------------------------------------------------------------
# S3 bucket storage container 
resource "aws_s3_bucket" "codepipeline_bucket" {
  bucket = "cit481-artifacts1"

  versioning {
    enabled = true
  }
}

# IAM Role for the Codepipeline 
resource "aws_iam_role" "codepipeline_role" {
  name = "test-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codepipeline.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

# IAM Role Policy for the Codepipeline 
resource "aws_iam_role_policy" "codepipeline_policy" {
  name = "codepipeline_policy"
  role = "${aws_iam_role.codepipeline_role.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect":"Allow",
      "Action": [
        "s3:GetObject",
        "s3:GetObjectVersion",
        "s3:GetBucketVersioning",
        "s3:PutObject"
      ],
      "Resource": [
        "${aws_s3_bucket.codepipeline_bucket.arn}",
        "${aws_s3_bucket.codepipeline_bucket.arn}/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "codebuild:BatchGetBuilds",
        "codebuild:StartBuild"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

# KMS encryption key for the data
resource "aws_kms_key" "s3kmskey" {
  description             = "KMS key 1"
  deletion_window_in_days = 10
}

# Provides an alias (name) for the KMS encryption key above 
resource "aws_kms_alias" "s3kmskey" {
  name          = "alias/myKmsKey"
  target_key_id = "${aws_kms_key.s3kmskey.key_id}"
}

# The codepipeline 
resource "aws_codepipeline" "codepipeline" {
  name     = "tf-test-pipeline"
  role_arn = "${aws_iam_role.codepipeline_role.arn}"

  artifact_store {
    location = "${aws_s3_bucket.codepipeline_bucket.bucket}"
    type     = "S3"

    # Used a KMS encryption key below instead of a data resource to keep data local and encrypted
    encryption_key {
      id   = "${aws_kms_alias.s3kmskey.arn}"
      type = "KMS"
    }
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeCommit"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        Owner  = "the-group"
        Repo   = "project"
        Branch = "master" 
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "CodeDeploy"
      input_artifacts = ["build_output"]
      version         = "1"

      configuration = {
        ActionMode     = "REPLACE_ON_FAILURE"
        Capabilities   = "CAPABILITY_AUTO_EXPAND,CAPABILITY_IAM"
        OutputFileName = "CreateStackOutput.json"
        StackName      = "MyStack"
        TemplatePath   = "build_output::sam-templated.yaml"
      }
    }
  }
}
