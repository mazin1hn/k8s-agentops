terraform {
  backend "s3" {
    bucket       = "mazin-eks-s3-bucket-agent"
    key          = "infra/terraform.tfstate"
    region       = "eu-west-2"
    use_lockfile = true
    encrypt      = true
  }
}