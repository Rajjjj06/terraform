resource "aws_security_group" "alb-sg" {
  name        = "${var.project_name}-alb-sg"
  description = "Security group for ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Allow HTTP traffic from the internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Allow backend traffic from the internet"
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
    Name = "${var.project_name}-alb-sg"
  }
}

resource "aws_security_group" "frontend-sg-1" {
  name        = "${var.project_name}-frontend-sg-1"
  description = "Security group for frontend application in subnet 1"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Allow HTTP traffic from the ALB"
    from_port       = var.frontend_port
    to_port         = var.frontend_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb-sg.id]
  }
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "${var.project_name}-frontend-sg-1"
  }
}

resource "aws_security_group" "backend-sg-2" {
  name        = "${var.project_name}-backend-sg-2"
  description = "Security group for backend application in subnet 2"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Allow backend traffic from the frontend"
    from_port       = var.backend_port
    to_port         = var.backend_port
    protocol        = "tcp"
    security_groups = [aws_security_group.frontend-sg-1.id]
  }
  ingress {
    description     = "Allow backend traffic from the ALB"
    from_port       = var.backend_port
    to_port         = var.backend_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb-sg.id]
  }
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "${var.project_name}-backend-sg-2"
  }
}