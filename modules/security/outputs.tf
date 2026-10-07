output "alb_sg_id" {
  description = "ID del Security Group del ALB"
  value       = aws_security_group.alb.id
}

output "app_sg_id" {
  description = "ID del Security Group de las EC2 App"
  value       = aws_security_group.app.id
}

output "db_sg_id" {
  description = "ID del Security Group de la EC2 MySQL"
  value       = aws_security_group.db.id
}
<<<<<<< HEAD

output "obs_sg_id" {
  description = "ID del Security Group de la EC2 de observabilidad"
  value       = aws_security_group.obs.id
}
=======
>>>>>>> 7c0071f9c8f6cd60faeeff7d71a3c4f1c7901024
