variable "aws_region" { type = string
  default = "ap-south-1" }
variable "project" { type = string
  default = "terraform-demo-p1" }
variable "instance_type" { type = string
  default = "t3.micro" }
variable "ssh_cidr" {
  description = "Your public IPv4 address in CIDR notation, e.g. 203.0.113.10/32. Use a restrictive value."
  type = string
}
