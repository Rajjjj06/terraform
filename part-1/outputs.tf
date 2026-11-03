output "ip_address" {
  value = aws_instance.app_server.public_ip
}

output "frontend_url" {
  value = "http://${aws_instance.app_server.public_ip}:${var.frontend_port}"
}

output "backend_url" {
  value = "http://${aws_instance.app_server.public_ip}:${var.backend_port}"
}