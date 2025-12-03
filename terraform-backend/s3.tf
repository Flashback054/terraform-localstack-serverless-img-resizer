### Terraform resouces for S3 Backend
resource "aws_s3_bucket" "my_terraform_state_bucket" {
  bucket = "my-terraform-state-bucket"
}

resource "aws_s3_bucket_versioning" "my_terraform_state_bucket_versioning" {
  bucket = aws_s3_bucket.my_terraform_state_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "my_terraform_state_bucket_encryption" {
  bucket = aws_s3_bucket.my_terraform_state_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
