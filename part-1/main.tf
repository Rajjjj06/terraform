terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

resource "aws_security_group" "app_sg" {
  name        = "${var.project_name}-sg"
  description = "Security group for ${var.project_name} application"

  ingress {
    description = "Allow HTTP traffic for frontend"
    from_port   = var.frontend_port
    to_port     = var.frontend_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTP traffic for backend"
    from_port   = var.backend_port
    to_port     = var.backend_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "${var.project_name}-sg"
  }
}

resource "aws_instance" "app_server" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  security_groups             = [aws_security_group.app_sg.name]
  user_data                   = file("${path.module}/user_data.sh")
  user_data_replace_on_change = true
  tags = {
    Name = "${var.project_name}-instance"
  }
}