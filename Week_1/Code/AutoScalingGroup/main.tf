# Get the AMI created ealier
data "aws_ami" "amazon-linux-ami" {
  most_recent = true
  owners      = ["self"]
  filter {
    name   = "name"
    values = ["CT_Auto_Scaling_Webhost"]
  }
}

# Launch Template Resource
resource "aws_launch_template" "aws-launch-template" {
  name                   = "${var.project_name}-scaling-template"
  image_id               = data.aws_ami.amazon-linux-ami.id
  instance_type          = var.instance_type
  key_name               = var.instance_key
  vpc_security_group_ids = [aws_security_group.sg.id]
  update_default_version = true
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "aws-webserver-demo"
    }
  }
  monitoring {
    enabled = true
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "myasg"
    }
  }
}

resource "aws_autoscaling_group" "aws-autoscaling-group" {
  name                = "${var.project_name}-ASG-Group"
  vpc_zone_identifier = [for s in aws_subnet.public_subnets : s.id]
  desired_capacity    = 2
  max_size            = 3
  min_size            = 2

  launch_template {
    id      = aws_launch_template.aws-launch-template.id
    version = aws_launch_template.aws-launch-template.latest_version
  }
}


resource "aws_autoscaling_attachment" "asg_attachment_alb" {
  autoscaling_group_name = aws_autoscaling_group.aws-autoscaling-group.id
  lb_target_group_arn    = aws_lb_target_group.alb_target_group.arn
}
