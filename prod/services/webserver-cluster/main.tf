provider "aws" {
  region = "us-east-1"
}

module "webserver_cluster" {
  source = "../../../modules/services/webserver-cluster"

  cluster_name              = "webservers-prod"
  db_remote_state_bucket    = "terraform-study-code-demo"
  db_remote_state_key       = "prod/data-stores/mysql/terraform.tfstate"
  
  instance_type             = "m4.large"
  min_size                  = 2
  enable_autoscaling        = 1
  enable_new_user_data      = 0
}

