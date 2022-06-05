data "aws_ssm_parameter" "amz_ami" {
  name = "/aws/service/ami-amazon-linux-latest/amzn2-ami-kernel-5.10-hvm-x86_64-gp2"
}

resource "aws_instance" "web-server" {
  count = 2

  ami                    = data.aws_ssm_parameter.amz_ami.value
  key_name               = "myvpckey"
  instance_type          = "t3.micro"
  subnet_id              = element(module.web_vpc.private_subnet_id[*], count.index + 2)
  vpc_security_group_ids = [module.web-sg[1].security_group_id]

  tags = {
    Name = "web-server-${count.index}"
  }
}

resource "aws_instance" "db-server" {
  count = 2

  ami                    = data.aws_ssm_parameter.amz_ami.value
  key_name               = "myvpckey"
  instance_type          = "t3.micro"
  subnet_id              = element(module.web_vpc.private_subnet_id[*], count.index)
  vpc_security_group_ids = [module.web-sg[2].security_group_id]

  tags = {
    Name = "db-servver-${count.index}"
  }
}

resource "aws_instance" "bastion-server" {
  count = 2

  ami                    = data.aws_ssm_parameter.amz_ami.value
  key_name               = "myvpckey"
  instance_type          = "t3.micro"
  subnet_id              = element(module.bastion_vpc.private_subnet_id[*], count.index)
  vpc_security_group_ids = [module.bastion-sg.security_group_id]

  tags = {
    Name = "bastion-server-${count.index}"
  }
}

resource "aws_instance" "poc-server" {
  count = 2

  ami                    = data.aws_ssm_parameter.amz_ami.value
  key_name               = "myvpckey"
  instance_type          = "t3.micro"
  subnet_id              = element(module.poc_vpc.public_subnet_id[*], count.index)
  vpc_security_group_ids = [module.poc-sg.security_group_id]

  tags = {
    Name = "poc-server-${count.index}"
  }

}