#!/bin/bash
exec > /var/log/user-data-obs.log 2>&1
set -x

# ============================================================
# Bootstrap EC2 Observabilidad - andysmotors (EP2)
# Generado por Terraform (templatefile) - NO editar a mano
# Levanta con Docker Compose: Prometheus + Grafana + simulador.
# Retencion de datos de Prometheus: 15 dias o 5 GB (lo que ocurra primero).
# simulator_hash: ${simulator_hash}
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

mkdir -p /home/ec2-user/observability/prometheus
mkdir -p /home/ec2-user/observability/grafana/provisioning/datasources
cd /home/ec2-user/observability

# Archivos de configuracion (identicos a los del repositorio)
echo "${prometheus_yml_b64}" | base64 -d > prometheus/prometheus.yml
echo "${datasource_yml_b64}" | base64 -d > grafana/provisioning/datasources/prometheus.yml

# Credenciales de Grafana (heredoc entrecomillado: el shell no expande el contenido)
cat > grafana.env << 'ENVEOF'
GF_SECURITY_ADMIN_USER=admin
GF_SECURITY_ADMIN_PASSWORD=${grafana_admin_password}
GF_USERS_ALLOW_SIGN_UP=false
ENVEOF
chmod 600 grafana.env

# Login a ECR (imagen del simulador) con el rol IAM de la instancia
aws ecr get-login-password --region ${aws_region} | \
  docker login --username AWS --password-stdin ${account_id}.dkr.ecr.${aws_region}.amazonaws.com

cat > docker-compose.yml << 'COMPOSEEOF'
services:
  prometheus:
    image: prom/prometheus:latest
    container_name: andysmotors-prometheus
    command:
      - --config.file=/etc/prometheus/prometheus.yml
      - --storage.tsdb.path=/prometheus
      - --storage.tsdb.retention.time=15d
      - --storage.tsdb.retention.size=5GB
      - --web.enable-lifecycle
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus/prometheus.yml:/etc/prometheus/prometheus.yml:ro
      - prometheus-data:/prometheus
    restart: always
    depends_on:
      - simulator

  grafana:
    image: grafana/grafana:latest
    container_name: andysmotors-grafana
    env_file:
      - grafana.env
    ports:
      - "3000:3000"
    volumes:
      - ./grafana/provisioning:/etc/grafana/provisioning:ro
      - grafana-data:/var/lib/grafana
    restart: always
    depends_on:
      - prometheus

  simulator:
    image: ${simulator_image}
    container_name: andysmotors-simulator
    ports:
      - "8000:8000"
    restart: always

volumes:
  prometheus-data:
  grafana-data:
COMPOSEEOF

chown -R ec2-user:ec2-user /home/ec2-user/observability

docker compose pull || exit 1
docker compose up -d || exit 1
docker ps -a

echo "andysmotors OBSERVABILIDAD setup completado (prometheus + grafana + simulator)"
