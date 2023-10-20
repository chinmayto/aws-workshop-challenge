# Launch Template Outputs
output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.app_vpc.id
}


output "web_instance_id_prod" {
  value = aws_instance.prod-instance.id
}

output "web_instance_id_dev" {
  value = aws_instance.dev-instance.id
}
