terraform {
  required_version = ">= 1.5.0"
  required_providers { aws = { source = "hashicorp/aws", version = "~> 5.0" } }
}
provider "aws" { region = var.aws_region }
data "aws_availability_zones" "available" { state = "available" }
data "aws_ami" "ubuntu" {
  most_recent = true
  owners = ["099720109477"]
  filter { name = "name"
  values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"] }
  filter { name = "virtualization-type"
  values = ["hvm"] }
}
resource "aws_vpc" "main" { cidr_block = "10.20.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = { Name = "${var.project}-vpc" } }
resource "aws_internet_gateway" "igw" { vpc_id = aws_vpc.main.id }
resource "aws_subnet" "public" {
  vpc_id = aws_vpc.main.id
  cidr_block = "10.20.1.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true
}
resource "aws_route_table" "public" { vpc_id = aws_vpc.main.id
  route { cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.igw.id } }
resource "aws_route_table_association" "public" { subnet_id = aws_subnet.public.id
  route_table_id = aws_route_table.public.id }

resource "aws_security_group" "frontend" {
  name = "${var.project}-frontend-sg"
  vpc_id = aws_vpc.main.id
  ingress { from_port = 3000
  to_port = 3000
  protocol = "tcp"
  cidr_blocks = ["0.0.0.0/0"] }
  ingress { from_port = 22
  to_port = 22
  protocol = "tcp"
  cidr_blocks = [var.ssh_cidr] }
  egress { from_port = 0
  to_port = 0
  protocol = "-1"
  cidr_blocks = ["0.0.0.0/0"] }
}
resource "aws_security_group" "backend" {
  name = "${var.project}-backend-sg"
  vpc_id = aws_vpc.main.id
  ingress { description = "Flask from frontend EC2"
  from_port = 5000
  to_port = 5000
  protocol = "tcp"
  security_groups = [aws_security_group.frontend.id] }
  ingress { description = "Flask public demo access"
  from_port = 5000
  to_port = 5000
  protocol = "tcp"
  cidr_blocks = ["0.0.0.0/0"] }
  ingress { from_port = 22
  to_port = 22
  protocol = "tcp"
  cidr_blocks = [var.ssh_cidr] }
  egress { from_port = 0
  to_port = 0
  protocol = "-1"
  cidr_blocks = ["0.0.0.0/0"] }
}
resource "aws_instance" "backend" {
  ami = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  subnet_id = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.backend.id]
  associate_public_ip_address = true
  user_data = file("${path.module}/backend_user_data.sh")
  user_data_replace_on_change = true
  tags = { Name = "${var.project}-flask" }
}
resource "aws_instance" "frontend" {
  ami = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  subnet_id = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.frontend.id]
  associate_public_ip_address = true
  user_data = templatefile("${path.module}/frontend_user_data.sh", { backend_private_ip = aws_instance.backend.private_ip })
  user_data_replace_on_change = true
  depends_on = [aws_instance.backend]
  tags = { Name = "${var.project}-express" }
}
