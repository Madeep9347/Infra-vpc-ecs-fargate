provider "aws" {
  region = "ap-south-1"
}

terraform {
  backend "s3" {
    bucket         = "terraform-bucket-envxchange"
    key            = "terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "terraform-lock"
  }
}
module "vpc" {
  source   = "./modules/vpc"
  region   = "ap-south-1"  # Specify your region here
  vpc_cidr = "10.0.0.0/16" # Specify your VPC CIDR here
}

module "ecs" {
  source          = "./modules/ecs"
  region          = "ap-south-1"  # Specify your region here
  vpc_id          = module.vpc.vpc_id
  public_subnets  = module.vpc.public_subnets
  private_subnets = module.vpc.private_subnets

  # Specify the container images for each service
  auth_container_image         = "182399702578.dkr.ecr.ap-south-1.amazonaws.com/environxchange-auth:latest"  # Replace with your Auth service container image
  environxchange_container_image = "182399702578.dkr.ecr.ap-south-1.amazonaws.com/environxchange-content:latest"  # Replace with your Environxchange service container image
}

