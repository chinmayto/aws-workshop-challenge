# Launch Template Outputs
output "launch_template_id" {
  description = "Launch Template ID"
  value       = aws_launch_template.aws-launch-template.id
}

output "launch_template_latest_version" {
  description = "Launch Template Latest Version"
  value       = aws_launch_template.aws-launch-template.latest_version
}

# Autoscaling Outputs
output "autoscaling_group_id" {
  description = "Autoscaling Group ID"
  value       = aws_autoscaling_group.aws-autoscaling-group.id
}

output "autoscaling_group_name" {
  description = "Autoscaling Group Name"
  value       = aws_autoscaling_group.aws-autoscaling-group.name
}

output "autoscaling_group_arn" {
  description = "Autoscaling Group ARN"
  value       = aws_autoscaling_group.aws-autoscaling-group.arn
}

# ALB Outputs
output "alb_target_group_arn" {
  description = "ALB Target Group ARN"
  value       = aws_lb_target_group.alb_target_group.arn
}
