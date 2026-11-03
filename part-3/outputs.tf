
output "alb_dns_name" {
  description = "Application Load Balancer DNS name"
  value       = aws_alb.main.dns_name
}

output "frontend_url" {
  description = "Public frontend URL"
  value       = "http://${aws_alb.main.dns_name}"
}

output "backend_url" {
  description = "Public backend URL through the Application Load Balancer"
  value       = "http://${aws_alb.main.dns_name}:${var.backend_port}"
}

output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = aws_ecs_cluster.main.name
}
