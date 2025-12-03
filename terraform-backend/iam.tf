locals {
  terraform_principal_arns    = try(var.terraform_principal_arns, []) != [] ? var.terraform_principal_arns : [data.aws_caller_identity.current.arn]
}

# IAM Role and Policy for Terraform State Access
data "aws_caller_identity" "current" {}

resource "aws_iam_role" "terraform" {
  name = "TerraformStateRole"

  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { AWS = local.terraform_principal_arns }
    }]
  })
}

data "aws_iam_policy_document" "terraform_state_access" {
  statement {
    sid     = "ListStatePrefix"
    effect  = "Allow"
    actions = ["s3:ListBucket"]
    resources = [aws_s3_bucket.my_terraform_state_bucket.arn]

    condition {
      test     = "StringEquals"
      variable = "s3:prefix"
      values   = ["terraform/state"]
    }
  }

  statement {
    sid       = "ReadWriteState"
    effect    = "Allow"
    actions   = ["s3:GetObject", "s3:PutObject"]
    resources = ["${aws_s3_bucket.my_terraform_state_bucket.arn}/terraform/state"]
  }

  statement {
    sid       = "LockFile"
    effect    = "Allow"
    actions   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
    resources = ["${aws_s3_bucket.my_terraform_state_bucket.arn}/terraform/state.tflock"]
  }
}

resource "aws_iam_policy" "terraform_state_access" {
  name   = "TerraformStateAccess"
  policy = data.aws_iam_policy_document.terraform_state_access.json
}

resource "aws_iam_role_policy_attachment" "terraform_state_access" {
  role       = aws_iam_role.terraform.name
  policy_arn = aws_iam_policy.terraform_state_access.arn
}