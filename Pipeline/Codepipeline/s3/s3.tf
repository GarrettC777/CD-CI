# AWS services and infrastructure 
provider "aws" { 
	region = "us-west-2"
}

# S3 bucket storage container 
resource "aws_s3_bucket" "tf-remote-state" {
  bucket = "cit481gps3bucket"

  versioning {
    enabled = true
  }

  lifecycle {
    prevent_destroy = false
  }
}

# State Lock for the S3 Bucket 
resource "aws_dynamodb_table" "dynamodb-tf-state-lock" {
  name            = "tf-state-lock" 
  hash_key        = "LockID"
  read_capacity   = 20
  write_capacity = 20

  attribute {
    name = "LockID"
    type = "S"
  }
} 
