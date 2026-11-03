terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.region
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "${var.project_name_frontend}-vpc"
  }
}

resource "aws_subnet" "frontend_subnet" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.project_name_frontend}-subnet"
  }
}

resource "aws_subnet" "backend_subnet" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.project_name_backend}-subnet"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "${var.project_name_frontend}-igw"
  }
}

resource "aws_route_table" "main" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  tags = {
    Name = "public-route-table"
  }
}
resource "aws_route_table_association" "frontend_association" {
  subnet_id      = aws_subnet.frontend_subnet.id
  route_table_id = aws_route_table.main.id
}
resource "aws_route_table_association" "backend_association" {
  subnet_id      = aws_subnet.backend_subnet.id
  route_table_id = aws_route_table.main.id
}
resource "aws_security_group" "frontend_sg" {
  name        = "${var.project_name_frontend}-sg"
  description = "Security group for frontend application"
  vpc_id      = aws_vpc.main.id
  ingress {
    description = "Allow HTTP traffic for frontend"
    from_port   = var.frontend_port
    to_port     = var.frontend_port
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
}

resource "aws_security_group" "backend_sg" {
  name        = "${var.project_name_backend}-sg"
  description = "Security group for backend application"
  vpc_id      = aws_vpc.main.id
  ingress {
    description = "Allow backend traffic"
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

}

resource "aws_instance" "frontend_instance" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  vpc_security_group_ids      = [aws_security_group.frontend_sg.id]
  subnet_id                   = aws_subnet.frontend_subnet.id
  associate_public_ip_address = true
  user_data = templatefile("${path.module}/frontend.sh", {
    backend_public_ip = aws_instance.backend_instance.public_ip
    backend_port      = var.backend_port
  })
  user_data_replace_on_change = true
  tags = {
    Name = "${var.project_name_frontend}-instance"
  }
}

resource "aws_instance" "backend_instance" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  vpc_security_group_ids      = [aws_security_group.backend_sg.id]
  subnet_id                   = aws_subnet.backend_subnet.id
  associate_public_ip_address = true
  user_data                   = file("${path.module}/backend.sh")
  user_data_replace_on_change = true
  tags = {
    Name = "${var.project_name_backend}-instance"
  }
}