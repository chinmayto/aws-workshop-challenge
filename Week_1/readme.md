# Week 1 - AWS General Immersion Days

https://catalog.workshops.aws/general-immersionday/en-US


## 1. Key Pair Creation

Terraform script to create AWS EC2 Key Pair. Rememer to add the key to .gitignore file, otherwise private key will be exposed to public git repo

```
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.5.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}

# Create a Key pair

resource "aws_key_pair" "WorkshopKeyPair" {
  key_name   = "WorkshopKeyPair"
  public_key = tls_private_key.rsa.public_key_openssh
}

# RSA key of size 4096 bits
resource "tls_private_key" "rsa" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Create a local file
resource "local_file" "WorkshopKeyPair" {
  content  = tls_private_key.rsa.private_key_pem
  filename = "WorkshopKeyPair"
}
```
Key pair in AWS Console:

![Alt text](Code/KeyPair/keypair.png)

## 2. Web Tier EC2 Linux

main.tf - create various resources (provider and web EC2 instance with userdata)

```
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
resource "aws_instance" "web" {
  ami             = data.aws_ami.amazon-linux-2.id
  instance_type   = var.instance_type
  key_name        = var.instance_key
  subnet_id       = aws_subnet.public_subnet.id
  security_groups = [aws_security_group.sg.id]

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
    Name = "web_instance"
  }

  volume_tags = {
    Name = "web_instance"
  }
}
```
network.tf - Create VPC (VPC, internet gateway, subnet, route table)

```
# Create the VPC
resource "aws_vpc" "app_vpc" {
  cidr_block = var.vpc_cidr

  tags = {
    Name = "app-vpc"
  }
}

# Create the internet gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.app_vpc.id

  tags = {
    Name = "vpc_igw"
  }
}

# Create the public subnet
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.app_vpc.id
  cidr_block              = var.public_subnet_cidr
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"

  tags = {
    Name = "public-subnet"
  }
}

# Create the route table
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.app_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public_rt"
  }
}

# Assign the public route table to the public subnet
resource "aws_route_table_association" "public_rt_asso" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}
```

sg.tf - create security group with ingress, egress rules

```
# Create the security group
resource "aws_security_group" "sg" {
  name        = "allow_ssh_http"
  description = "Allow ssh http inbound traffic"
  vpc_id      = aws_vpc.app_vpc.id

  ingress {
    description      = "SSH from VPC"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "HTTP from VPC"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_ssh_http"
  }
}
```

variables.tf
```
tervariable "region" {
  default = "us-east-1"
}
variable "instance_type" {
  default = "t2.micro"
}
variable "profile_name" {
  default = "default"
}
variable "instance_key" {
  default = "WorkshopKeyPair"
}
variable "vpc_cidr" {
  default = "178.0.0.0/16"
}
variable "public_subnet_cidr" {
  default = "178.0.10.0/24"
}
```

Terraform apply output:
```
Plan: 7 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + web_instance_id = (known after apply)
  + web_instance_ip = (known after apply)
aws_vpc.app_vpc: Creating...
aws_vpc.app_vpc: Still creating... [10s elapsed]
aws_vpc.app_vpc: Creation complete after 13s [id=vpc-0a73436b4fd4778af]
aws_internet_gateway.igw: Creating...
aws_subnet.public_subnet: Creating...
aws_security_group.sg: Creating...
aws_subnet.public_subnet: Creation complete after 5s [id=subnet-0c1590bd8528b6594]
aws_internet_gateway.igw: Creation complete after 6s [id=igw-063dbcfdd22dab1b8]
aws_route_table.public_rt: Creating...
aws_security_group.sg: Still creating... [10s elapsed]
aws_security_group.sg: Creation complete after 10s [id=sg-0ddcfe1f981f66733]
aws_instance.web: Creating...
aws_route_table.public_rt: Creation complete after 5s [id=rtb-03cad53d564069fe8]
aws_route_table_association.public_rt_asso: Creating...
aws_route_table_association.public_rt_asso: Creation complete after 2s [id=rtbassoc-05d129e8c110febe8]
aws_instance.web: Still creating... [10s elapsed]
aws_instance.web: Still creating... [20s elapsed]
aws_instance.web: Still creating... [30s elapsed]
aws_instance.web: Still creating... [40s elapsed]
aws_instance.web: Creation complete after 49s [id=i-04e12b8b6ade18b61]

Apply complete! Resources: 7 added, 0 changed, 0 destroyed.

Outputs:

web_instance_id = "i-04e12b8b6ade18b61"
web_instance_ip = "44.202.80.228"
```

