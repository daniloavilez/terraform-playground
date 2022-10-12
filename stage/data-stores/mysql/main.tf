terraform {
  backend "s3" {
    bucket = "terraform-study-code-demo"
    key = "stage/data-stores/mysql/terraform.tfstate"
    region = "us-east-1"
    encrypt = true
  }
}

provider "aws" {
  region = "us-east-1"
}

module "database" {
  source = "../../../modules/data-stores/mysql"

  database_name     = "mysql_stage"
  instance_class    = "db.t2.micro"
  db_password       = var.db_password
}