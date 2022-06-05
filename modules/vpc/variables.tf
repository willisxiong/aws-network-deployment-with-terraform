variable "region" {
  type = string
  default = "ap-east-1"
}

variable "availability_zones" {
  type = list(string)
  default = ["ap-east-1a", "ap-east-1b", "ap-east-1c"]
}

variable "vpc_cidr" {
  type = string
  nullable = false

}

variable "public_subnets" {
  type = list(string)
  default = []
}

variable "private_subnets" {
  type = list(string)
  nullable = false
  default = []
}

variable "project_name" {
  type = string
  default = ""
}

variable "create_igw" {
  description = "control if create an internet gateway"
  type = bool
  default = false
}

variable "create_nat" {
  description = "control if create an nat gateway"
  type = bool
  default = false
}
