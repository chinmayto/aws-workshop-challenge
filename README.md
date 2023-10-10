# aws-workshop-challenge
AWS Workshop Challenge

**This Repository has been created for 12 Week AWS Workshop Challenge by Prasad Rao**

Follow the week by week instructions to get a handson with the AWS Services

These labs are for the learning and hands-on for terraform using VS Code and assume that you have understanding knowledge of AWS services and concepts

## Setup
Before we will go deep dive to workskop, lets create environment set up. This is one time set up and can be used in future challenge.

1. ***`Free account in AWS`*** - Link: https://aws.amazon.com/free/
2. ***`Install VS Code.`*** - Download link - https://code.visualstudio.com/Download
3. ***`Install Terraform.`*** - Setup Terraform Locally - https://www.youtube.com/watch?v=ljYzclmsvF4
4. ***`Install AWS CLI.`*** - Installing AWS CLI - https://www.youtube.com/watch?v=u0JyzUGzvJA
5. ***`Configure aws cli to be used in Terraform.`*** - Configure AWS CLI with Terraform - https://www.youtube.com/watch?v=XxTcw7UTues


Important Terraform commands.
1. ***`terraform init `*** - This command is used for initialize the terraform.
2. ***` terraform fmt `*** -  This command is used for format the terraform code.
3. ***` terraform validate `*** - This command is used for validate the terraform code.
4. ***` terraform plan `*** - This command is used to describe the plan. This is highly recommended to run before apply the changes.
5. ***` terraform apply `*** - If you are statisfy with changes, run this command to apply the changes.

## 1. Key Pair Creation

Script to create AWS EC2 Key Pair. Rememer to add the key to .gitignore file, otherwise private key will be exposed to public git repo

```terraform {
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

![Alt text](image.png)