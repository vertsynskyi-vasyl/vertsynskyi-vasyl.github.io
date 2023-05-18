# --- root/main.tf ---

### NETWORKING ###
module "networking" {
  source           = "./networking"
  vpc_cidr         = local.vpc_cidr
  private_sn_count = 3
  public_sn_count  = 2
  private_cidrs    = [for i in range(1, 255, 2) : cidrsubnet(local.vpc_cidr, 8, i)]
  public_cidrs     = [for i in range(2, 255, 2) : cidrsubnet(local.vpc_cidr, 8, i)]
  max_subnets      = 20
  access_ip        = var.access_ip
  security_groups  = local.security_groups
  db_subnet_group  = "true"
}

### DATABASE ###
module "database" {
  source                 = "./database"
  db_engine_type         = var.db_engine_type
  db_engine_version      = var.db_engine_version
  db_instance_class      = var.db_instance_type
  db_name                = var.db_name
  db_user                = var.db_user
  db_password            = var.db_password
  db_identifier          = "sonarqube-db"
  skip_db_snapshot       = true
  db_subnet_group_name   = module.networking.db_subnet_group_name[0]
  vpc_security_group_ids = [module.networking.db_security_group]
}

### LOAD BALANCING ###
module "loadbalancing" {
  source                  = "./loadbalancing"
  public_sg               = module.networking.public_sg
  public_subnets          = module.networking.public_subnets
  tg_port                 = 8080
  tg_protocol             = "HTTP"
  vpc_id                  = module.networking.vpc_id
  elb_healthy_threshold   = 2
  elb_unhealthy_threshold = 2
  elb_timeout             = 3
  elb_interval            = 30
  listener_port           = 80
  listener_protocol       = "HTTP"
}

### COMPUTE ###
module "compute" {
  source               = "./compute"
  public_sg            = module.networking.public_sg
  public_subnets       = module.networking.public_subnets
  instance_count       = 1 # TODO increase instance type if everything works just fine
  instance_type        = "t3.micro"
  vol_size             = "10"
  public_key_path      = var.public_key_path
  key_name             = "sonarqubekey"
  db_name              = var.db_name
  db_user              = var.db_user
  db_password          = var.db_password
  db_endpoint          = module.database.db_endpoint
  sonarqube_version    = var.sonarqube_version
  server_user_password = var.server_user_password
  user_data_path       = "${path.root}/userdata.tpl"
  lb_target_group_arn  = module.loadbalancing.lb_target_group_arn
}
