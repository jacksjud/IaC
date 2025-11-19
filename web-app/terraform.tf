# #####################################################################
# #####################################################################
# #####################################################################
# # Terraform Block

# # Specifies providers
# terraform {

#     required_providers {
#         aws = {
#             source = "hashicorp/aws"
#             version = "~> 5.0"
#         }

#         cloudflare = {
#             source = "cloudflare/cloudflare"
#             version = "~>4.0"
#         }
#     }

#     # Cloud is much easier to work with than using s3 and dynamodb
#     # that we aren't even using, plus the weird shift from local to backend is just too weird
#     cloud { 
#         organization = "static-site" 

#         workspaces { 
#             name = "static-site-portfolio" 
#         } 
#     } 

#     required_version = ">=1.13"
# }
