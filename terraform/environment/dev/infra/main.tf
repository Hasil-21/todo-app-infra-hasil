module "network" {
  source = "../../../modules/network"
}

module "ecr" {
    source = "../../../modules/ecr"
}

module "rds" {
  source = "../../../modules/rds"

  vpc_id = module.network.vpc_id
  private_subnet_ids = module.network.private_subnet_ids
  db_ingress_cidr = []
  db_ingress_sg = [module.eks.eks-sg]
}

module "eks" {
  source = "../../../modules/eks"

  vpc_id = module.network.vpc_id
  private_subnet_ids = module.network.private_subnet_ids
  public_subnet_ids = module.network.public_subnet_ids
}

module "iam" {
  source = "../../../modules/iam"

  openid_connect_arn = module.eks.openid_connect_arn
  openid_connect_url = module.eks.openid_connect_url
}