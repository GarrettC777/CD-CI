
resource "aws_iam_role_policy" "ec2-role-policy" {
  name = "ec2-role-policy"
  role = aws_iam_role.ec2-role.id

  policy = "${file("ec2-policy.json")}"
}
resource "aws_iam_role" "ec2-role" {
  name = "ec2-role"

  assume_role_policy = "${file("ec2-assume-policy.json")}"

  tags = {
    tag-key = "ec2-role-yup"
  }
}

resource "aws_iam_instance_profile" "ec2-profile" {
  name = "ec2-profile"
  role = "${aws_iam_role.ec2-role.name}"
}

