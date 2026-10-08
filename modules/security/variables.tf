variable "vpc_id" {
  description = "ID de la VPC"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR de la VPC (para restringir SSH interno)"
  type        = string
}

variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
}

variable "observability_allowed_cidr" {
  description = "CIDR autorizado a acceder a Prometheus (9090) y Grafana (3000)"
  type        = string
  default     = "0.0.0.0/0"
}

variable "common_tags" {
  description = "Tags comunes obligatorios"
  type        = map(string)
  default     = {}
}
