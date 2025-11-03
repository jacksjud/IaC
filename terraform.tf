# # Specifies providers
# terraform {

#     required_providers {
#       aws = {
#         source = "hashicorp/aws"
#         version = "~> 5.0"
#       }
#     }

#     # This part is commented out for initial 'boot', then uncommented
#     # to use resources
#     backend "s3" {

#         bucket = aws_s3_bucket.terraform_state.id
#         key = "terraform.tfstate"
#         region = "us-west-2"
#         dynamodb_table = aws_dynamodb_table.terraform_locks.id
#         encrypt = true
#     }

#     required_version = ">=1.13"
# }