Running website:

![Alt text](Code/WebTierEC2Linux/ec2linux.png)

Terraform Destroy output:

```
Plan: 0 to add, 0 to change, 7 to destroy.

Changes to Outputs:
  - web_instance_id = "i-04e12b8b6ade18b61" -> null
  - web_instance_ip = "44.202.80.228" -> null
aws_route_table_association.public_rt_asso: Destroying... [id=rtbassoc-05d129e8c110febe8]
aws_instance.web: Destroying... [id=i-04e12b8b6ade18b61]
aws_route_table_association.public_rt_asso: Destruction complete after 1s
aws_route_table.public_rt: Destroying... [id=rtb-03cad53d564069fe8]
aws_route_table.public_rt: Destruction complete after 3s
aws_internet_gateway.igw: Destroying... [id=igw-063dbcfdd22dab1b8]
aws_instance.web: Still destroying... [id=i-04e12b8b6ade18b61, 10s elapsed]
aws_internet_gateway.igw: Still destroying... [id=igw-063dbcfdd22dab1b8, 10s elapsed]
aws_instance.web: Still destroying... [id=i-04e12b8b6ade18b61, 20s elapsed]
aws_internet_gateway.igw: Still destroying... [id=igw-063dbcfdd22dab1b8, 20s elapsed]
aws_instance.web: Still destroying... [id=i-04e12b8b6ade18b61, 30s elapsed]
aws_internet_gateway.igw: Destruction complete after 25s
aws_instance.web: Destruction complete after 35s
aws_subnet.public_subnet: Destroying... [id=subnet-0c1590bd8528b6594]
aws_security_group.sg: Destroying... [id=sg-0ddcfe1f981f66733]
aws_security_group.sg: Destruction complete after 2s
aws_subnet.public_subnet: Destruction complete after 2s
aws_vpc.app_vpc: Destroying... [id=vpc-0a73436b4fd4778af]
aws_vpc.app_vpc: Destruction complete after 2s

Destroy complete! Resources: 7 destroyed.
```

## 2. Web Tier EC2 Windows Server 2019
main.tf - create various resources (Provider and web EC2 instance with userdata)
```
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

# Get latest Amazon Windows Server 2019 Ami
data "aws_ami" "windows-2019" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["Windows_Server-2019-English-Full-Base*"]
  }
}

# Create the Windows server 2019 Web Server
resource "aws_instance" "web" {
  ami             = data.aws_ami.windows-2019.id
  instance_type   = var.instance_type
  key_name        = var.instance_key
  subnet_id       = aws_subnet.public_subnet.id
  security_groups = [aws_security_group.sg.id]
  user_data       = file("userdata.tpl")


  tags = {
    Name = "web_instance"
  }

  volume_tags = {
    Name = "web_instance"
  }
}
```
network.tf - Create VPC (VPC, internet gateway, subnet, route table)
```
# Create the VPC
resource "aws_vpc" "app_vpc" {
  cidr_block = var.vpc_cidr

  tags = {
    Name = "app-vpc"
  }
}

# Create the internet gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.app_vpc.id

  tags = {
    Name = "vpc_igw"
  }
}

# Create the public subnet
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.app_vpc.id
  cidr_block              = var.public_subnet_cidr
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"

  tags = {
    Name = "public-subnet"
  }
}

# Create the route table
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.app_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public_rt"
  }
}

# Assign the public route table to the public subnet
resource "aws_route_table_association" "public_rt_asso" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}
```
sg.tf - create security group with ingress, egress rules

