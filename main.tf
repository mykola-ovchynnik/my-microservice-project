module "s3_backend" {
  source = "./modules/s3-backend"
  bucket_name = "terraform-state-bucket-lesson-7-001011"
  table_name = "terraform_locks"
}

module "vpc" {
  source             = "./modules/vpc"
  vpc_cidr_block     = "10.0.0.0/16"
  public_subnets     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnets    = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
  availability_zones = ["eu-central-1a", "eu-central-1b", "eu-central-1c"]
  vpc_name           = "lesson-7"
}

module "ecr" {
  source      = "./modules/ecr"
  ecr_name    = "lesson-7-ecr"
  scan_on_push = true
}

module "eks" {
  source          = "./modules/eks"
  cluster_name    = "eks-cluster-demo"            # Назва кластера
  subnet_ids      = module.vpc.public_subnet       # ID підмереж
  instance_type   = "t3.medium"                    # Тип інстансів
  desired_size    = 1                              # Бажана кількість нодів
  max_size        = 2                              # Максимальна кількість нодів
  min_size        = 1                              # Мінімальна кількість нодів
}

