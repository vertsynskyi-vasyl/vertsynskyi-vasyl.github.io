# --- loadbalancing/outputs.tf ---

output "lb_target_group_arn" {
  value = aws_lb_target_group.sonarqube_tg.arn
}

output "lb_dns_name" {
  value = aws_lb.sonarqube_lb.dns_name
}