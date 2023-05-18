# --- compute/outputs.tf ---

output "instances_public_ips" {
  value = aws_instance.sonarqube_node[*].public_ip
}