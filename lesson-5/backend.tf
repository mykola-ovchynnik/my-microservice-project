terraform {
  backend "s3" {
    bucket         = "terraform-state-bucket-001011"
    key            = "terraform.tfstate"
    region         = "eu-central-1"
    dynamodb_table = "terraform_locks"
    encrypt        = true
  }
}