```
# Create the security group
resource "aws_security_group" "sg" {
  name        = "allow_ssh_http"
  description = "Allow ssh http inbound traffic"
  vpc_id      = aws_vpc.app_vpc.id

  ingress {
    description      = "SSH from VPC"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "HTTP from VPC"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_ssh_http"
  }
}
```
userdata.tpl (userdata script in powershell)
```
<powershell>
Install-WindowsFeature -name Web-Server -IncludeManagementTools
$instanceId = Get-EC2InstanceMetadata -Path '/instance-id'
$id = (Invoke-WebRequest -Uri  http://169.254.169.254/latest/meta-data/instance-id -UseBasicParsing).content
New-Item -Path C:\inetpub\wwwroot\index.html -ItemType File -Value "AWS Windows VM Deployed with Terraform with instance id $instanceId : $id" -Force
</powershell>
```
output.tf
```
output "web_instance_ip" {
  value = aws_instance.web.public_ip
}

output "web_instance_id" {
  value = aws_instance.web.id
}
```

Terraform apply output:
```
Plan: 7 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + web_instance_id = (known after apply)
  + web_instance_ip = (known after apply)
aws_vpc.app_vpc: Creating...
aws_vpc.app_vpc: Still creating... [10s elapsed]
aws_vpc.app_vpc: Creation complete after 17s [id=vpc-04c04866cb32d6e2e]
aws_internet_gateway.igw: Creating...
aws_subnet.public_subnet: Creating...
aws_security_group.sg: Creating...
aws_internet_gateway.igw: Creation complete after 7s [id=igw-0329071a185c6afff]
aws_route_table.public_rt: Creating...
aws_subnet.public_subnet: Still creating... [10s elapsed]
aws_security_group.sg: Still creating... [10s elapsed]
aws_route_table.public_rt: Still creating... [10s elapsed]
aws_route_table.public_rt: Creation complete after 12s [id=rtb-086e66465adb40304]
aws_subnet.public_subnet: Creation complete after 20s [id=subnet-0cc92776d900331a0]
aws_route_table_association.public_rt_asso: Creating...
aws_security_group.sg: Still creating... [20s elapsed]
aws_security_group.sg: Creation complete after 22s [id=sg-048337eda0772a221]
aws_instance.web: Creating...
aws_route_table_association.public_rt_asso: Creation complete after 4s [id=rtbassoc-0288a8645618b7abd]
aws_instance.web: Still creating... [10s elapsed]
aws_instance.web: Still creating... [20s elapsed]
aws_instance.web: Still creating... [30s elapsed]
aws_instance.web: Still creating... [40s elapsed]
aws_instance.web: Still creating... [50s elapsed]
aws_instance.web: Still creating... [1m0s elapsed]
aws_instance.web: Still creating... [1m10s elapsed]
aws_instance.web: Still creating... [1m20s elapsed]
aws_instance.web: Still creating... [1m30s elapsed]
aws_instance.web: Still creating... [1m40s elapsed]
aws_instance.web: Still creating... [1m50s elapsed]
aws_instance.web: Still creating... [2m0s elapsed]
aws_instance.web: Still creating... [2m10s elapsed]
aws_instance.web: Creation complete after 2m17s [id=i-046e5e98f23f63202]

Apply complete! Resources: 7 added, 0 changed, 0 destroyed.

Outputs:

web_instance_id = "i-046e5e98f23f63202"
web_instance_ip = "44.204.58.224"
```

Running Website:
It takes some time for windows website to run

![Alt text](Code/WebTierEC2Win/ec2win.png)

![Alt text](Code/WebTierEC2Win/rdesk.png)


Terraform Destroy output:

