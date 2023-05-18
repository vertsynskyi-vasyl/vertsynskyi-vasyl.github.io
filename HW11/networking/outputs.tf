# --- networking/outputs.tf ---

output "vpc_id" {
  value = aws_vpc.sonarqube_vpc.id
}

output "db_subnet_group_name" {
  value = aws_db_subnet_group.sonarqube_rds_subnetgroup.*.name
}

output "db_security_group" {
  value = aws_security_group.sonarqube_sg["rds"].id
}

output "public_sg" {
  value = aws_security_group.sonarqube_sg["public"].id
}

output "public_subnets" {
  value = aws_subnet.sonarqube_public_subnet.*.id
}