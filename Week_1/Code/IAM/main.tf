terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region  = var.region
  profile = var.profile_name
}


# Get latest Amazon Linux 2 AMI
data "aws_ami" "amazon-linux-2" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }
}

# Create the Linux EC2 Web server
resource "aws_instance" "prod-instance" {
  ami                         = data.aws_ami.amazon-linux-2.id
  instance_type               = var.instance_type
  key_name                    = var.instance_key
  subnet_id                   = aws_subnet.public_subnets[0].id
  security_groups             = [aws_security_group.sg.id]
  associate_public_ip_address = true

  # attach instance profile to EC2
  iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.name

  user_data = <<-EOF
  #!/bin/bash
  yum update -y
  yum install -y httpd.x86_64
  systemctl start httpd.service
  systemctl enable httpd.service
  instanceId=$(curl http://169.254.169.254/latest/meta-data/instance-id)
   echo “AWS Linux VM Deployed with Terraform with instance id $instanceId” > /var/www/html/index.html
  EOF

  tags = {
    Name = "prod-instance"
    Env  = "prod"
  }

  volume_tags = {
    Name = "prod-instance"
  }
}

resource "aws_instance" "dev-instance" {
  ami                         = data.aws_ami.amazon-linux-2.id
  instance_type               = var.instance_type
  key_name                    = var.instance_key
  subnet_id                   = aws_subnet.public_subnets[1].id
  security_groups             = [aws_security_group.sg.id]
  associate_public_ip_address = true

  user_data = <<-EOF
  #!/bin/bash
  yum update -y
  yum install -y httpd.x86_64
  systemctl start httpd.service
  systemctl enable httpd.service
  instanceId=$(curl http://169.254.169.254/latest/meta-data/instance-id)
   echo “AWS Linux VM Deployed with Terraform with instance id $instanceId” > /var/www/html/index.html
  EOF

  tags = {
    Name = "dev-instance"
    Env  = "dev"
  }

  volume_tags = {
    Name = "dev-instance"
  }
}
