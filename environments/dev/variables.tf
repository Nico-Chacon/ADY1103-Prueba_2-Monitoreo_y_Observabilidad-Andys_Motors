variable "aws_region" {
  description = "Region de AWS"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Nombre del proyecto (prefijo de todos los recursos)"
  type        = string
  default     = "andysmotors"
}

variable "owner_name" {
  description = "Tu nombre/apellido (tag Owner)"
  type        = string
  default     = "AndysMotors"
}

variable "vpc_cidr" {
  description = "CIDR de la VPC (segun caso AndysMotors: /22)"
  type        = string
  default     = "10.0.0.0/22"
}

variable "ami_id" {
  description = "AMI personalizada (dejar vacio para usar Amazon Linux 2023 ARM64 mas reciente)"
  type        = string
  default     = ""
}

variable "key_name" {
  description = "Nombre del Key Pair EC2 en AWS (sin .pem). El archivo local key.pem corresponde al par llamado key"
  type        = string
  default     = "key"
}

variable "instance_type" {
  description = "Tipo de instancia EC2 (App y Data). Segun el caso: t4g.small"
  type        = string
  default     = "t4g.small"
}

# ---- Base de datos (EC2 MySQL) ----
variable "db_root_password" {
  description = "Password root de MySQL (pasar vía TF_VAR_db_root_password / secret, NUNCA commitear)"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "Password del usuario de aplicacion MySQL (pasar vía TF_VAR_db_password / secret)"
  type        = string
  sensitive   = true
}

variable "db_name" {
  description = "Nombre de la base de datos (debe coincidir con app/db/init.sql)"
  type        = string
  default     = "andysmotors"
}

variable "db_username" {
  description = "Usuario de aplicacion de MySQL"
  type        = string
  default     = "alumno"
}

# ---- Observabilidad (EP2) ----
variable "grafana_admin_password" {
  description = "Password del usuario admin de Grafana (pasar via TF_VAR_grafana_admin_password / secret; alfanumerico, min. 8 caracteres)"
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.grafana_admin_password) >= 8 && can(regex("^[A-Za-z0-9]+$", var.grafana_admin_password))
    error_message = "grafana_admin_password debe ser alfanumerica y tener al menos 8 caracteres (revisar el secret GRAFANA_ADMIN_PASSWORD)."
  }
}

variable "observability_allowed_cidr" {
  description = "CIDR autorizado a abrir Prometheus (9090) y Grafana (3000). Recomendado: tu IP publica /32"
  type        = string
  default     = "0.0.0.0/0"
}

# ---- Notificaciones / gobierno ----
variable "email_sns" {
  description = "Correo para notificaciones SNS (Budgets + CloudWatch)"
  type        = string
}

variable "backup_iam_role_arn" {
  description = "ARN del rol IAM para AWS Backup (usa LabRole de AWS Academy)"
  type        = string
  default     = ""
}

# ---- Control financiero ----
variable "monthly_budget_usd" {
  type    = string
  default = "100"
}

variable "ec2_budget_usd" {
  type    = string
  default = "60"
}

variable "enable_budgets" {
  description = "Poner en false si tu cuenta de Academy no permite AWS Budgets"
  type        = bool
  default     = true
}