```
Plan: 0 to add, 0 to change, 7 to destroy.

Changes to Outputs:
  - web_instance_id = "i-046e5e98f23f63202" -> null
  - web_instance_ip = "44.204.58.224" -> null
aws_route_table_association.public_rt_asso: Destroying... [id=rtbassoc-0288a8645618b7abd]
aws_instance.web: Destroying... [id=i-046e5e98f23f63202]
aws_route_table_association.public_rt_asso: Destruction complete after 4s
aws_route_table.public_rt: Destroying... [id=rtb-086e66465adb40304]
aws_instance.web: Still destroying... [id=i-046e5e98f23f63202, 10s elapsed]
aws_route_table.public_rt: Destruction complete after 6s
aws_internet_gateway.igw: Destroying... [id=igw-0329071a185c6afff]
aws_instance.web: Still destroying... [id=i-046e5e98f23f63202, 20s elapsed]
aws_internet_gateway.igw: Still destroying... [id=igw-0329071a185c6afff, 10s elapsed]
aws_instance.web: Still destroying... [id=i-046e5e98f23f63202, 30s elapsed]
aws_internet_gateway.igw: Still destroying... [id=igw-0329071a185c6afff, 20s elapsed]
aws_instance.web: Still destroying... [id=i-046e5e98f23f63202, 40s elapsed]
aws_internet_gateway.igw: Still destroying... [id=igw-0329071a185c6afff, 30s elapsed]
aws_instance.web: Still destroying... [id=i-046e5e98f23f63202, 50s elapsed]
aws_internet_gateway.igw: Still destroying... [id=igw-0329071a185c6afff, 40s elapsed]
aws_instance.web: Destruction complete after 54s
aws_subnet.public_subnet: Destroying... [id=subnet-0cc92776d900331a0]
aws_security_group.sg: Destroying... [id=sg-048337eda0772a221]
aws_internet_gateway.igw: Destruction complete after 44s
aws_subnet.public_subnet: Destruction complete after 4s
aws_security_group.sg: Destruction complete after 5s
aws_vpc.app_vpc: Destroying... [id=vpc-04c04866cb32d6e2e]
aws_vpc.app_vpc: Destruction complete after 3s

Destroy complete! Resources: 7 destroyed.
```


## 3. Auto Scaling Group

1. Create Custom AMI for auto scaling group from the YAML file provided in workshop

https://catalog.workshops.aws/general-immersionday/en-US/basic-modules/10-ec2/ec2-auto-scaling/ec2-auto-scaling/1-ec2-as

Create stack from yaml provided:

![Alt text](Code/AutoScalingGroup/stackparam.png)

Submit the cloudformation template:

![Alt text](Code/AutoScalingGroup/submitstack.png)

Running website:

![Alt text](Code/AutoScalingGroup/webhost.png)

Create AMI from running instance:

![Alt text](Code/AutoScalingGroup/ami.png)

Create Security Group:

![Alt text](Code/AutoScalingGroup/sg.png)

Auto Scaling Group Diagram:

![Alt text](Code/AutoScalingGroup/asgdiag.png)

2. variables.tf - variables for azs, public subnet ciders

```
variable "region" {
  default = "us-east-1"
}
variable "instance_type" {
  default = "t2.micro"
}
variable "profile_name" {
  default = "default"
}
variable "instance_key" {
  default = "WorkshopKeyPair"
}
variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

# VPC Public Subnets
variable "public_subnet_cidrs" {
  description = "VPC Public Subnets"
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24", "10.0.104.0/24"]
}

/*
# VPC Private Subnets
variable "private_subnet_cidrs" {
  description = "VPC Private Subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24", "10.0.4.0/24"]
}
*/
variable "project_name" {
  default = "CT"
}

variable "azs" {
  type        = list(string)
  description = "Availability Zones"
  default     = ["us-east-1a", "us-east-1b", "us-east-1c", "us-east-1d"]
}
```
3. network.tf - Create VPC with 4 public subnet, attach internet gateway

```
# Create the VPC
resource "aws_vpc" "app_vpc" {
  cidr_block = var.vpc_cidr

  tags = {
    Name = "${var.project_name}-VPC"
  }
}

#create public subnets per zone
resource "aws_subnet" "public_subnets" {
  count             = length(var.public_subnet_cidrs)
  vpc_id            = aws_vpc.app_vpc.id
  cidr_block        = element(var.public_subnet_cidrs, count.index)
  availability_zone = element(var.azs, count.index)

  tags = {
    Name = "Public Subnet ${count.index + 1}"
  }
}

# Create the internet gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.app_vpc.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

# Create the route table
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.app_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public_rt"
  }
}

# Create route table assosiation with all public subnets
resource "aws_route_table_association" "public_subnet_asso" {
  count          = length(var.public_subnet_cidrs)
  subnet_id      = element(aws_subnet.public_subnets[*].id, count.index)
  route_table_id = aws_route_table.public_rt.id
}
```

