#####################################################################
#####################################################################
#####################################################################
# Terraform Block

# Specifies providers
terraform {

    required_providers {
        aws = {
            source = "hashicorp/aws"
            version = "~> 5.0"
        }

        cloudflare = {
            source = "cloudflare/cloudflare"
            version = "~>4.0"
        }
    }

    # # This part is commented out for initial 'boot', then uncommented
    # # to use resources
    # backend "s3" {

    #     bucket = "amzn-s3-static-site-bucket"
    #     key = "terraform.tfstate"
    #     region = "us-west-2"
    #     use_lockfile = true
    #     encrypt = true
    # }

    # Cloud is much easier to work with than using s3 and dynamodb
    # that we aren't even using, plus the weird shift from local to backend is just too weird
    cloud { 
        organization = "static-site" 

        workspaces { 
            name = "static-site-portfolio" 
        } 
    } 

    required_version = ">=1.13"
}


#####################################################################
#####################################################################
#####################################################################
# Providers

# Defines default region for said provider(s)
provider "aws" {
    region = "us-west-2"
}

# 
provider "cloudflare" {
    api_token = var.cloudflare_api_token
}


#####################################################################
#####################################################################
#####################################################################
# SSL Certificate Retrieval

resource "aws_acm_certificate" "site_cert" {
    domain_name = "judahrjackson.com"  
    subject_alternative_names = [ "www.judahrjackson.com" ]
    validation_method = "DNS"

    lifecycle {
      create_before_destroy = true
    }
}

#####################################################################
#####################################################################
#####################################################################
# Automate Cloudflare record keeping with CNAMEs

variable "cloudflare_api_token" {
    description = "API token for managing Cloudflare DNS"
    type = string
    sensitive = true
}

variable "cloudflare_zone_id" {
    description = "Zone ID of the domain in Cloudflare"
    type = string
  
}

resource "cloudflare_record" "acm_validation" {
    for_each = {
        for dvo in aws_acm_certificate.site_cert.domain_validation_options : dvo.domain_name => {
        name  = dvo.resource_record_name
        type  = dvo.resource_record_type
        value = dvo.resource_record_value
        }
    }

    zone_id = var.cloudflare_zone_id
    name    = each.value.name
    type    = each.value.type
    content = each.value.value
    ttl     = 60
  
}

# Tell ACM to use those records for validation
resource "aws_acm_certificate_validation" "site_cert_validation" {
  certificate_arn         = aws_acm_certificate.site_cert.arn
  validation_record_fqdns = [for record in cloudflare_record.acm_validation : record.hostname]
}


# With ELB existing, automatically create the public CNAME record in Cloudflare
resource "cloudflare_record" "elb_alias" {
    allow_overwrite = true
    zone_id = var.cloudflare_zone_id
    name    = "@"  # or "www"
    type    = "CNAME"
    content   = aws_elb.classic_lb.dns_name
    proxied = true   # Cloudflare CDN + HTTPS proxy enabled
}

#####################################################################
#####################################################################
#####################################################################
# AWS instances, still using free tier

resource "aws_instance" "instance_1" {
    ami = data.aws_ami.amazon_linux_2.id
    instance_type = "t3.micro"

    tags = {
        Name = "Free Tier Instance 1"
    }

    security_groups = [ aws_security_group.instances.name ]
    user_data = <<-EOF
                #!/bin/bash
                echo "Hello, World 1" > index.html
                python3 -m http.server 8080 &
                EOF


}

resource "aws_instance" "instance_2" {
    ami = data.aws_ami.amazon_linux_2.id
    instance_type = "t3.micro"

    tags = {
        Name = "Free Tier Instance 2"
    }

    security_groups = [ aws_security_group.instances.name ]

    user_data = <<-EOF
                #!/bin/bash
                echo "Hello, World 2" > index.html
                python3 -m http.server 8080 &
                EOF

}

