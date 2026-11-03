variable "aws_region" {
    description = "The AWS region to deploy resources in"
    type        = string
    default     = "ap-south-2"
  
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.nano"
}

variable "ami_id" {
  description = "Ubuntu AMI ID"
  type        = string
  default     = "ami-0c24c764e44ed98f2"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "flask-express"
}

variable "frontend_port" {
  description = "Express frontend port"
  type        = number
  default     = 3000
}

variable "backend_port" {
  description = "Flask backend port"
  type        = number
  default     = 5000
}