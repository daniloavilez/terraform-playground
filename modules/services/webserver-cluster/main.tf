provider "aws" {
  region = "us-east-1"
}

resource "aws_launch_configuration" "example" {
  image_id        = "ami-40d28157"
  instance_type   = var.instance_type
  security_groups = [ aws_security_group.instance.id ]

  user_data = element(concat(data.template_file.user_data.*.rendered, data.template_file.user_data_new.*.rendered), 0)
  
  # If a resource has create_before_destroy, all dependencies it has must be have create_before_destroy too (example here is the security group)
  lifecycle {
    create_before_destroy = true  
  }
}

# if var.enable_new_user_data == false {
data "template_file" "user_data" {
  count = 1 - var.enable_new_user_data

  template = file("${path.module}/user-data.sh")

  vars = {
    server_port = var.server_port
    db_address  = data.terraform_remote_state.db.outputs.address
    db_port     = data.terraform_remote_state.db.outputs.port
  } 
}
# } else {
data "template_file" "user_data_new" {
  count = var.enable_new_user_data

  template = file("${path.module}/user-data-new.sh")

  vars = {
    server_port = var.server_port
  } 
}
# }

resource "aws_security_group" "instance" {
  name = "${var.cluster_name}-example-instance"

  ingress {
      from_port     = var.server_port
      to_port       = var.server_port
      protocol      = "tcp"
      cidr_blocks   = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "example" {
  launch_configuration = aws_launch_configuration.example.id
  availability_zones = data.aws_availability_zones.all.names

  # It tells to ASG (autoscaling_group) when an instance starts register on ELB
  load_balancers = [ aws_elb.example.name ]
  
  # This tells the ASG to use the ELB’s health check to determine 
  # if an Instance is healthy or not and to automatically replace Instances if the ELB reports them as unhealthy.
  health_check_type = "ELB"

  min_size = var.min_size
  max_size = 10

  lifecycle {
    create_before_destroy = true
  }

  tag {
    key                 = "Name"
    value               = "${var.cluster_name}-asg-example"
    propagate_at_launch = true
  }
}

data "aws_availability_zones" "all" {}

resource "aws_elb" "example" {
  name                = "${var.cluster_name}-asg-example"
  availability_zones  = data.aws_availability_zones.all.names
  security_groups     = [ aws_security_group.elb.id ]

  lifecycle {
    create_before_destroy = true
  }

  listener {
    lb_port           = 80
    lb_protocol       = "http"
    instance_port     = var.server_port
    instance_protocol = "http"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    interval            = 30
    target              = "HTTP:${var.server_port}/"
  }
}

resource "aws_security_group" "elb" {
  name = "${var.cluster_name}-elb"

  lifecycle {
    create_before_destroy = true
  }

  ingress {
    from_port   = 80
    protocol    = "tcp"
    to_port     = 80
    cidr_blocks = [ "0.0.0.0/0" ]
  }

  egress {
    cidr_blocks = [ "0.0.0.0/0" ]
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
  }
}

# if var.enable_autoscaling {
resource "aws_autoscaling_schedule" "scale_out_during_business_hours" {
  # That's the way to make a conditional if, a boolean value TRUE will be convert to 1 (creating the resource), otherwise value FALSE will be converted to 0 (not creating the resource)
  count = var.enable_autoscaling

  scheduled_action_name = "scale-out-during-business-hours"
  min_size              = 2
  max_size              = 10
  desired_capacity      = 10
  recurrence            = "0 9 * * *"

  autoscaling_group_name = aws_autoscaling_group.example.name
}

resource "aws_autoscaling_schedule" "scale_in_at_night" {
  count = var.enable_autoscaling

  scheduled_action_name = "scale-in-at-night"
  min_size              = 2
  max_size              = 10
  desired_capacity      = 2
  recurrence            = "0 17 * * *"

  autoscaling_group_name = aws_autoscaling_group.example.name
}
# }

data "terraform_remote_state" "db" {
  backend = "s3"

  config = {
    bucket = var.db_remote_state_bucket
    key    = var.db_remote_state_key
    region = "us-east-1"
  }
}