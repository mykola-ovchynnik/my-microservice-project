# terraform {
#   backend "s3" {
#     bucket         = "mykolaovchynnik-terraform-state-lesson-9"
#     key            = "lesson-9/terraform.tfstate"
#     region         = "eu-central-1"
#     dynamodb_table = "terraform-locks"
#     encrypt        = true
#   }
# }
