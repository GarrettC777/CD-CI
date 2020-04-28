resource "aws_instance" "bastion" {
  ami           = "ami-0d1cd67c26f5fca19"
  instance_type = "t2.micro"
  vpc_security_group_ids = ["${aws_security_group.allow_ssh.id}"]
  subnet_id = "${aws_subnet.public-subnet-1.id}"
  key_name = "beef"
  associate_public_ip_address = true
  
  tags = {
    Name = "Bastion Host"
  }
}

resource "aws_instance" "webserver" {
  ami           = "ami-0d1cd67c26f5fca19"
  instance_type = "t2.micro"
  vpc_security_group_ids = ["${aws_security_group.allow_ssh.id}"]
  subnet_id = "${aws_subnet.private-subnet-1.id}"
  key_name = "beef"
  
  tags = {
    Name = "Web Server"
  }
}