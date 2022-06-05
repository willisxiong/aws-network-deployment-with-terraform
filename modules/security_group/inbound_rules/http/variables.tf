variable "cidr_blocks" {
  type = list(string)
  default = ["0.0.0.0/0"]
  nullable = true
}

variable "source_security_group_id" {
  type = string
  default = ""
}

variable "security_group_id" {
  type = string
}

variable "ingress_with_security_groups" {
  type = bool
  default = false
}

variable "ingress_with_cidr_blocks" {
  type = bool
  default = true
}