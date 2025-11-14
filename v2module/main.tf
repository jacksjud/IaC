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
