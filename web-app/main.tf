/*
To use the module we made `v2module`, we setup our environment the same,
with a terraform block, our providers, variables we want to use, etc.
but then, we add a 'module' block:
*/

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

# Cloudflare provider 
provider "cloudflare" {
    api_token = var.cloudflare_api_token
}

#####################################################################
#####################################################################
#####################################################################
# Variables

#####################################################################
# Cloudflare
# Exclusive to whoever is using the module

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

module "web_app_1" {
    source = "github.com/jacksjud/IaC//v2module?ref=main"

    # Input variables

    app_name = "web-app-1"
    instance_name = "site-web-app-1"
    env_name = "production"
    
}

module "web_app_2" {
    source = "github.com/jacksjud/IaC//v2module?ref=main"

    # Input variables

    app_name = "web-app-2"
    instance_name = "site-web-app-2"
    env_name = "production"
    
}