#####################################################################
# Cloudflare Connection


# SSL Certificate Retrieval
resource "aws_acm_certificate" "site_cert" {
    domain_name = var.domain[0]
    subject_alternative_names = slice(var.domain , 0 , 1)
    validation_method = "DNS"

    lifecycle {
      create_before_destroy = true
    }
}

# ACM Validation for Cloudflare
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

locals {
  subdomain = var.env_name == "production" ? "" : "${var.env_name}"
}

# With ELB existing, automatically create the public CNAME record in Cloudflare
resource "cloudflare_record" "elb_alias" {
    allow_overwrite = true
    zone_id = var.cloudflare_zone_id
    # For distinction between production, dev, staging, etc.
    name = "${local.subdomain}${var.domain[0]}"
    type    = "CNAME"
    content   = aws_elb.classic_lb.dns_name
    proxied = true   # Cloudflare CDN + HTTPS proxy enabled (?)
}