4. Create application load balancer with target group and listener

```
# create application load balancer
resource "aws_lb" "aws-application_load_balancer" {
  name                       = "${var.project_name}-alb"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.aws-sg-load-balancer.id]
  subnets                    = [for s in aws_subnet.public_subnets : s.id]
  enable_deletion_protection = false

  tags = {
    Name = "${var.project_name}-alb"
  }
}

# create target group
resource "aws_lb_target_group" "alb_target_group" {
  name        = "${var.project_name}-tg"
  target_type = "instance"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.app_vpc.id

  health_check {
    enabled             = true
    interval            = 300
    path                = "/"
    timeout             = 60
    matcher             = 200
    healthy_threshold   = 5
    unhealthy_threshold = 5
  }

  lifecycle {
    create_before_destroy = true
  }
}

# create a listener on port 80 with redirect action
resource "aws_lb_listener" "alb_http_listener" {
  load_balancer_arn = aws_lb.aws-application_load_balancer.id
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_target_group.id

  }
}
```


5. Create ASG launch template with auto scaling group and policy


```
# Get the AMI created ealier
data "aws_ami" "amazon-linux-ami" {
  most_recent = true
  owners      = ["self"]
  filter {
    name   = "name"
    values = ["CT_Auto_Scaling_Webhost"]
  }
}

# Create Launch Template Resource
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

# Create auto scaling group
resource "aws_autoscaling_group" "aws-autoscaling-group" {
  name                = "${var.project_name}-ASG-Group"
  vpc_zone_identifier = [for s in aws_subnet.public_subnets : s.id]
  desired_capacity    = 1
  max_size            = 4
  min_size            = 1

  launch_template {
    id      = aws_launch_template.aws-launch-template.id
    version = aws_launch_template.aws-launch-template.latest_version
  }
}

# Create target tracking scaling policy for average CPU utilization
resource "aws_autoscaling_policy" "avg_cpu_scaling_policy" {
  name                   = "avg_cpu_scaling_policy"
  policy_type            = "TargetTrackingScaling"
  autoscaling_group_name = aws_autoscaling_group.aws-autoscaling-group.name
  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 25.0
  }
  estimated_instance_warmup = 180
}

# attach auto scaling group to Application Load Balancer ALB
resource "aws_autoscaling_attachment" "asg_attachment_alb" {
  autoscaling_group_name = aws_autoscaling_group.aws-autoscaling-group.id
  lb_target_group_arn    = aws_lb_target_group.alb_target_group.arn
}

```

Terraform Apply output:

