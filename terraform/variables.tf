variable "images_bucket" {
  description = "The name of the S3 bucket to store images"
  type        = string
}

variable "images_resized_bucket" {
  description = "The name of the S3 bucket to store resized images"
  type        = string
}

variable "website_bucket" {
  description = "The name of the S3 bucket to host the website"
  type        = string
}


