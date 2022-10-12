terraform {
  backend "s3" {
      bucket = "terraform-study-code-demo"
      key = "global/s3/terraform.tfstate"
      region = "us-east-1"
      encrypt = true
  }
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "terraform_state" {
  bucket = "terraform-study-code-demo"

  versioning {
    enabled = true
  }

  lifecycle {
    prevent_destroy = true
  }
}