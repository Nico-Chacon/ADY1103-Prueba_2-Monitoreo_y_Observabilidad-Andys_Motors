# ============================================================
# ECR - Repositorios para las 6 imagenes Docker de AndysMotors
# (frontend + get-vehicles + create-visit + create-contact + manage-visits + simulator)
# ============================================================

resource "aws_ecr_repository" "repo" {
  for_each = toset(var.services)

  name                 = "${var.project_name}-${each.key}"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = merge(var.common_tags, { Name = "${var.project_name}-${each.key}" })
}

# Mantener solo las ultimas 5 imagenes por repo (limpieza de costos)
resource "aws_ecr_lifecycle_policy" "repo" {
  for_each   = aws_ecr_repository.repo
  repository = each.value.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Mantener solo las ultimas 5 imagenes"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 5
      }
      action = { type = "expire" }
    }]
  })
}
