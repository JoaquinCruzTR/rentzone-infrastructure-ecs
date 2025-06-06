locals {
  region       = var.region
  project_name = var.project_name
  environment  = var.environment
}
#Create vpc module
module "vpc" {
  source                       = "git@github.com:JoaquinCruzTR/terraform-modules.git//vpc"
  region                       = local.region
  project_name                 = local.project_name
  environment                  = local.environment
  vpc_cidr                     = var.vpc_cidr
  public_subnet_az1_cidr       = var.public_subnet_az1_cidr
  public_subnet_az2_cidr       = var.public_subnet_az2_cidr
  private_app_subnet_az1_cidr  = var.private_app_subnet_az1_cidr
  private_app_subnet_az2_cidr  = var.private_app_subnet_az2_cidr
  private_data_subnet_az1_cidr = var.private_data_subnet_az1_cidr
  private_data_subnet_az2_cidr = var.private_data_subnet_az2_cidr
}

module "nat_gateway" {
  source                     = "git@github.com:JoaquinCruzTR/terraform-modules.git//nat-gateway"
  project_name               = local.project_name
  environment                = local.environment
  public_subnet_az1_id       = module.vpc.public_subnet_az1_id
  internet_gateway           = module.vpc.internet_gateway
  public_subnet_az2_id       = module.vpc.public_subnet_az2_id
  vpc_id                     = module.vpc.vpc_id
  private_app_subnet_az1_id  = module.vpc.private_app_subnet_az1_id
  private_data_subnet_az1_id = module.vpc.private_data_subnet_az1_id
  private_app_subnet_az2_id  = module.vpc.private_app_subnet_az2_id
  private_data_subnet_az2_id = module.vpc.private_data_subnet_az2_id
}

# create security groups
module "security_groups" {
  source       = "git@github.com:JoaquinCruzTR/terraform-modules.git//security-groups"
  project_name = local.project_name
  environment  = local.environment
  vpc_id       = module.vpc.vpc_id
  ssh_ip       = var.ssh_ip
}


#Launch rds instance
module "rds" {
  source                       = "git@github.com:JoaquinCruzTR/terraform-modules.git//rds"
  project_name                 = local.project_name
  environment                  = local.environment
  vpc_id                       = module.vpc.vpc_id
  private_data_subnet_az1_id   = module.vpc.private_data_subnet_az1_id
  private_data_subnet_az2_id   = module.vpc.private_data_subnet_az2_id
  database_snapshot_identifier = var.database_snapshot_identifier
  database_instance_class      = var.database_instance_class
  availability_zone_1          = var.availability_zone_1
  database_instance_identifier = var.database_instance_identifier
  multi_az_deployment          = var.multi_az_deployment
  database_security_group_id   = module.security_groups.database_security_group_id
}

# request ssl certificate 

module "ssl_certificate" {
  source            = "git@github.com:JoaquinCruzTR/terraform-modules.git//acm"
  domain_name       = var.domain_name
  alternative_names = var.alternative_names
}

# create application load balancer
module "application_load_balancer" {
  source                = "git@github.com:JoaquinCruzTR/terraform-modules.git//alb"
  project_name          = local.project_name
  environment           = local.environment
  alb_security_group_id = module.security_groups.alb_security_group_id
  public_subnet_az1_id  = module.vpc.public_subnet_az1_id
  public_subnet_az2_id  = module.vpc.public_subnet_az2_id
  target_type           = var.target_type
  vpc_id                = module.vpc.vpc_id
  certificate_arn       = module.ssl_certificate.certificate_arn
}

module "s3_bucket" {
  source               = "git@github.com:JoaquinCruzTR/terraform-modules.git//s3-bucket"
  project_name         = local.project_name
  env_file_bucket_name = var.env_file_bucket_name
  env_file_name        = var.env_file_name
}

# create ecs task execution role
module "ecs_task_execution_role" {
  source = "git@github.com:JoaquinCruzTR/terraform-modules.git//iam-role"
  project_name = local.project_name
  file_bucket_name = module.s3_bucket.env_file_bucket_name
  environment = local.environment
}