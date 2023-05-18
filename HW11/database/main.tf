# --- database/main.tf ---

resource "aws_db_instance" "sonarqube_db" {
  allocated_storage      = 10
  engine                 = var.db_engine_type
  engine_version         = var.db_engine_version
  instance_class         = var.db_instance_class
  db_name                = var.db_name
  username               = var.db_user
  password               = var.db_password
  db_subnet_group_name   = var.db_subnet_group_name
  vpc_security_group_ids = var.vpc_security_group_ids
  identifier             = var.db_identifier
  skip_final_snapshot    = var.skip_db_snapshot
  tags = {
    Name = "sonarqube-db"
  }
}
