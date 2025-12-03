variable "terraform_principal_arns" {
  description = "Optional list of IAM principal ARNs allowed to assume the Terraform state role"
  type        = list(string)
  default     = null
}