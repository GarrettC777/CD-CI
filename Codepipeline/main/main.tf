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

# Define the VPC
resource "aws_vpc" "the_main" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags {
    Name = "main-vpc"
  }
}

# Define the public subnet
resource "aws_subnet" "public-subnet" {
  vpc_id = "${aws_vpc.the_main.id}"
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-west-2"

  tags {
    Name = "public subnet"
  }
}

# Define the private subnet
resource "aws_subnet" "private-subnet" {
  vpc_id = "${aws_vpc.the_main.id}"
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-west-2"

  tags {
    Name = "private subnet"
  }
}

# Define the internet gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = "${aws_vpc.the_main.id}"

  tags {
    Name = "VPC IGW"
  }
}

# Define the route table
resource "aws_route_table" "public-rt" {
  vpc_id = "${aws_vpc.default.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.gw.id}"
  }

  tags {
    Name = "Public Subnet RT"
  }
}

# Assign the route table to the public Subnet
resource "aws_route_table_association" "public-rt" {
  subnet_id = "${aws_subnet.public-subnet.id}"
  route_table_id = "${aws_route_table.public-rt.id}"
}
