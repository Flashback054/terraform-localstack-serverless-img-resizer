terraform {
  backend "s3" {
    bucket = "my-terraform-state-bucket"
    key = "terraform/state"
    region = "us-east-1"
    use_lockfile = true
    encrypt = true
    role_arn = "arn:aws:iam::000000000000:role/TerraformStateRole"
  }
}