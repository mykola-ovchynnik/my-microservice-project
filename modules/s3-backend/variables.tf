variable "bucket_name" {
  description = "The name of the S3 bucket to store Terraform state files."
  type        = string
}

variable "table_name" {
  description = "The name of the DynamoDB table to store Terraform state locks."
  type        = string
}

variable "environment" {
  description = "The environment for tagging resources."
  type        = string
} 
