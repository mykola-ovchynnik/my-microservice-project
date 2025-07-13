# terraform {
#   backend "s3" {
#     bucket         = "terraform-state-bucket-lesson-7-001011"
#     key            = "lesson-5/terraform.tfstate"
#     region         = "eu-central-1"
#     dynamodb_table = "terraform_locks"
#     encrypt        = true
#   }
# }