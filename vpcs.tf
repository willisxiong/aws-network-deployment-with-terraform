# Create VPC
module "web_vpc" {
  source             = "./modules/vpc"
  vpc_cidr           = "10.0.0.0/16"
  availability_zones = ["ap-east-1a", "ap-east-1c"]
  public_subnets     = ["10.0.0.0/24", "10.0.128.0/24"]
  private_subnets    = ["10.0.2.0/24", "10.0.130.0/24", "10.0.1.0/24", "10.0.129.0/24"]
  project_name       = "WEB"
  create_igw         = true
  create_nat         = true
}

module "poc_vpc" {
  source             = "./modules/vpc"
  vpc_cidr           = "10.250.0.0/16"
  availability_zones = ["ap-east-1a", "ap-east-1c"]
  public_subnets     = ["10.250.0.0/24", "10.250.128.0/24"]
  private_subnets    = ["10.250.1.0/24", "10.250.129.0/24"]
  project_name       = "POC"
  create_igw         = true
}

module "bastion_vpc" {
  source             = "./modules/vpc"
  vpc_cidr           = "10.1.0.0/16"
  availability_zones = ["ap-east-1a", "ap-east-1c"]
  private_subnets    = ["10.1.0.0/24", "10.1.128.0/24"]
  project_name       = "BASTION"
}

resource "aws_vpc_peering_connection" "web-bastion" {
  vpc_id      = module.web_vpc.vpc_id
  peer_vpc_id = module.bastion_vpc.vpc_id
  auto_accept = true

  tags = {
    Name = "peering between web and bastion"
  }
}

resource "aws_vpc_peering_connection" "bastion-poc" {
  vpc_id      = module.bastion_vpc.vpc_id
  peer_vpc_id = module.poc_vpc.vpc_id
  auto_accept = true

  tags = {
    Name = "peering between bastion and poc"
  }
}

resource "aws_route" "web-public-r" {
  route_table_id            = module.web_vpc.public_rt_id[0]
  destination_cidr_block    = "10.1.0.0/16"
  vpc_peering_connection_id = aws_vpc_peering_connection.web-bastion.id
}

resource "aws_route_table" "web-private1-rt" {
  vpc_id = module.web_vpc.vpc_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = module.web_vpc.nat_id[0]
  }

  route {
    cidr_block                = "10.1.0.0/16"
    vpc_peering_connection_id = aws_vpc_peering_connection.web-bastion.id
  }

  tags = {
    Name = "web-private1-rt"
  }
}

resource "aws_route_table_association" "a" {
  subnet_id = module.web_vpc.private_subnet_id[2]

  route_table_id = aws_route_table.web-private1-rt.id
}

resource "aws_route_table" "web-private2-rt" {
  vpc_id = module.web_vpc.vpc_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = module.web_vpc.nat_id[1]
  }

  route {
    cidr_block                = "10.1.0.0/16"
    vpc_peering_connection_id = aws_vpc_peering_connection.web-bastion.id
  }

  tags = {
    Name = "web-private2-rt"
  }
}

resource "aws_route_table_association" "b" {
  subnet_id = module.web_vpc.private_subnet_id[3]

  route_table_id = aws_route_table.web-private2-rt.id
}

resource "aws_default_route_table" "bastion-default-rt" {
  default_route_table_id = module.bastion_vpc.default_rt_id

  route {
    cidr_block                = "10.0.0.0/16"
    vpc_peering_connection_id = aws_vpc_peering_connection.web-bastion.id
  }

  route {
    cidr_block                = "10.250.0.0/16"
    vpc_peering_connection_id = aws_vpc_peering_connection.bastion-poc.id
  }

}

resource "aws_route_table_association" "c" {
  subnet_id = module.bastion_vpc.private_subnet_id[0]

  route_table_id = aws_default_route_table.bastion-default-rt.id
}

resource "aws_route_table_association" "d" {
  subnet_id = module.bastion_vpc.private_subnet_id[1]

  route_table_id = aws_default_route_table.bastion-default-rt.id
}

resource "aws_route" "poc-public-r" {
  route_table_id            = module.poc_vpc.public_rt_id[0]
  destination_cidr_block    = "10.1.0.0/16"
  vpc_peering_connection_id = aws_vpc_peering_connection.bastion-poc.id

}

resource "aws_route_table" "poc-private-rt" {
  vpc_id = module.poc_vpc.vpc_id

  route {
    cidr_block                = "10.1.0.0/16"
    vpc_peering_connection_id = aws_vpc_peering_connection.bastion-poc.id
  }

  tags = {
    Name = "poc-private1-rt"
  }
}


resource "aws_route_table_association" "e" {
  subnet_id = module.poc_vpc.private_subnet_id[0]

  route_table_id = aws_route_table.poc-private-rt.id
}

resource "aws_route_table_association" "f" {
  subnet_id = module.poc_vpc.private_subnet_id[1]

  route_table_id = aws_route_table.poc-private-rt.id
}

# Create Security Group
module "web-sg" {
  source = "./modules/security_group"

  count = length(var.web_sg_names)

  project_name = element(var.web_sg_names[*], count.index)
  vpc_id       = module.web_vpc.vpc_id
}

module "bastion-sg" {
  source = "./modules/security_group"

  project_name = "bastion"
  vpc_id       = module.bastion_vpc.vpc_id
}

module "poc-sg" {
  source = "./modules/security_group"

  project_name = "poc"
  vpc_id       = module.poc_vpc.vpc_id
}

module "web_lb_inbound_rule" {
  source = "./modules/security_group/inbound_rules/http"

  ingress_with_security_groups = false
  ingress_with_cidr_blocks     = true
  security_group_id            = module.web-sg[0].security_group_id
}

module "web_server_inbound_rule" {
  source = "./modules/security_group/inbound_rules/http"

  ingress_with_cidr_blocks     = false
  ingress_with_security_groups = true
  source_security_group_id     = module.web-sg[0].security_group_id
  security_group_id            = module.web-sg[1].security_group_id
}

module "mysql_inbound_rule" {
  source = "./modules/security_group/inbound_rules/mysql"

  ingress_with_security_groups = true
  ingress_with_cidr_blocks     = false
  source_security_group_id     = module.web-sg[1].security_group_id
  security_group_id            = module.web-sg[2].security_group_id
}

module "poc_ssh_inbound_rule" {
  source = "./modules/security_group/inbound_rules/ssh"

  ingress_with_cidr_blocks     = true
  ingress_with_security_groups = false
  security_group_id            = module.poc-sg.security_group_id
}

module "bastion_ssh_inbound_rule" {
  source = "./modules/security_group/inbound_rules/ssh"

  ingress_with_security_groups = true
  ingress_with_cidr_blocks     = false
  source_security_group_id     = module.poc-sg.security_group_id
  security_group_id            = module.bastion-sg.security_group_id
}

module "web_outbound_rule" {
  source = "./modules/security_group/outbound_rules"

  count = length(var.web_sg_names)

  security_group_id = element(module.web-sg[*].security_group_id, count.index)
}

module "bastion_outbound_rule" {
  source = "./modules/security_group/outbound_rules"
  security_group_id = module.bastion-sg.security_group_id
}

module "poc_outbound_rule" {
  source = "./modules/security_group/outbound_rules"
  security_group_id = module.poc-sg.security_group_id
}