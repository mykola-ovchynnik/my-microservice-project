output "s3_bucket_name" {
  description = "Name for S3 bucket to store Terraform state"
  value = aws_s3_bucket.terraform_state.bucket
}

output "dynamodb_table_name" {
  description = "Name for DynamoDB table to store Terraform state locks"
  value = aws_dynamodb_table.terraform-locks.name
}