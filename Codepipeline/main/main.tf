# Specify AWS services and infrastructure. 
provider "aws" {
  region = "us-west-2"
}

# Required function call for backend of the s3 bucket called cit481gps3bucket stored in s3.tf.
terraform {
  backend "s3" {
    region = "us-west-2"
    bucket = "cit481gp3bucket"

    # The key can be specified by different users, but it must remain the same for consistency
    key            = "terraform.tfstate"
    dynamodb_table = "be-lock"
  }
}

# This resource creates a blank CodeCommit data repository 
resource "aws_codecommit_repository" "test" {
  repository_name = "MyTestRepository"
  description     = "This is the Sample App Repository"
}

# Define the VPC
resource "aws_vpc" "the_main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "main-vpc"
  }
}

# Define the public subnet 1
resource "aws_subnet" "public-subnet-1" {
  vpc_id            = "${aws_vpc.the_main.id}"
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-west-2a"

  tags = {
    Name = "public subnet 1"
  }
}

# Define the public subnet 2
resource "aws_subnet" "public-subnet-2" {
  vpc_id            = "${aws_vpc.the_main.id}"
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-west-2b"

  tags = {
    Name = "public subnet 2"
  }
}

# Define the private subnet 1
resource "aws_subnet" "private-subnet-1" {
  vpc_id            = "${aws_vpc.the_main.id}"
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-west-2a"

  tags = {
    Name = "private subnet 1"
  }
}

# Define the private subnet 2
resource "aws_subnet" "private-subnet-2" {
  vpc_id            = "${aws_vpc.the_main.id}"
  cidr_block        = "10.0.4.0/24"
  availability_zone = "us-west-2b"

  tags = {
    Name = "private subnet 2"
  }
}

# Define the internet gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = "${aws_vpc.the_main.id}"

  tags = {
    Name = "VPC IGW"
  }
}

# Define NAT Gateway
resource "aws_nat_gateway" "ngw" {
  allocation_id = "${aws_eip.nat.id}"
  subnet_id     = "${aws_subnet.public-subnet-1.id}"

  tags = {
  Name = "gw NAT"
  }
}

# Define the public route table
resource "aws_route_table" "public-rt" {
  vpc_id = "${aws_vpc.the_main.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.igw.id}"
  }

  tags = {
    Name = "Public Subnet RT"
  }
}

# Define the private route table
resource "aws_route_table" "private-rt" {
  vpc_id = "${aws_vpc.the_main.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_nat_gateway.ngw.id}"
  }

  tags = {
    Name = "Private Subnet RT"
  }
}

# Assign the public route table to the public Subnet 1
resource "aws_route_table_association" "public-rt-assoc-1" {
  subnet_id      = "${aws_subnet.public-subnet-1.id}"
  route_table_id = "${aws_route_table.public-rt.id}"
}

# Assign the public route table to the public Subnet 2
resource "aws_route_table_association" "public-rt-assoc-2" {
  subnet_id      = "${aws_subnet.public-subnet-2.id}"
  route_table_id = "${aws_route_table.public-rt.id}"
}

# Assign the private route table to the private Subnet 1
resource "aws_route_table_association" "private-rt-assoc-1" {
  subnet_id      = "${aws_subnet.private-subnet-1.id}"
  route_table_id = "${aws_route_table.private-rt.id}"
}

# Assign the private route table to the private Subnet 2
resource "aws_route_table_association" "private-rt-assoc-2" {
  subnet_id      = "${aws_subnet.private-subnet-2.id}"
  route_table_id = "${aws_route_table.private-rt.id}"
}

# Define Elastic IP address
resource "aws_eip" "nat" {
  vpc      = true
   depends_on = ["aws_internet_gateway.igw"]
}

# Create a new load balancer
resource "aws_elb" "elb" {
  name               = "vpc-elb"
  #availability_zones = ["us-west-2a","us-west-2b"]
  subnets = ["${aws_subnet.public-subnet-1.id}", "${aws_subnet.public-subnet-2.id}"]
  security_groups = ["${aws_security_group.allow_http.id}"]

  listener {
    instance_port     = 8000
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:8000/"
    interval            = 30
  }

  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400

  tags = {
    Name = "discource-elb"
  }
}

resource "aws_elb_attachment" "yup" {
  elb      = "${aws_elb.elb.id}"
  instance = "${aws_instance.webserver.id}"

  depends_on = ["aws_elb.elb"]
}