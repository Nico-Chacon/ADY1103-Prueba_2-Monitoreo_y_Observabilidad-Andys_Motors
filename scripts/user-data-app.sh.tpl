#!/bin/bash
exec > /var/log/user-data-app.log 2>&1
set -x

# ============================================================
# Bootstrap EC2 App - Capa App - andysmotors
# Generado por Terraform (templatefile) - NO editar a mano
# Instala Docker + Compose y levanta los 5 contenedores
# (frontend + get/create/update/manage-visits) leyendo las
# imagenes ya publicadas en Amazon ECR.
# Solo el puerto 80 (frontend/Nginx) se expone al host; los
# 4 microservicios backend se comunican por la red interna de
# docker-compose usando su nombre de servicio (igual que en
# nginx.conf: get-vehicles:3001, create-visit:3002, etc).
# ============================================================

dnf update -y
dnf install -y docker

systemctl enable docker
systemctl start docker
usermod -a -G docker ec2-user
usermod -a -G docker ssm-user

# Plugin docker compose v2
mkdir -p /usr/local/lib/docker/cli-plugins
curl -SL "https://github.com/docker/compose/releases/latest/download/docker-compose-linux-$(uname -m)" \
  -o /usr/local/lib/docker/cli-plugins/docker-compose
chmod +x /usr/local/lib/docker/cli-plugins/docker-compose

mkdir -p /home/ec2-user/app
cd /home/ec2-user/app

# Login a ECR usando el rol IAM de la instancia (LabInstanceProfile)
aws ecr get-login-password --region ${aws_region} | \
  docker login --username AWS --password-stdin ${account_id}.dkr.ecr.${aws_region}.amazonaws.com

cat > docker-compose.yml << COMPOSEEOF
services:
  frontend:
    image: ${frontend_image}
    container_name: andysmotors-frontend
    ports:
      - "80:80"
    restart: always
    depends_on:
      - get-vehicles
      - create-visit
      - create-contact
      - manage-visits

  get-vehicles:
    image: ${get_vehicles_image}
    container_name: andysmotors-get-vehicles
    environment:
      DB_HOST: "${db_host}"
      DB_USER: "${db_user}"
      DB_PASS: "${db_password}"
      DB_NAME: "${db_name}"
      DB_PORT: "3306"
      PORT: "3001"
    ports:
      - "3001:3001"   # /metrics y /health (EP2: scrape de Prometheus; SG solo permite al SG de observabilidad)
    restart: always

  create-visit:
    image: ${create_visit_image}
    container_name: andysmotors-create-visit
    environment:
      DB_HOST: "${db_host}"
      DB_USER: "${db_user}"
      DB_PASS: "${db_password}"
      DB_NAME: "${db_name}"
      DB_PORT: "3306"
      PORT: "3002"
    ports:
      - "3002:3002"   # /metrics y /health (EP2: scrape de Prometheus; SG solo permite al SG de observabilidad)
    restart: always

  create-contact:
    image: ${create_contact_image}
    container_name: andysmotors-create-contact
    environment:
      DB_HOST: "${db_host}"
      DB_USER: "${db_user}"
      DB_PASS: "${db_password}"
      DB_NAME: "${db_name}"
      DB_PORT: "3306"
      PORT: "3003"
    ports:
      - "3003:3003"   # /metrics y /health (EP2: scrape de Prometheus; SG solo permite al SG de observabilidad)
    restart: always

  manage-visits:
    image: ${manage_visits_image}
    container_name: andysmotors-manage-visits
    environment:
      DB_HOST: "${db_host}"
      DB_USER: "${db_user}"
      DB_PASS: "${db_password}"
      DB_NAME: "${db_name}"
      DB_PORT: "3306"
      PORT: "3004"
    ports:
      - "3004:3004"   # /metrics y /health (EP2: scrape de Prometheus; SG solo permite al SG de observabilidad)
    restart: always
COMPOSEEOF

chown -R ec2-user:ec2-user /home/ec2-user/app

docker compose pull || exit 1
docker compose up -d || exit 1
docker ps -a

echo "andysmotors APP setup completado (5 contenedores)"
