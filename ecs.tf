provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "sampleapp_vpc" {
  cidr_block = "173.0.0.0/16"
}

resource "aws_subnet" "sampleapp_subnet_us_east_1a" {
  vpc_id            = aws_vpc.sampleapp_vpc.id
  cidr_block        = "173.0.1.0/24"
  availability_zone = "us-east-1a"
}

resource "aws_subnet" "sampleapp_subnet_us_east_1b" {
  vpc_id            = aws_vpc.sampleapp_vpc.id
  cidr_block        = "173.0.2.0/24"
  availability_zone = "us-east-1b"
}

resource "aws_security_group" "sampleapp_security_group" {
  vpc_id = aws_vpc.sampleapp_vpc.id

  # Define your security group rules here
}

resource "aws_internet_gateway" "sampleapp_igw" {
  vpc_id = aws_vpc.sampleapp_vpc.id
}

resource "aws_route_table" "sampleapp_route_table" {
  vpc_id = aws_vpc.sampleapp_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.sampleapp_igw.id
  }
}

resource "aws_route_table_association" "sampleapp_route_table_association_us_east_1a" {
  subnet_id      = aws_subnet.sampleapp_subnet_us_east_1a.id
  route_table_id = aws_route_table.sampleapp_route_table.id
}

resource "aws_route_table_association" "sampleapp_route_table_association_us_east_1b" {
  subnet_id      = aws_subnet.sampleapp_subnet_us_east_1b.id
  route_table_id = aws_route_table.sampleapp_route_table.id
}

resource "aws_lb" "sampleapploadbalancer" {
  name               = "sampleapploadbalancer"
  internal           = false
  load_balancer_type = "application"
  subnets            = [aws_subnet.sampleapp_subnet_us_east_1a.id, aws_subnet.sampleapp_subnet_us_east_1b.id]
  security_groups    = [aws_security_group.sampleapp_security_group.id]
}

resource "aws_lb_listener" "sampleapp_listener" {
  load_balancer_arn = aws_lb.sampleapploadbalancer.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.sampleapptargetgrp1.arn
  }
}

resource "aws_lb_target_group" "sampleapptargetgrp1" {
  name       = "sampleapptargetgrp1"
  port       = 5000
  protocol   = "HTTP"
  vpc_id     = aws_vpc.sampleapp_vpc.id
  target_type = "ip"
}

resource "aws_ecs_cluster" "sampleappcluster" {
  name = "sampleappcluster"
}

resource "aws_ecs_task_definition" "sampleapptaskdefinition" {
  family                   = "sampleapptaskdefinition"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256  # Define CPU allocation
  memory                   = 512  # Define memory allocation
  execution_role_arn       = "arn:aws:iam::339712890830:role/ecsTaskExecutionRole" 

  container_definitions    = <<DEFINITION
[
  {
    "name": "samplepythonapp",
    "image": "339712890830.dkr.ecr.us-east-1.amazonaws.com/sample-app-img",
    "cpu": 256,
    "memory": 512,
    "portMappings": [
      {
        "containerPort": 5000,
        "hostPort": 5000
      }
    ]
  }
]
DEFINITION
}

resource "aws_ecs_service" "sampleappservice" {
  name            = "sampleappservice"
  cluster         = aws_ecs_cluster.sampleappcluster.id
  task_definition = aws_ecs_task_definition.sampleapptaskdefinition.arn
  desired_count   = 1

  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200

  network_configuration {
    subnets          = [aws_subnet.sampleapp_subnet_us_east_1a.id, aws_subnet.sampleapp_subnet_us_east_1b.id]
    security_groups  = [aws_security_group.sampleapp_security_group.id]
    
  }
}
