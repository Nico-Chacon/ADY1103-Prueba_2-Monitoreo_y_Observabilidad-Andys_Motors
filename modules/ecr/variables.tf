variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
}

variable "services" {
  description = "Lista de microservicios/imagenes a crear en ECR"
  type        = list(string)
  default = [
    "frontend",
<<<<<<< HEAD
    "get-vehicles",
    "create-visit",
    "create-contact",
    "manage-visits",
    "simulator", # EP2: script simulador de transacciones (metricas para Prometheus)
=======
    "get-products",
    "create-product",
    "update-product",
    "delete-product",
>>>>>>> 7c0071f9c8f6cd60faeeff7d71a3c4f1c7901024
  ]
}

variable "common_tags" {
  description = "Tags comunes obligatorios"
  type        = map(string)
  default     = {}
}
