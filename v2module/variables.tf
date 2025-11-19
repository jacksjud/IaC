#####################################################################
# General Variables

variable "region" {
    description = "Default region for provider"
    type = string
    default = "us-west-2"
}

variable "app_name" {
    description = "Name of the web application"
    type = string
    default = "portfolio-web-app"
}

# Avoids naming conflicts
variable "env_name" {
    description = "Deployment environment (dev/staging/production)"
    type = string
    default = "dev"
  
}


#####################################################################
# AWS EC2 Instances
variable "instance_name" {
    description = "Name of EC2 instance"
    type = string
}

variable "instance_type" {
    description = "EC2 instance type"
    type = string
    default = "t3.micro"
}

variable "ami" {
    description = "Amazon machine image to use for ec2 instance"
    type = string
    # Empty string as a placeholder default, 
    # because we use conditional to trigger data block
    default = ""
}

#####################################################################
# Domain

variable "domain" {
    description = "Website domain name and alternative names"
    type = list(string)
    default = ["judahrjackson.com", "www.judahrjackson.com"]
}




#####################################################################
# Cloudflare

variable "cloudflare_api_token" {
    description = "API token for managing Cloudflare DNS"
    type = string
    sensitive = true
    default = ""
}

variable "cloudflare_zone_id" {
    description = "Zone ID of the domain in Cloudflare"
    type = string
    default = ""
}




#####################################################################
# Database Variables

# variable "db_name" {
#     description = "Name of database instance"
#     type = string
#     default = ""
# }

# variable "db_user" {
#     description = "Username for database"
#     type = string
#     default = ""
# }

# variable "db_pass" {
#     description = "Password for database"
#     type = string
#     sensitive = true
#     default = ""
# }




#####################################################################
# Debugging

# IP
variable "ip_addr" {
    description = "Personal IP Address"
    type = string
    default = ""
    sensitive = true
}