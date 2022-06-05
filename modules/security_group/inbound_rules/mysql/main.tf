resource "aws_security_group_rule" "mysql" {
  description = "allow tcp 3306 traffic"
  type = "ingress"
  to_port = 3306
  from_port = 3306
  protocol = "tcp"
  cidr_blocks = var.ingress_with_cidr_blocks ? var.cidr_blocks : null
  source_security_group_id = var.ingress_with_security_groups ? var.source_security_group_id : null
  security_group_id = var.security_group_id
}