```
Plan: 21 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + alb_target_group_arn           = (known after apply)
  + autoscaling_group_arn          = (known after apply)
  + autoscaling_group_id           = (known after apply)
  + autoscaling_group_name         = "CT-ASG-Group"
  + launch_template_id             = (known after apply)
  + launch_template_latest_version = (known after apply)
aws_vpc.app_vpc: Creating...
aws_vpc.app_vpc: Creation complete after 5s [id=vpc-02b906e7043f3d8e6]
aws_internet_gateway.igw: Creating...
aws_subnet.public_subnets[0]: Creating...
aws_subnet.public_subnets[2]: Creating...
aws_subnet.public_subnets[1]: Creating...
aws_subnet.public_subnets[3]: Creating...
aws_security_group.sg: Creating...
aws_lb_target_group.alb_target_group: Creating...
aws_subnet.public_subnets[2]: Creation complete after 2s [id=subnet-0541a9c0a045c7363]
aws_subnet.public_subnets[0]: Creation complete after 2s [id=subnet-028aee147164dc72d]
aws_subnet.public_subnets[1]: Creation complete after 2s [id=subnet-09ebd094c0505109e]
aws_subnet.public_subnets[3]: Creation complete after 2s [id=subnet-0a7b17965f98308b6]
aws_internet_gateway.igw: Creation complete after 3s [id=igw-06e2271835e6f4da0]
aws_route_table.public_rt: Creating...
aws_lb_target_group.alb_target_group: Creation complete after 4s [id=arn:aws:elasticloadbalancing:us-east-1:197317184204:targetgroup/CT-tg/ea3170d1f5d7a0cb]
aws_security_group.sg: Creation complete after 5s [id=sg-06e64d1f78fa99fbb]
aws_security_group.aws-sg-load-balancer: Creating...
aws_launch_template.aws-launch-template: Creating...
aws_route_table.public_rt: Creation complete after 2s [id=rtb-075b7945b1debdf87]
aws_route_table_association.public_subnet_asso[2]: Creating...
aws_route_table_association.public_subnet_asso[0]: Creating...
aws_route_table_association.public_subnet_asso[3]: Creating...
aws_route_table_association.public_subnet_asso[1]: Creating...
aws_launch_template.aws-launch-template: Creation complete after 1s [id=lt-01a2a11483417456c]
aws_autoscaling_group.aws-autoscaling-group: Creating...
aws_route_table_association.public_subnet_asso[1]: Creation complete after 1s [id=rtbassoc-002e1ee56cf799d71]
aws_route_table_association.public_subnet_asso[2]: Creation complete after 1s [id=rtbassoc-03d19759add215b30]
aws_route_table_association.public_subnet_asso[0]: Creation complete after 1s [id=rtbassoc-017a953531b315031]
aws_route_table_association.public_subnet_asso[3]: Creation complete after 2s [id=rtbassoc-04a392ea7cb2bb025]
aws_security_group.aws-sg-load-balancer: Creation complete after 5s [id=sg-056f59c0d068ff490]
aws_security_group_rule.ASG-sg-to-alb-sg-ingress: Creating...
aws_lb.aws-application_load_balancer: Creating...
aws_security_group_rule.ASG-sg-to-alb-sg-ingress: Creation complete after 1s [id=sgrule-3273163239]
aws_autoscaling_group.aws-autoscaling-group: Still creating... [10s elapsed]
aws_lb.aws-application_load_balancer: Still creating... [10s elapsed]
aws_autoscaling_group.aws-autoscaling-group: Still creating... [20s elapsed]
aws_lb.aws-application_load_balancer: Still creating... [20s elapsed]
aws_autoscaling_group.aws-autoscaling-group: Still creating... [30s elapsed]
aws_lb.aws-application_load_balancer: Still creating... [30s elapsed]
aws_autoscaling_group.aws-autoscaling-group: Still creating... [40s elapsed]
aws_lb.aws-application_load_balancer: Still creating... [40s elapsed]
aws_autoscaling_group.aws-autoscaling-group: Creation complete after 46s [id=CT-ASG-Group]
aws_autoscaling_attachment.asg_attachment_alb: Creating...
aws_autoscaling_policy.avg_cpu_scaling_policy: Creating...
aws_autoscaling_attachment.asg_attachment_alb: Creation complete after 2s [id=CT-ASG-Group-20231016100015880300000002]
aws_autoscaling_policy.avg_cpu_scaling_policy: Creation complete after 2s [id=avg_cpu_scaling_policy]
aws_lb.aws-application_load_balancer: Still creating... [50s elapsed]
aws_lb.aws-application_load_balancer: Still creating... [1m0s elapsed]
aws_lb.aws-application_load_balancer: Still creating... [1m10s elapsed]
aws_lb.aws-application_load_balancer: Still creating... [1m20s elapsed]
aws_lb.aws-application_load_balancer: Still creating... [1m30s elapsed]
aws_lb.aws-application_load_balancer: Still creating... [1m40s elapsed]
aws_lb.aws-application_load_balancer: Still creating... [1m50s elapsed]
aws_lb.aws-application_load_balancer: Still creating... [2m10s elapsed]
aws_lb.aws-application_load_balancer: Still creating... [2m20s elapsed]
aws_lb.aws-application_load_balancer: Creation complete after 2m28s [id=arn:aws:elasticloadbalancing:us-east-1:197317184204:loadbalancer/app/CT-alb/86487cfbd838c4c4]       
aws_lb_listener.alb_http_listener: Creating...
aws_lb_listener.alb_http_listener: Creation complete after 1s [id=arn:aws:elasticloadbalancing:us-east-1:197317184204:listener/app/CT-alb/86487cfbd838c4c4/8d91a9de371f1fa6]

Apply complete! Resources: 21 added, 0 changed, 0 destroyed.

Outputs:

alb_target_group_arn = "arn:aws:elasticloadbalancing:us-east-1:197317184204:targetgroup/CT-tg/ea3170d1f5d7a0cb"
autoscaling_group_arn = "arn:aws:autoscaling:us-east-1:197317184204:autoScalingGroup:ac194ac6-81c0-4911-a369-454cd27a02d4:autoScalingGroupName/CT-ASG-Group"
autoscaling_group_id = "CT-ASG-Group"
autoscaling_group_name = "CT-ASG-Group"
launch_template_id = "lt-01a2a11483417456c"
launch_template_latest_version = 1
```

