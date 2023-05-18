# --- root/outputs.tf ---

output "database_endpoint" {
  value = module.database.db_endpoint
}

output "instance_endpoint" {
  value = module.compute.instances_public_ips
}

output "dns_name" {
  value = module.loadbalancing.lb_dns_name
}