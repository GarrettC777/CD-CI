# Specify AWS services and infrastructure. 
provider "aws" { 
	region = "us-west-2"
}


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
 

# This resource creates a blank CodeCommit data repository 
resource "aws_codecommit_repository" "test" {
  repository_name = "MyTestRepository"
  description     = "This is the Sample App Repository"
}







