resource "aws_instance" "bastion" {
  ami           = "ami-0d1cd67c26f5fca19"
  instance_type = "t2.micro"
  vpc_security_group_ids = ["${aws_security_group.allow_ssh.id}"]
  subnet_id = "${aws_subnet.public-subnet.id}"

  tags = {
    Name = "Bastion Host"
  }
}