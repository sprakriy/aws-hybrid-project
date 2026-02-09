output "rds_hostname" {
  description = "RDS instance hostname"
  value       = aws_db_instance.postgres.address
}

output "rds_port" {
  description = "RDS instance port"
  value       = aws_db_instance.postgres.port
}
output "grafana_access_key" {
  value = aws_iam_access_key.grafana_key.id
}

output "grafana_secret_key" {
  value     = aws_iam_access_key.grafana_key.secret
  sensitive = true # This hides it from the screen until you ask for it
}
