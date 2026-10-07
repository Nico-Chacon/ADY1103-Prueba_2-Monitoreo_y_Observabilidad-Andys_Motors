variable "project_name" {
  description = "Nombre del proyecto (prefijo de todos los recursos)"
  type        = string
}

variable "vpc_cidr" {
<<<<<<< HEAD
  description = "CIDR de la VPC (segun caso AndysMotors: /22)"
=======
  description = "CIDR de la VPC (segun caso FreshBox: /22)"
>>>>>>> 7c0071f9c8f6cd60faeeff7d71a3c4f1c7901024
  type        = string
}

variable "common_tags" {
  description = "Tags comunes obligatorios"
  type        = map(string)
  default     = {}
}
