#!/bin/bash
# ============================================================
# Build & Push — 6 imágenes AndysMotors (frontend + 4 backend + simulator) hacia ECR
# Proyecto: andysmotors
#
# Se ejecuta DESPUÉS de que exista el módulo ECR en AWS
# (terraform apply -target=module.ecr), o directamente dentro
# del pipeline de GitHub Actions (terraform-apply.yml).
#
# Requiere: AWS CLI configurado (credenciales del Learner Lab
# ya exportadas como variables de entorno / secrets de Actions).
# ============================================================
set -e

AWS_REGION="${AWS_REGION:-us-east-1}"
PROJECT_NAME="${PROJECT_NAME:-andysmotors}"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

echo ">> Account ID: $ACCOUNT_ID"
echo ">> Login a ECR..."
aws ecr get-login-password --region "$AWS_REGION" | \
  docker login --username AWS --password-stdin "$ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com"

build_and_push () {
  local service_dir="$1"
  local repo_suffix="$2"
  local repo_name="${PROJECT_NAME}-${repo_suffix}"
  local repo_url="$ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/${repo_name}"

  echo ">> Build & push (arm64): ${repo_name}"
  docker buildx build \
    --platform linux/arm64 \
    -t "${repo_url}:latest" \
    --push \
    "${service_dir}"
}

build_and_push "./frontend"                 "frontend"
build_and_push "./backend/get-vehicles"     "get-vehicles"
build_and_push "./backend/create-visit"     "create-visit"
build_and_push "./backend/create-contact"   "create-contact"
build_and_push "./backend/manage-visits"    "manage-visits"

# EP2: simulador de transacciones (script Python del docente) para Prometheus
build_and_push "../monitoring/simulator"    "simulator"

echo ">> Listo. 6 imágenes subidas a ECR (frontend + 4 microservicios + simulator)."
