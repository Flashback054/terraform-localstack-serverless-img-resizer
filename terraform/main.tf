provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "images_bucket" {
  bucket = var.images_bucket
}

resource "aws_s3_bucket" "images_resized_bucket" {
  bucket = var.images_resized_bucket
}

resource "aws_s3_bucket" "website_bucket" {
  bucket = var.website_bucket
}
