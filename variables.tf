variable "web_sg_names" {
  type    = list(string)
  default = ["web-lb", "web-server", "web-db"]
}

variable "aws-region" {
  type = string
  default = "ap-east-1"
}