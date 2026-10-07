# ------------------------------------------------------------
# Backend remoto S3 para el estado de Terraform.
# IMPORTANTE: el bucket debe existir ANTES del primer
# `terraform init` (Terraform no puede crear su propio backend).
# Crealo una sola vez, por ejemplo:
<<<<<<< HEAD
#   aws s3api create-bucket --bucket andysmotors-tfstate --region us-east-1
# ------------------------------------------------------------
terraform {
  backend "s3" {
    bucket       = "andysmotors-tfstate"
=======
#   aws s3api create-bucket --bucket chacon-freshbox-tfstate --region us-east-1
# ------------------------------------------------------------
terraform {
  backend "s3" {
    bucket       = "chacon-freshbox-tfstate"
>>>>>>> 7c0071f9c8f6cd60faeeff7d71a3c4f1c7901024
    key          = "dev/terraform.tfstate"
    region       = "us-east-1"
    use_lockfile = true
    encrypt      = true
  }
}
