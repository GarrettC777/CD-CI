resource "aws_instance" "bastion" {
  ami           = "ami-0d1cd67c26f5fca19"
  instance_type = "t2.micro"
  vpc_security_group_ids = ["${aws_security_group.bastion-host-sg.id}"]
  subnet_id = "${aws_subnet.public-subnet-1.id}"
  key_name = "${aws_key_pair.ssh-bastion-key.key_name}"
  associate_public_ip_address = true
  
  tags = {
    Name = "Bastion Host"
  }
}

resource "aws_instance" "webserver1" {
  ami           = "ami-0d1cd67c26f5fca19"
  instance_type = "t2.micro"
  vpc_security_group_ids = ["${aws_security_group.vpc-secure-maintenance-sg.id}"]
  subnet_id = "${aws_subnet.private-subnet-1.id}"
  key_name = "${aws_key_pair.ssh-bastion-key.key_name}"
  iam_instance_profile = "${aws_iam_instance_profile.ec2-profile.name}"
  user_data = "${file("codedeploy.sh")}"

  tags = {
    Name = "Web Server"
  }
}

resource "aws_instance" "webserver2" {
  ami           = "ami-0d1cd67c26f5fca19"
  instance_type = "t2.micro"
  vpc_security_group_ids = ["${aws_security_group.vpc-secure-maintenance-sg.id}"]
  subnet_id = "${aws_subnet.private-subnet-2.id}"
  key_name = "${aws_key_pair.ssh-bastion-key.key_name}"
  iam_instance_profile = "${aws_iam_instance_profile.ec2-profile.name}"
  user_data = "${file("codedeploy.sh")}"

  tags = {
    Name = "Web Server"
  }
}

resource "aws_key_pair" "ssh-bastion-key" {
  key_name   = "ssh-bastion-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDLlo1i8W2G2TsJi59qRyqRFr1u8fYmmnKL4fWg9PsrhEgItMdsV81hwEPApoM6nRD7FBmTqQY1ueR6Ogl04HpS2slHVP4Sqnmj75BwFdokkm7CeyypdED7V8jpMncXipS7GTsL6uEOGi8IAW/JCtKXfkGb+v5EOC2k9Ii68JWaPV807hB2djBX9dh8HPmo4KBab4Qsc6/3GOfoRjMC6ecvRwX631eSWnEDh0e9IeLe+Z7whwoFvDslSwq66IaXUPhmkl6eVH3E3DGAKV/mWa41IFYCTy0hZpxuUDSmjh3F0GS9Hs5MEmBt8H71a4DmpJVVmwCbSRcrkijjadLeSN+Y6QsQLpxcRWphK8xUFPj/XSGOGKEJEx3R4oyKH+8/f7tT2EnFIVF6he9MQhpka5//qWL4BeyZCxtrsqEEsXz792qj3pzLeK1uynRko4T7aFYVau/nbEqqVQkTBQXBCQjygJ/hxlG6TXKs7cUl7gkOs5eJW9nOzBEP3DtrPyBoTV+QrwCBHhZATbHujpJWOM0L1iYnSRgvvkppF9jnJhDcRIXYIvJdKU5bT1Fe45ZgJpvsgFOjXdpEKfj/y900RDits/i7f5X5+bfb2IUGjHAuxYnlcqBjydzks+U6i1sXsDFx9Ql9SJlCQuOQ+dz8fxDWldU6FutMm0NQeNqD1VRKww== garrett@linuxg"
}
