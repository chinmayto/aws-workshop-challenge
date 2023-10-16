# Create the security group for EC2
resource "aws_security_group" "sg" {
  name        = "${var.project_name} - Auto Scaling SG"
  description = "Allow ssh http inbound traffic"
  vpc_id      = aws_vpc.app_vpc.id

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "${var.project_name} - Auto Scaling SG"
  }
}

# Define the security group for the Load Balancer
resource "aws_security_group" "aws-sg-load-balancer" {
  name        = "aws-sg-load-balancer"
  description = "Allow incoming connections for load balancer"
  vpc_id      = aws_vpc.app_vpc.id
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["58.84.61.225/32"]
    description = "Allow incoming HTTP connections"
  }
  egress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.sg.id]
  }
  tags = {
    Name = "${var.project_name}-load-balancer-sg"
  }
}


# Add an inbound rule to auto scaling security group to allow traffic from ALB security group
resource "aws_security_group_rule" "ASG-sg-to-alb-sg-ingress" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  security_group_id        = aws_security_group.sg.id
  source_security_group_id = aws_security_group.aws-sg-load-balancer.id
}