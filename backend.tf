terraform {
  backend "s3" {
    bucket         = "mykola-ovchynnik-terraform-state"
    key            = "goit-devops-mykola-ovchynnik/terraform.tfstate"
    region         = "eu-central-1"
    dynamodb_table = "use_lockfile"
    encrypt        = true
  }
}
