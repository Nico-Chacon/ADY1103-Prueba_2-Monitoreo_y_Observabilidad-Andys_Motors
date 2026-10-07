output "alb_dns_name" {
<<<<<<< HEAD
  description = "DNS del ALB - pegar en el navegador para ver la app AndysMotors"
=======
  description = "DNS del ALB - pegar en el navegador para ver la app FreshBox"
>>>>>>> 7c0071f9c8f6cd60faeeff7d71a3c4f1c7901024
  value       = module.loadbalancer.alb_dns_name
}

output "vpc_id" {
  value = module.networking.vpc_id
}

output "db_private_ip" {
  description = "IP privada de la EC2 MySQL (capa Data)"
  value       = module.database.db_private_ip
}

output "asg_name" {
  value = module.compute.asg_name
}

output "sns_topic_arn" {
  value = module.monitoring.sns_topic_arn
}

output "ecr_repo_urls" {
<<<<<<< HEAD
  description = "URLs de los 6 repositorios ECR (para docker push)"
=======
  description = "URLs de los 5 repositorios ECR (para docker push)"
>>>>>>> 7c0071f9c8f6cd60faeeff7d71a3c4f1c7901024
  value       = module.ecr.repo_urls
}

output "account_id" {
  value = data.aws_caller_identity.current.account_id
}
<<<<<<< HEAD

output "prometheus_url" {
  description = "EP2 - Interfaz de Prometheus"
  value       = module.observability.prometheus_url
}

output "grafana_url" {
  description = "EP2 - Interfaz de Grafana (usuario: admin)"
  value       = module.observability.grafana_url
}
=======
>>>>>>> 7c0071f9c8f6cd60faeeff7d71a3c4f1c7901024
