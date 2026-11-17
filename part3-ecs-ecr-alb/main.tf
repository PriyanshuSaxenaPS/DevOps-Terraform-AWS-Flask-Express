terraform {
  required_version = ">= 1.5.0"
  required_providers { aws = { source = "hashicorp/aws", version = "~> 5.0" } }
}
provider "aws" { region = var.aws_region }
data "aws_availability_zones" "available" { state = "available" }
locals {
  name = var.project
  flask_image = "${aws_ecr_repository.flask.repository_url}:${var.image_tag}"
  express_image = "${aws_ecr_repository.express.repository_url}:${var.image_tag}"
}
resource "aws_ecr_repository" "flask" { name = "${local.name}-flask"
  image_tag_mutability = "MUTABLE"
  force_delete = true }
resource "aws_ecr_repository" "express" { name = "${local.name}-express"
  image_tag_mutability = "MUTABLE"
  force_delete = true }

resource "aws_vpc" "main" { cidr_block = "10.30.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = { Name = "${local.name}-vpc" } }
resource "aws_internet_gateway" "igw" { vpc_id = aws_vpc.main.id
  tags = { Name = "${local.name}-igw" } }
resource "aws_subnet" "public" {
  count = 2
  vpc_id = aws_vpc.main.id
  cidr_block = count.index == 0 ? "10.30.1.0/24" : "10.30.2.0/24"
  availability_zone = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true
  tags = { Name = "${local.name}-public-${count.index + 1}" }
}
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route { cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.igw.id }
}
resource "aws_route_table_association" "public" {
  count = 2
  subnet_id = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}
resource "aws_security_group" "alb" {
  name = "${local.name}-alb-sg"
  vpc_id = aws_vpc.main.id
  ingress { from_port = 80
  to_port = 80
  protocol = "tcp"
  cidr_blocks = ["0.0.0.0/0"] }
  egress { from_port = 0
  to_port = 0
  protocol = "-1"
  cidr_blocks = ["0.0.0.0/0"] }
}
resource "aws_security_group" "tasks" {
  name = "${local.name}-tasks-sg"
  vpc_id = aws_vpc.main.id
  ingress { description = "Flask from ALB"
  from_port = 5000
  to_port = 5000
  protocol = "tcp"
  security_groups = [aws_security_group.alb.id] }
  ingress { description = "Express from ALB"
  from_port = 3000
  to_port = 3000
  protocol = "tcp"
  security_groups = [aws_security_group.alb.id] }
  egress { from_port = 0
  to_port = 0
  protocol = "-1"
  cidr_blocks = ["0.0.0.0/0"] }
}
resource "aws_lb" "app" {
  name = substr("${local.name}-alb", 0, 32)
  load_balancer_type = "application"
  subnets = aws_subnet.public[*].id
  security_groups = [aws_security_group.alb.id]
}
resource "aws_lb_target_group" "flask" {
  name = substr("${local.name}-flask-tg", 0, 32)
  port = 5000
  protocol = "HTTP"
  vpc_id = aws_vpc.main.id
  target_type = "ip"
  health_check { path = "/health"
  matcher = "200"
  interval = 30
  healthy_threshold = 2
  unhealthy_threshold = 3 }
}
resource "aws_lb_target_group" "express" {
  name = substr("${local.name}-express-tg", 0, 32)
  port = 3000
  protocol = "HTTP"
  vpc_id = aws_vpc.main.id
  target_type = "ip"
  health_check { path = "/healthz"
  matcher = "200"
  interval = 30
  healthy_threshold = 2
  unhealthy_threshold = 3 }
}
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app.arn
  port = 80
  protocol = "HTTP"
  default_action { type = "forward"
  target_group_arn = aws_lb_target_group.express.arn }
}
resource "aws_lb_listener_rule" "flask_api" {
  listener_arn = aws_lb_listener.http.arn
  priority = 100
  action { type = "forward"
  target_group_arn = aws_lb_target_group.flask.arn }
  condition { path_pattern { values = ["/api/*", "/health"] } }
}

resource "aws_ecs_cluster" "main" { name = "${local.name}-cluster" }
resource "aws_iam_role" "ecs_execution" {
  name = "${local.name}-ecs-execution"
  assume_role_policy = jsonencode({ Version = "2012-10-17", Statement = [{ Action = "sts:AssumeRole", Effect = "Allow", Principal = { Service = "ecs-tasks.amazonaws.com" } }] })
}
resource "aws_iam_role_policy_attachment" "ecs_execution" {
  role = aws_iam_role.ecs_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}
resource "aws_cloudwatch_log_group" "flask" { name = "/ecs/${local.name}/flask"
  retention_in_days = 7 }
resource "aws_cloudwatch_log_group" "express" { name = "/ecs/${local.name}/express"
  retention_in_days = 7 }

resource "aws_ecs_task_definition" "flask" {
  family = "${local.name}-flask"
  requires_compatibilities = ["FARGATE"]
  network_mode = "awsvpc"
  cpu = "256"
  memory = "512"
  execution_role_arn = aws_iam_role.ecs_execution.arn
  container_definitions = jsonencode([{
    name = "flask", image = local.flask_image, essential = true,
    portMappings = [{ containerPort = 5000, hostPort = 5000, protocol = "tcp" }],
    logConfiguration = { logDriver = "awslogs", options = { awslogs-group = aws_cloudwatch_log_group.flask.name, awslogs-region = var.aws_region, awslogs-stream-prefix = "flask" } }
  }])
  depends_on = [aws_iam_role_policy_attachment.ecs_execution]
}
resource "aws_ecs_task_definition" "express" {
  family = "${local.name}-express"
  requires_compatibilities = ["FARGATE"]
  network_mode = "awsvpc"
  cpu = "256"
  memory = "512"
  execution_role_arn = aws_iam_role.ecs_execution.arn
  container_definitions = jsonencode([{
    name = "express", image = local.express_image, essential = true,
    portMappings = [{ containerPort = 3000, hostPort = 3000, protocol = "tcp" }],
    logConfiguration = { logDriver = "awslogs", options = { awslogs-group = aws_cloudwatch_log_group.express.name, awslogs-region = var.aws_region, awslogs-stream-prefix = "express" } }
  }])
  depends_on = [aws_iam_role_policy_attachment.ecs_execution]
}
resource "aws_ecs_service" "flask" {
  name = "${local.name}-flask"
  cluster = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.flask.arn
  desired_count = 1
  launch_type = "FARGATE"
  network_configuration { subnets = aws_subnet.public[*].id
  security_groups = [aws_security_group.tasks.id]
  assign_public_ip = true }
  load_balancer { target_group_arn = aws_lb_target_group.flask.arn
  container_name = "flask"
  container_port = 5000 }
  depends_on = [aws_lb_listener.http]
}
resource "aws_ecs_service" "express" {
  name = "${local.name}-express"
  cluster = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.express.arn
  desired_count = 1
  launch_type = "FARGATE"
  network_configuration { subnets = aws_subnet.public[*].id
  security_groups = [aws_security_group.tasks.id]
  assign_public_ip = true }
  load_balancer { target_group_arn = aws_lb_target_group.express.arn
  container_name = "express"
  container_port = 3000 }
  depends_on = [aws_lb_listener.http]
}