# Data block, used to query for the most recent official amazon linux 2 ami
# Data blocks reference existing resources within AWS
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

#####################################################################
#####################################################################
#####################################################################
# Configuration and Security Groups

# Get default VPC
data "aws_vpc" "default_vpc" {
  default = true
}

# Get subnets in the default VPC
data "aws_subnets" "default_subnet" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default_vpc.id]
  }

  filter {
    name   = "tag:Environment"
    values = ["boot_test"]
  }
}

# Security group for instances
resource "aws_security_group" "instances" {
  name        = "instance-security-group-0"
  description = "Security group for app instances"
  vpc_id      = data.aws_vpc.default_vpc.id
}

resource "aws_security_group_rule" "allow_http_inbound" {
  type              = "ingress"
  security_group_id = aws_security_group.instances.id
  from_port         = 8080
  to_port           = 8080
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

# Security group for Classic Load Balancer
resource "aws_security_group" "elb" {
  name        = "classic-elb-sg-0"
  description = "Security group for Classic ELB"
  vpc_id      = data.aws_vpc.default_vpc.id
}

# Allow HTTP from anywhere
resource "aws_security_group_rule" "allow_elb_http_inbound" {
  type              = "ingress"
  security_group_id = aws_security_group.elb.id
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

# Allow outbound to anywhere
resource "aws_security_group_rule" "allow_elb_all_outbound" {
  type              = "egress"
  security_group_id = aws_security_group.elb.id
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

#####################################################################
#####################################################################
#####################################################################
# Classic Load Balancer (ELB)

resource "aws_elb" "classic_lb" {
  name               = "classic-web-elb-0"
  availability_zones = [ "us-west-2a", "us-west-2b", "us-west-2c" ]
  subnets            = data.aws_subnets.default_subnet.ids
  security_groups    = [aws_security_group.elb.id]
  cross_zone_load_balancing = true
  idle_timeout                = 60
  connection_draining         = true
  connection_draining_timeout = 300

  listener {
    instance_port     = 8080
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  listener {
    instance_port      = 8080
    instance_protocol  = "http"
    lb_port            = 443
    lb_protocol        = "https"
    ssl_certificate_id = aws_acm_certificate.site_cert.arn
  }

  health_check {
    target              = "HTTP:8080/"
    interval            = 15
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  instances = [
    aws_instance.instance_1.id,
    aws_instance.instance_2.id
  ]

  tags = {
    Name = "classic-web-elb"
  }
}

#####################################################################
#####################################################################
#####################################################################
# DNS setup, 

# resource "aws_acm_certificate" "site_cert" {
#   domain_name       = "judahrjackson.com"
#   validation_method = "DNS"

#   subject_alternative_names = ["www.judahrjackson.com"]

#   lifecycle {
#     create_before_destroy = true
#   }
# }

# resource "aws_route53_record" "cert_validation" {
#     # only needed if using Route53; skip this if Cloudflare is DNS
#     # for_each = {
#     #     for dvo in aws_acm_certificate.site_cert.domain_validation_options : dvo.domain_name => {
#     #     name  = dvo.resource_record_name
#     #     type  = dvo.resource_record_type
#     #     value = dvo.resource_record_value
#     #     }
#     # }

#     name    = each.value.name
#     type    = each.value.type
#     zone_id = aws_elb.classic_lb.zone_id
#     records = [each.value.value]
#     ttl     = 60
# }

# # Validate manually if using Cloudflare DNS
# resource "aws_acm_certificate_validation" "site_cert_validation" {
#   certificate_arn         = aws_acm_certificate.site_cert.arn
#   validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
# }



#####################################################################
#####################################################################
#####################################################################
# TO BE DELETED

# Currently provides the dns name for the classic loadbalancer, goal will
# be to make it so Cloudflare will route our domain to the loadbalancer's dns
# then AWS can take control (limiting Cloudflare dependency).
output "elb_dns_name" {
    value =  aws_elb.classic_lb.dns_name
}
