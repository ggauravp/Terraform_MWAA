
output "mwaa_security_group_id" {
  value = aws_security_group.mwaa_sg.id
}

output "mwaa_environment_arn" {
  value = aws_mwaa_environment.this.arn
}
