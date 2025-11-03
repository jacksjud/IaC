/*
This code is a working example of how the EC2 resource can be provisioned from AWS.
It assumes work with Terraform Cloud for state management, as well as exclusively using
free-tier resources from AWS.

*/

# Specifies providers
terraform {

    required_providers {
        aws = {
            source = "hashicorp/aws"
            version = "~> 5.0"
        }
    }

    cloud { 
        organization = "static-site" 

        workspaces { 
            name = "static-site-portfolio" 
        } 
    } 

    required_version = ">=1.13"
}


# Defines default region for said provider
provider "aws" {
  region = "us-west-2"
}


# Corresponds to instance within EC2, provides OS (AMI) via data block and instance type
resource "aws_instance" "ex" {
  ami = data.aws_ami.amazon_linux_2.id
  instance_type = "t3.micro"

  tags = {
    Name = "Free Tier Instance"
  }
}

# Data block, used to query for the most recent official amazon linux 2 ami
data "aws_ami" "amazon_linux_2" {
    most_recent = true
    owners = ["amazon"]

    filter {
      name = "name"
      values = ["amzn2-ami-hvm-*-x86_64-gp2"]
    }

    filter {
        name = "virtualization-type"
        values = ["hvm"]
    }
}