provider "aws" {
  region = "us-east-1"
}

# for i =0; i < 3; i++ {
resource "aws_iam_user" "example" {
  name  = element(var.user_names, count.index)
  count = length(var.user_names)
}
# }

data "aws_iam_policy_document" "ec2_read_only" {
  statement {
    effect = "Allow"
    actions = [ "ec2:Describe" ]
    resources = [ "*" ]
  }
}

resource "aws_iam_policy" "ec2_read_only" {
  name = "ec2-read-only"
  policy = data.aws_iam_policy_document.ec2_read_only.json
}

resource "aws_iam_user_policy_attachment" "ec2_access" {
  count = length(var.user_names)
  user = element(aws_iam_user.example.*.name, count.index)
  policy_arn = aws_iam_policy.ec2_read_only.arn
}