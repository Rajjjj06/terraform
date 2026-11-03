
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-south-2"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "flask-express-ecs"
}

variable "frontend_port" {
  description = "Express application port"
  type        = number
  default     = 3000
}

variable "backend_port" {
  description = "Flask application port"
  type        = number
  default     = 5000
}

variable "container_cpu" {
  description = "CPU units for each Fargate task"
  type        = number
  default     = 256
}

variable "container_memory" {
  description = "Memory in MB for each Fargate task"
  type        = number
  default     = 512
}


variable "frontend_image" {
  description = "Existing frontend Docker image in ECR"
  type        = string
}

variable "backend_image" {
  description = "Existing backend Docker image in ECR"
  type        = string
}
