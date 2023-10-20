# Launch Template Outputs
output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.app_vpc.id
}
