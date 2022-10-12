terraform {
  backend "s3" {
    bucket = "terraform-study-code-demo"
    key = "stage/services/webserver-cluster/terraform.tfstate"
    region = "us-east-1"
    encrypt = true
  }
}

provider "aws" {
  region = "us-east-1"
}

module "webserver_cluster" {
  source = "../../../modules/services/webserver-cluster"

  cluster_name              = "webservers-stage"
  db_remote_state_bucket    = "terraform-study-code-demo"
  db_remote_state_key       = "stage/data-stores/mysql/terraform.tfstate"
  
  instance_type             = "t2.micro"
  min_size                  = 2
  enable_autoscaling        = 0
  enable_new_user_data      = 1
}