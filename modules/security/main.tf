# ============================================================
# Security Groups segmentados por capa: ALB -> App -> Data
# Minimo privilegio: cada capa solo acepta trafico de la capa
<<<<<<< HEAD
# inmediatamente anterior (segun tabla 2.4).
=======
# inmediatamente anterior (segun tabla 2.4 del enunciado EP1).
>>>>>>> 7c0071f9c8f6cd60faeeff7d71a3c4f1c7901024
# ============================================================

resource "aws_security_group" "alb" {
  name        = "${var.project_name}-sg-alb"
  description = "SG del Application Load Balancer (capa publica)"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP publico"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS publico"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, { Name = "${var.project_name}-sg-alb" })
}

resource "aws_security_group" "app" {
  name        = "${var.project_name}-sg-app"
  description = "SG de las EC2 App (capa privada) - solo recibe trafico del ALB"
  vpc_id      = var.vpc_id

  ingress {
    description     = "HTTP desde el ALB (Nginx del contenedor frontend)"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  ingress {
    description = "SSH solo desde dentro de la VPC (troubleshooting). Se recomienda usar SSM Session Manager."
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

<<<<<<< HEAD
  ingress {
    description     = "EP2: /metrics de los microservicios (3001-3004) solo desde la EC2 de observabilidad"
    from_port       = 3001
    to_port         = 3004
    protocol        = "tcp"
    security_groups = [aws_security_group.obs.id]
  }

=======
>>>>>>> 7c0071f9c8f6cd60faeeff7d71a3c4f1c7901024
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, { Name = "${var.project_name}-sg-app" })
}

resource "aws_security_group" "db" {
  name        = "${var.project_name}-sg-db"
  description = "SG de la EC2 MySQL (capa Data) - solo recibe trafico de la capa App"
  vpc_id      = var.vpc_id

  ingress {
    description     = "MySQL solo desde EC2 App"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  ingress {
    description = "SSH solo desde dentro de la VPC (troubleshooting)"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, { Name = "${var.project_name}-sg-db" })
}
<<<<<<< HEAD

# ------------------------------------------------------------
# EP2 - Observabilidad: Prometheus (9090) + Grafana (3000)
# Se publican solo hacia el CIDR indicado en allowed_cidr
# (recomendado: tu IP /32). Prometheus no trae autenticacion.
# ------------------------------------------------------------
resource "aws_security_group" "obs" {
  name        = "${var.project_name}-sg-obs"
  description = "SG de la EC2 de observabilidad (Prometheus + Grafana)"
  vpc_id      = var.vpc_id

  ingress {
    description = "Prometheus UI"
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = [var.observability_allowed_cidr]
  }

  ingress {
    description = "Grafana UI"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = [var.observability_allowed_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, { Name = "${var.project_name}-sg-obs" })
}
=======
>>>>>>> 7c0071f9c8f6cd60faeeff7d71a3c4f1c7901024
