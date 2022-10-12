provider "aws" {
  region = "us-east-1"
}

module "database" {
  source = "../../../modules/data-stores/mysql"

  database_name = "mysql_prod"
  instance_class = "db.t2.micro"
}