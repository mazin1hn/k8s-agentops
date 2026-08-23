module "vpc" {
  source = "./modules/vpc"

  
  vpc_cidr_block = var.vpc_cidr_block
  private_subnet_a_cidr_block = var.private_subnet_a_cidr_block
  private_subnet_b_cidr_block = var.private_subnet_b_cidr_block
  public_subnet_a_cidr_block  = var.public_subnet_a_cidr_block
  public_subnet_b_cidr_block  = var.public_subnet_b_cidr_block
  az_a = var.az_a
  az_b = var.az_b 

}



module "eks" {
    source = "./modules/eks"
  
subnet_ids = concat(
    module.vpc.private_subnet_ids,
    module.vpc.public_subnet_ids
)

private_subnet_ids = module.vpc.private_subnet_ids
vpc_id = module.vpc.vpc_id




}
  
module "oidc" {
    source = "./modules/oidc"

    cluster_oidc_issuer = module.eks.cluster_oidc_issuer    
}


 