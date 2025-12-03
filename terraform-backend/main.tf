provider "aws" {
  region = "us-east-1"
}

output "s3_backend_outputs" {
  value = {
    bucket         = aws_s3_bucket.my_terraform_state_bucket.bucket
    role_arn       = aws_iam_role.terraform.arn
  }
}