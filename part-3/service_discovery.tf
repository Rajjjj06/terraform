resource "aws_service_discovery_private_dns_namespace" "main" {
  name        = "${var.project_name}-namespace"
  description = "Private DNS namespace for service discovery"
  vpc         = aws_vpc.main.id
  tags = {
    Name = "${var.project_name}-namespace"
  }
}

resource "aws_service_discovery_service" "backend" {
  name = "backend"
  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.main.id
    dns_records {
      type = "A"
      ttl  = 60
    }
    routing_policy = "MULTIVALUE"
  }
  tags = {
    Name = "${var.project_name}-backend-service"
  }
}