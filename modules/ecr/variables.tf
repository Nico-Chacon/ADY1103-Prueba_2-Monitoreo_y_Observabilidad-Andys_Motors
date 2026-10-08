variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
}

variable "services" {
  description = "Lista de microservicios/imagenes a crear en ECR"
  type        = list(string)
  default = [
    "frontend",
    "get-vehicles",
    "create-visit",
    "create-contact",
    "manage-visits",
    "simulator", # EP2: script simulador de transacciones (metricas para Prometheus)
  ]
}

variable "common_tags" {
  description = "Tags comunes obligatorios"
  type        = map(string)
  default     = {}
}
