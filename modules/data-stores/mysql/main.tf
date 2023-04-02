resource "aws_db_instance" "example" {
  engine              = "mysql"
  allocated_storage   = 10
  name                = "${var.database_name}_database"
  instance_class      = var.instance_class
  username            = "admin"
  password            = var.db_password
  skip_final_snapshot = true
}