Running on us-east-1c
![Alt text](Code/AutoScalingGroup/runningec2.png)

![Alt text](Code/AutoScalingGroup/runningec2meta.png)

After stressing the CPU

![Alt text](Code/AutoScalingGroup/scaledec2.png)

![Alt text](Code/AutoScalingGroup/newec2a.png)

![Alt text](Code/AutoScalingGroup/newec2b.png)

![Alt text](Code/AutoScalingGroup/newec2c.png)


Autoscalling Worked!!!


Terraform Destroy Output:

```
Plan: 0 to add, 0 to change, 21 to destroy.

Changes to Outputs:
  - alb_target_group_arn           = "arn:aws:elasticloadbalancing:us-east-1:197317184204:targetgroup/CT-tg/ea3170d1f5d7a0cb" -> null
  - autoscaling_group_arn          = "arn:aws:autoscaling:us-east-1:197317184204:autoScalingGroup:ac194ac6-81c0-4911-a369-454cd27a02d4:autoScalingGroupName/CT-ASG-Group" -> null
  - autoscaling_group_id           = "CT-ASG-Group" -> null
  - autoscaling_group_name         = "CT-ASG-Group" -> null
  - launch_template_id             = "lt-01a2a11483417456c" -> null
  - launch_template_latest_version = 1 -> null
aws_autoscaling_attachment.asg_attachment_alb: Destroying... [id=CT-ASG-Group-20231016100015880300000002]
aws_route_table_association.public_subnet_asso[2]: Destroying... [id=rtbassoc-03d19759add215b30]
aws_route_table_association.public_subnet_asso[0]: Destroying... [id=rtbassoc-017a953531b315031]
aws_route_table_association.public_subnet_asso[3]: Destroying... [id=rtbassoc-04a392ea7cb2bb025]
aws_route_table_association.public_subnet_asso[1]: Destroying... [id=rtbassoc-002e1ee56cf799d71]
aws_security_group_rule.ASG-sg-to-alb-sg-ingress: Destroying... [id=sgrule-3273163239]
aws_lb_listener.alb_http_listener: Destroying... [id=arn:aws:elasticloadbalancing:us-east-1:197317184204:listener/app/CT-alb/86487cfbd838c4c4/8d91a9de371f1fa6]
aws_autoscaling_policy.avg_cpu_scaling_policy: Destroying... [id=avg_cpu_scaling_policy]
aws_autoscaling_attachment.asg_attachment_alb: Destruction complete after 2s
aws_autoscaling_policy.avg_cpu_scaling_policy: Destruction complete after 2s
aws_autoscaling_group.aws-autoscaling-group: Destroying... [id=CT-ASG-Group]
aws_route_table_association.public_subnet_asso[3]: Destruction complete after 2s
aws_route_table_association.public_subnet_asso[2]: Destruction complete after 2s
aws_route_table_association.public_subnet_asso[1]: Destruction complete after 2s
aws_route_table_association.public_subnet_asso[0]: Destruction complete after 2s
aws_lb_listener.alb_http_listener: Destruction complete after 2s
aws_security_group_rule.ASG-sg-to-alb-sg-ingress: Destruction complete after 2s
aws_route_table.public_rt: Destroying... [id=rtb-075b7945b1debdf87]
aws_lb_target_group.alb_target_group: Destroying... [id=arn:aws:elasticloadbalancing:us-east-1:197317184204:targetgroup/CT-tg/ea3170d1f5d7a0cb]
aws_lb.aws-application_load_balancer: Destroying... [id=arn:aws:elasticloadbalancing:us-east-1:197317184204:loadbalancer/app/CT-alb/86487cfbd838c4c4]
aws_lb_target_group.alb_target_group: Destruction complete after 1s
aws_route_table.public_rt: Destruction complete after 2s
aws_internet_gateway.igw: Destroying... [id=igw-06e2271835e6f4da0]
aws_autoscaling_group.aws-autoscaling-group: Still destroying... [id=CT-ASG-Group, 10s elapsed]
aws_lb.aws-application_load_balancer: Still destroying... [id=arn:aws:elasticloadbalancing:us-east-1:...adbalancer/app/CT-alb/86487cfbd838c4c4, 10s elapsed]
aws_lb.aws-application_load_balancer: Destruction complete after 10s
aws_security_group.aws-sg-load-balancer: Destroying... [id=sg-056f59c0d068ff490]
aws_internet_gateway.igw: Still destroying... [id=igw-06e2271835e6f4da0, 10s elapsed]
aws_autoscaling_group.aws-autoscaling-group: Still destroying... [id=CT-ASG-Group, 20s elapsed]
aws_security_group.aws-sg-load-balancer: Still destroying... [id=sg-056f59c0d068ff490, 10s elapsed]
aws_internet_gateway.igw: Still destroying... [id=igw-06e2271835e6f4da0, 20s elapsed]
aws_autoscaling_group.aws-autoscaling-group: Still destroying... [id=CT-ASG-Group, 30s elapsed]
aws_security_group.aws-sg-load-balancer: Still destroying... [id=sg-056f59c0d068ff490, 20s elapsed]
aws_internet_gateway.igw: Still destroying... [id=igw-06e2271835e6f4da0, 30s elapsed]
aws_autoscaling_group.aws-autoscaling-group: Still destroying... [id=CT-ASG-Group, 40s elapsed]
aws_security_group.aws-sg-load-balancer: Still destroying... [id=sg-056f59c0d068ff490, 30s elapsed]
aws_internet_gateway.igw: Still destroying... [id=igw-06e2271835e6f4da0, 40s elapsed]
aws_autoscaling_group.aws-autoscaling-group: Still destroying... [id=CT-ASG-Group, 50s elapsed]
aws_security_group.aws-sg-load-balancer: Still destroying... [id=sg-056f59c0d068ff490, 40s elapsed]
aws_internet_gateway.igw: Still destroying... [id=igw-06e2271835e6f4da0, 50s elapsed]
aws_autoscaling_group.aws-autoscaling-group: Destruction complete after 56s
aws_subnet.public_subnets[3]: Destroying... [id=subnet-0a7b17965f98308b6]
aws_subnet.public_subnets[0]: Destroying... [id=subnet-028aee147164dc72d]
aws_subnet.public_subnets[1]: Destroying... [id=subnet-09ebd094c0505109e]
aws_subnet.public_subnets[2]: Destroying... [id=subnet-0541a9c0a045c7363]
aws_launch_template.aws-launch-template: Destroying... [id=lt-01a2a11483417456c]
aws_launch_template.aws-launch-template: Destruction complete after 2s
aws_security_group.aws-sg-load-balancer: Destruction complete after 47s
aws_security_group.sg: Destroying... [id=sg-06e64d1f78fa99fbb]
aws_internet_gateway.igw: Destruction complete after 57s
aws_subnet.public_subnets[0]: Destruction complete after 3s
aws_subnet.public_subnets[1]: Destruction complete after 3s
aws_subnet.public_subnets[2]: Destruction complete after 3s
aws_subnet.public_subnets[3]: Destruction complete after 3s
aws_security_group.sg: Destruction complete after 2s
aws_vpc.app_vpc: Destroying... [id=vpc-02b906e7043f3d8e6]
aws_vpc.app_vpc: Destruction complete after 2s

Destroy complete! Resources: 21 destroyed.
```