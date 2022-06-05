resource "aws_security_group" "sg" {
  name = "${var.project_name}-sg"
  vpc_id = var.vpc_id

  tags = {
    Name = "${var.project_name}-sg"
  }
}