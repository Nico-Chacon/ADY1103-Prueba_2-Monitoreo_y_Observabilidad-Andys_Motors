output "public_ip" {
  description = "IP publica (Elastic IP) de la EC2 de observabilidad"
  value       = aws_eip.obs.public_ip
}

output "prometheus_url" {
  value = "http://${aws_eip.obs.public_ip}:9090"
}

output "grafana_url" {
  value = "http://${aws_eip.obs.public_ip}:3000"
}

output "instance_id" {
  value = aws_instance.obs.id
}
