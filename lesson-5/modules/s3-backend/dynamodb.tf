resource "aws_dynamodb_table" "terraform-locks" {
  name = var.table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

    tags = {
        Name = "Terraform locks table"
        Environment = "lesson-5"
    }
}