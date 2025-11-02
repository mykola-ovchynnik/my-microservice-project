module "s3_backend" {
  source      = "./modules/s3-backend"
  bucket_name = "mykola-ovchynnik-terraform-state"
  table_name  = "use_lockfile"
  environment = "devops-mykola-ovchynnik"
}

module "vpc" {
  source             = "./modules/vpc"
  vpc_cidr_block     = "10.0.0.0/16"
  public_subnets     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnets    = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
  availability_zones = ["eu-central-1a", "eu-central-1b", "eu-central-1c"]
  vpc_name           = "goit-devops-mykola-ovchynnik-vpc"
}

module "ecr" {
  source       = "./modules/ecr"
  ecr_name     = "goit-devops-mykola-ovchynnik-ecr"
  scan_on_push = true
}
