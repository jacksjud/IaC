# This acts as a working example (with minimal explanation) of how one would setup
# an S3 Bucket and DynamoDB Table for state management in the Terraform Block.

# Specifies providers
terraform {

    required_providers {
      aws = {
        source = "hashicorp/aws"
        version = "~> 5.0"
      }
    }

    # This part is commented out for initial 'boot', then uncommented
    # to use resources
    backend "s3" {

        bucket = aws_s3_bucket.terraform_state.id
        key = "terraform.tfstate"
        region = "us-west-2"
        dynamodb_table = aws_dynamodb_table.terraform_locks.id
        encrypt = true
    }

    required_version = ">=1.13"
}


resource "aws_s3_bucket" "bucket" {
  bucket_prefix = "devops-directive-web-app-data"
  force_destroy = true
}

resource "aws_s3_bucket_versioning" "bucket_versioning" {
  bucket = aws_s3_bucket.bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "bucket_crypto_conf" {
  bucket = aws_s3_bucket.bucket.bucket
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Database

resource "aws_db_instance" "db_instance" {
    allocated_storage = 20
    storage_type = "standard"
    engine = "postgres"
    instance_class = "db.t3.micro"
    # Must be defined variables to use like this, otherwise just use strings (bad practice)
    # name = var.db_name
    # username = var.db_user
    # password = var.db_pass
    skip_final_snapshot = true
  
}