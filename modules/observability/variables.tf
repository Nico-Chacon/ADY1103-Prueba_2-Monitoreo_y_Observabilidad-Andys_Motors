variable "project_name" {
  type = string
}

variable "public_subnet_id" {
  description = "Subred publica donde corre la EC2 de observabilidad"
  type        = string
}

variable "obs_sg_id" {
  description = "Security Group de la EC2 de observabilidad (viene del modulo security)"
  type        = string
}

variable "instance_type" {
  type    = string
  default = "t4g.small"
}

variable "ami_id" {
  type    = string
  default = ""
}

variable "key_name" {
  type    = string
  default = ""
}

variable "aws_region" {
  type = string
}

variable "account_id" {
  type = string
}

variable "simulator_image" {
  description = "URL:tag de la imagen del simulador en ECR"
  type        = string
}

variable "grafana_admin_password" {
  description = "Password del usuario admin de Grafana (alfanumerico, minimo 8 caracteres)"
  type        = string
  sensitive   = true
}

variable "common_tags" {
  type    = map(string)
  default = {}
}
