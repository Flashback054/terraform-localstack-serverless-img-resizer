locals {
  # TO-DO: The environment variable STAGE is required for Lambdas to connect to LocalStack endpoints.
  # The environment variable can be removed once Lambdas are adapted to support transparent endpoint injection.
  env_variables               = { STAGE = "local" }
  failure_notifications_email = "my-email@example.com"
}

provider "aws" {
  region = "us-east-1"
}

# S3
resource "aws_s3_bucket" "images_bucket" {
  bucket = var.images_bucket
}

resource "aws_s3_bucket" "images_resized_bucket" {
  bucket = var.images_resized_bucket
}

resource "aws_s3_bucket" "website_bucket" {
  bucket = var.website_bucket
}

# SSM
resource "aws_ssm_parameter" "images_bucket_ssm" {
  name  = "/thumbnail-app/buckets/images"
  type  = "String"
  value = aws_s3_bucket.images_bucket.bucket
}

resource "aws_ssm_parameter" "images_resized_bucket_ssm" {
  name  = "/thumbnail-app/buckets/resized"
  type  = "String"
  value = aws_s3_bucket.images_resized_bucket.bucket
}

## Lambdas

# IAM SSM Policy

resource "aws_iam_policy" "lambdas_ssm" {
  name   = "LambdasAccessSsm"
  policy = file("policies/lambda_ssm.json")
}

# Presign Lambda

resource "aws_iam_role" "presign_lambda_role" {
  name               = "PresignLambdaRole"
  assume_role_policy = file("policies/lambda.json")
}

resource "aws_iam_policy" "presign_lambda_s3_buckets" {
  name = "PresignLambdaS3AccessPolicy"
  policy = templatefile("policies/presign_lambda_s3_buckets.json.tpl", {
    images_bucket = aws_s3_bucket.images_bucket.bucket
  })
}

resource "aws_iam_role_policy_attachment" "presign_lambda_s3_buckets" {
  role       = aws_iam_role.presign_lambda_role.name
  policy_arn = aws_iam_policy.presign_lambda_s3_buckets.arn
}

resource "aws_iam_role_policy_attachment" "presign_lambda_ssm" {
  role       = aws_iam_role.presign_lambda_role.name
  policy_arn = aws_iam_policy.lambdas_ssm.arn
}

resource "aws_lambda_function" "presign_lambda" {
  function_name = "presign"
  filename      = "lambdas/presign/lambda.zip"
  handler       = "handler.handler"
  runtime       = "python3.11"
  timeout       = 10
  role          = aws_iam_role.presign_lambda_role.arn
  source_code_hash = filebase64sha256("lambdas/presign/lambda.zip")

  environment {
    variables = local.env_variables
  }
}

resource "aws_lambda_function_url" "presign_lambda_function" {
  function_name      = aws_lambda_function.presign_lambda.function_name
  authorization_type = "NONE"
}

# List images lambda

resource "aws_iam_role" "list_lambda_role" {
  name               = "ListLambdaRole"
  assume_role_policy = file("policies/lambda.json")
}

resource "aws_iam_policy" "list_lambda_s3_buckets" {
  name = "ListLambdaS3AccessPolicy"
  policy = templatefile("policies/list_lambda_s3_buckets.json.tpl", {
    images_bucket         = aws_s3_bucket.images_bucket.bucket,
    images_resized_bucket = aws_s3_bucket.images_resized_bucket.bucket
  })
}

resource "aws_iam_role_policy_attachment" "list_lambda_s3_buckets" {
  role       = aws_iam_role.list_lambda_role.name
  policy_arn = aws_iam_policy.list_lambda_s3_buckets.arn
}

resource "aws_iam_role_policy_attachment" "list_lambda_ssm" {
  role       = aws_iam_role.list_lambda_role.name
  policy_arn = aws_iam_policy.lambdas_ssm.arn
}

resource "aws_lambda_function" "list_lambda" {
  function_name = "list"
  filename      = "lambdas/list/lambda.zip"
  handler       = "handler.handler"
  runtime       = "python3.11"
  timeout       = 10
  role          = aws_iam_role.list_lambda_role.arn
  source_code_hash = filebase64sha256("lambdas/list/lambda.zip")

  environment {
    variables = local.env_variables
  }
}

resource "aws_lambda_function_url" "list_lambda_function" {
  function_name      = aws_lambda_function.list_lambda.function_name
  authorization_type = "NONE"
}

# Resize lambda

resource "aws_iam_role" "resize_lambda_role" {
  name               = "ResizeLambdaRole"
  assume_role_policy = file("policies/lambda.json")
}

resource "aws_iam_policy" "resize_lambda_s3_buckets" {
  name = "ResizeLambdaS3Buckets"
  policy = templatefile("policies/resize_lambda_s3_buckets.json.tpl", {
    images_resized_bucket = aws_s3_bucket.images_resized_bucket.bucket
  })
}

resource "aws_iam_role_policy_attachment" "resize_lambda_s3_buckets" {
  role       = aws_iam_role.resize_lambda_role.name
  policy_arn = aws_iam_policy.resize_lambda_s3_buckets.arn
}

resource "aws_iam_policy" "resize_lambda_sns" {
  name = "ResizeLambdaSNS"
  policy = templatefile("policies/resize_lambda_sns.json.tpl", {
    failure_notifications_topic_arn = aws_sns_topic.failure_notifications.arn,
    resize_lambda_arn = aws_lambda_function.resize_lambda.arn
  })
}

resource "aws_iam_role_policy_attachment" "resize_lambda_sns" {
  role       = aws_iam_role.resize_lambda_role.name
  policy_arn = aws_iam_policy.resize_lambda_sns.arn
}

resource "aws_iam_role_policy_attachment" "resize_lambda_ssm" {
  role       = aws_iam_role.resize_lambda_role.name
  policy_arn = aws_iam_policy.lambdas_ssm.arn
}

resource "aws_lambda_function" "resize_lambda" {
  function_name = "resize"
  filename      = "lambdas/resize/lambda.zip"
  handler       = "handler.handler"
  runtime       = "python3.11"
  role          = aws_iam_role.resize_lambda_role.arn
  source_code_hash = filebase64sha256("lambdas/resize/lambda.zip")

  environment {
    variables = local.env_variables
  }

  dead_letter_config {
    target_arn = aws_sns_topic.failure_notifications.arn
  }
}

# SNS Topic for failure notifications
resource "aws_sns_topic" "failure_notifications" {
  name = "image_resize_failures"
}

resource "aws_sns_topic_subscription" "email_sub" {
  topic_arn = aws_sns_topic.failure_notifications.arn
  protocol  = "email"
  endpoint  = local.failure_notifications_email
}