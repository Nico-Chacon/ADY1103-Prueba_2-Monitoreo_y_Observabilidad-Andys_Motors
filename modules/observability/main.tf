# ============================================================
# Observabilidad (EP2) - EC2 en subred publica con Docker Compose:
#   Prometheus (9090) + Grafana (3000) + simulador transaccional.
# prometheus.yml y el datasource de Grafana se leen desde la carpeta
# monitoring/ del repo (los mismos archivos que se entregan).
# ============================================================

data "aws_ami" "al2023_arm" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-arm64"]
  }

  filter {
    name   = "architecture"
    values = ["arm64"]
  }
}

resource "aws_instance" "obs" {
  ami                         = var.ami_id != "" ? var.ami_id : data.aws_ami.al2023_arm.id
  instance_type               = var.instance_type
  subnet_id                   = var.public_subnet_id
  vpc_security_group_ids      = [var.obs_sg_id]
  key_name                    = var.key_name != "" ? var.key_name : null
  associate_public_ip_address = true

  iam_instance_profile = "LabInstanceProfile"

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
    encrypted   = true
  }

  # hop_limit = 2: permite que el contenedor de Prometheus lea las credenciales
  # del rol (necesarias para ec2_sd_configs) a traves del IMDSv2.
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
  }

  user_data = templatefile("${path.module}/../../scripts/user-data-obs.sh.tpl", {
    aws_region             = var.aws_region
    account_id             = var.account_id
    simulator_image        = var.simulator_image
    grafana_admin_password = var.grafana_admin_password
    prometheus_yml_b64     = base64encode(file("${path.module}/../../monitoring/prometheus/prometheus.yml"))
    datasource_yml_b64     = base64encode(file("${path.module}/../../monitoring/grafana/provisioning/datasources/prometheus.yml"))
    # Hash del codigo del simulador: si cambia el script, la instancia se recrea y baja la imagen nueva
    simulator_hash = sha1(join("", [for f in sort(fileset("${path.module}/../../monitoring/simulator", "**")) : filesha1("${path.module}/../../monitoring/simulator/${f}")]))
  })

  # Cambios en prometheus.yml / datasource / password recrean la instancia
  user_data_replace_on_change = true

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-observabilidad"
    Capa = "observabilidad-publica"
  })
}

resource "aws_eip" "obs" {
  instance = aws_instance.obs.id
  domain   = "vpc"

  tags = merge(var.common_tags, { Name = "${var.project_name}-obs-eip" })
}
