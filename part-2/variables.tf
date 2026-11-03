variable "region" {
  description = "The AWS region to deploy resources"
  type        = string
  default     = "ap-south-2"
}

variable "project_name_frontend" {
  description = "The name of the project"
  type        = string
  default     = "frontend-app"
}
variable "project_name_backend" {
  description = "The name of the project"
  type        = string
  default     = "backend-app"
}

variable "frontend_port" {
  description = "The port for the frontend application"
  type        = number
  default     = 3000
}
variable "backend_port" {
  description = "The port for the backend application"
  type        = number
  default     = 5000
}
variable "ami_id" {
  description = "The AMI ID for the EC2 instance"
  type        = string
  default     = "ami-0c24c764e44ed98f2"
}

variable "instance_type" {
  description = "The instance type for the EC2 instance"
  type        = string
  default     = "t3.nano"
}